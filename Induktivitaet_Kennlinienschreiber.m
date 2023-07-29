% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

instrreset;

dateiname = 'C_measurement.xlsx';

dateiname = input('Bitte geben Sie einen Dateinamen ein (ohne Dateierweiterung): ', 's');

% Fügen Sie die gewünschte Dateierweiterung hinzu (z. B. '.txt' oder '.mat')
filename = strcat(dateiname, '.xlsx'); % Hier als Beispiel '.txt', ändern Sie es entsprechend.

f_start = 0.10;
f_stop  = 100.0;
f_step  = 0.5;
C_max_nF   = 0;
Vbias   = 0.0;
oscLvl  = 1.0;

% Vorbereiten der Messdaten
sampleRate = 0.5;      % Abtastrate in Sekunden
f = [f_start:f_step:f_stop]';
% miminale Frequenz ist 5Hz
if f(1) == 0
    f(1) = 0.005;
end
numSamples = length(f);

Z = zeros(numSamples, 1);
R = zeros(numSamples, 1);
C = zeros(numSamples, 1);
RC = zeros(numSamples, 1);
L = zeros(numSamples, 1);
RL = zeros(numSamples, 1);
xL = zeros(numSamples, 1);
QC = zeros(numSamples, 1);
QL = zeros(numSamples, 1);
Phi = zeros(numSamples, 1);
rxstring = zeros(numSamples, 1);

time = zeros(numSamples, 1);
tlog = zeros(numSamples, 1);
tstart= 0;

% Grafik erstellen
h= figure

% L oben links
subplot(2, 2, 1); 
p = plot(f,L);
grid on;
title('Induktivität');
xlabel('f/kHz');
ylabel('L');
xlim([f(1) f(end)]);
if C_max_nF ~= 0.0
    ylim([0 C_max_nF]);
end
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'L';

% R oben rechts
subplot(2, 2, 2); 
p = plot(f,RL);
grid on;
title('Widerstand');
xlabel('f/kHz');
ylabel('R/Ohm');
xlim([f(1) f(end)]);
% ylim([0 50]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'RL';

subplot(2, 2, 3); % Phi unten links
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

subplot(2, 2, 4); % Güte unten rechts
p = plot(f,QL);
grid on;
title('Güte');
xlabel('f/kHz');
ylabel('Güte');
xlim([f(1) f(end)]);
% ylim([0 50]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'QL';


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
rcl.setOscLevel(oscLvl);
rcl.setCircuitmodeSeries();

rcl.setModeLR();
rcl.trigger;
[value qualifier] = rcl.readAll;

% Messung starten
for i = 1:numSamples
    % Messdaten abrufen
    rcl.setSpotFreq(f(i));
    
    %C
    rcl.setModeLR();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    L(i) = value(1);   
    RL(i) = value(2);
    % QC(i) = value(2);
    if qualifier{1}(1) ~= 'N'
        L(i) = NaN;
    else
        L(i) = L(i);
    end
    if qualifier{2}(1) ~= 'N'
        RL(i) = NaN;
    else
        RL(i) = RL(i);
    end
    
    rcl.setModeLQ();
    [value qualifier] = rcl.readAll;
    QL(i) = value(2);
    if qualifier{2}(1) ~= 'N'
        QL(i) = NaN;
    else
        QL(i) = QC(i);
    end
        
    refreshdata(h);
    % Warten bis zur nächsten Messung
    pause(0.1);
    
end

rcl.setBiasOff();
% Verbindung trennen
myGpib.close(hRcl);

col_names = {'f','L','RL','QL'};
save_vectors_to_csv(f,L,RL,QL,col_names,filename);

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
