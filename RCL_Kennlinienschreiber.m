% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

instrreset;

filename = 'output_data.csv';

f_start = 0.20;
f_stop  = 50.0;
f_step  = 0.2;
C_max_nF   = 0;
Vbias   = 5.0;

% Vorbereiten der Messdaten
sampleRate = 0.5;      % Abtastrate in Sekunden
f = [f_start:f_step:f_stop]';
numSamples = length(f);

Z = zeros(numSamples, 1);
R = zeros(numSamples, 1);
C = zeros(numSamples, 1);
L = zeros(numSamples, 1);
xL = zeros(numSamples, 1);
QC = zeros(numSamples, 1);
QL = zeros(numSamples, 1);
Phi = zeros(numSamples, 1);
rxstring = zeros(numSamples, 1);

time = zeros(numSamples, 1);
tlog = zeros(numSamples, 1);
tstart= 0;

% Grafik erstellen
h= figure;

subplot(2, 2, 1); % Oben links 
p = plot(f,Z);
grid on;
title('Impedanz');
xlabel('f/kHz');
ylabel('Z/Ohm');
xlim([f(1) f(end)]);
% ylim([0 50]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'Z';

subplot(2, 2, 2); % Oben rechts
p = plot(f,Phi);
grid on;
title('Phasenwinkel');
xlabel('f/kHz');
ylabel('Phi/°');
xlim([f(1) f(end)]);
ylim([-180 180]);
%xticks([0:20:tMax]);
yticks([-180:30:180]);
p.XDataSource = 'f';
p.YDataSource = 'Phi';

subplot(2, 2, 3); % unten links
p = plot(f,L);
grid on;
title('Induktivität');
xlabel('f/kHz');
ylabel('L/uH');
xlim([f(1) f(end)]);
% ylim([0 50]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'L';

subplot(2, 2, 4); % unten rechts
p = plot(f,C);
grid on;
title('Kapazität');
xlabel('f/kHz');
ylabel('C/nF');
xlim([f(1) f(end)]);
if C_max_nF ~= 0.0
    ylim([0 C_max_nF]);
end
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'C';

run('GPIB_preludium.m');

% GPIP Verbindung mit HP4192A aufbauen
hRcl = myGpib.connect(gpibAddrHP4192A);
rcl = HP4192A(hRcl);
% rcl.reset();

if strcmp(hRcl.status,'open')
    disp('HP4192A verbunden');
else
    disp('KHP4192A nicht verbunden');
end

%make sure calibration is ok!
% rcl.setRCL(1);
if Vbias == 0.0
    rcl.setBiasOff();
else
    rcl.setSpotBias(Vbias);
end
rcl.setModeLQ();
rcl.setSpotFreq(f(1));

rcl.trigger;
[value qualifier] = rcl.readAll;

% Messung starten
for i = 1:numSamples
    % Messdaten abrufen
    rcl.setSpotFreq(f(i));
    %L
    rcl.setModeLQ();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    L(i) = value(1)*1E6;   
    temp = rcl.readAll_B();
    xL(i) = temp{1,1}*1E6;
    
    QL(i) = value(2);
    %C
    rcl.setModeCQ();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    C(i) = value(1)*1E9;   
    QC(i) = value(2);
    if qualifier{1}(1) ~= 'N'
        C(i) = 0;
    else
        C(i) = C(i);
    end

    %Z
    rcl.setModeZdeg();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    Z(i) = value(1);   
    Phi(i) = value(2);
    refreshdata(h);
    % Warten bis zur nächsten Messung
    pause(0.1);
    
end

rcl.setBiasOff();
% Verbindung trennen
myGpib.close(hRcl);

col_names = {'f','Z','Phi','L','QL','C','QC'};
save_vectors_to_csv(f,Z,Phi,L,QL,C,QC,col_names,filename);

% SRQ-Ereignisbehandlungsfunktion
function handleSRQ(src, event)
    % Hier können Sie den SRQ-Ereigniscode bearbeiten
    % Fügen Sie Ihren Code zur Verarbeitung des SRQ-Ereignisses ein
    disp('Service Request empfangen');
end


function [Cl,Q] = rclReadCapQ(hRCL)
    rxMsg = fscanf(hRCL);
    resVektor = (strsplit(rxMsg,','));
    dispA = char(resVektor(1));
    dispB = char(resVektor(2));
    dispC = char(resVektor(3));
    Cl = str2double(dispA(5:end));
    Q = str2double(dispB(5:end));
end

function [value, unit, time] = str2value(str)
    % Float-Zahl mit optionaler Einheit extrahieren
    %match = regexp(str, '(-?\d+\.?\d*(?:e-?\d+)?)\s*(\w*)', 'tokens', 'once');
    resVektor = string(strsplit(str,','));
    
    match = regexp(resVektor(1), '([-+]?\d*\.?\d+[eE][-+]?\d+)\s*(\w*)', 'tokens', 'once');
    ltime = regexp(resVektor(2), '([-+]?\d*\.?\d+)\s*(\w*)', 'tokens', 'once');
    time = str2double(ltime(1));

    if ~isempty(match)
        floatNum = str2double(match{1});
        unit = match{2};
    
        % fprintf('Extrahierte Float-Zahl: %s\n', floatNum);
        % fprintf('Extrahierte Einheit: %s\n', unit);
    else
        disp('Keine Float-Zahl gefunden.');
    end
    value = floatNum;
    
end

function save_vectors_to_csv(varargin)
    % Überprüfen, ob die Anzahl der übergebenen Vektoren zwischen 2 und 10 liegt
    num_vectors = nargin;
    if num_vectors < 2 || num_vectors > 10
        error('Die Funktion erwartet zwischen 2 und 10 Vektoren.');
    end
    
    % Den letzten Parameter als Dateinamen entfernen
    filename = varargin{end};
    varargin = varargin(1:end-1);
    
    % Den vorletzten Parameter als Spaltennamen entfernen
    col_names = varargin{end};
    varargin = varargin(1:end-1);
    
    num_vectors = num_vectors - 2;
    
    % Überprüfen, ob die Vektoren alle die gleiche Länge haben
    vec_lengths = cellfun(@numel, varargin);
    if ~all(vec_lengths == vec_lengths(1))
        error('Alle übergebenen Vektoren müssen die gleiche Länge haben.');
    end
    
    % Überprüfen, ob die Anzahl der Spaltennamen korrekt ist
    num_names = numel(col_names);
    if num_names ~= num_vectors
        error('Die Anzahl der Spaltennamen muss der Anzahl der übergebenen Vektoren entsprechen.');
    end
    
    % Daten in eine Tabelle umwandeln
    data = table(varargin{:});
    
    % Spaltennamen festlegen
    data.Properties.VariableNames = col_names;
    
    % CSV-Datei speichern
    try
        writetable(data, filename);
        disp(['Die Daten wurden erfolgreich in der Datei ', filename, ' gespeichert.']);
    catch
        error('Fehler beim Speichern der Daten in der CSV-Datei.');
    end
end
