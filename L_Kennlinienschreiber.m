% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

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


% Vorbereiten der Messdaten
sampleRate = 0.5;      % Abtastrate in Sekunden
f = [1000.00:500.0:10000.0]';
numSamples = length(f);

L = zeros(numSamples, 1);
Q = zeros(numSamples, 1);
Z = zeros(numSamples, 1);
R = zeros(numSamples, 1);
C = zeros(numSamples, 1);
Phi = zeros(numSamples, 1);

time = zeros(numSamples, 1);
tlog = zeros(numSamples, 1);
tstart= 0;

% Grafik erstellen
h= figure;
p = plot(tlog,L);
grid on;
xlabel('f/kHz');
ylabel('L/nH');
title('Induktivität');
% Y-Achse skalieren
xlim([f(1) f(end)]);
ylim([0 50]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'L';

%make sure calibration is ok!
% rcl.setRCL(1);

rcl.setModeLQ();
rcl.setSpotFreq(11.0);

rcl.trigger;
[value qualifier] = rcl.readAll;

% Messung starten
% fprintf(gpibObj, 'EX');
for i = 1:numSamples
    % Messdaten abrufen
    rcl.setSpotFreq(f(i));
    rcl.setModeLQ();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    L(i) = value(1)*1E9;   
    Q(i) = value(2);
    rcl.setModeZdeg();
    rcl.trigger();
    [value qualifier] = rcl.readAll;
    Z(i) = value(1);   
    Phi(i) = value(2);
    refreshdata(h);
    % Warten bis zur nächsten Messung
    pause(0.1);
    
    % Nächste Messung anfordern
    %fprintf(hRCL, 'EX');
end


% Verbindung trennen
myGpib.close(hRcl);
figure;
plot(f,Q);

col_names = {'f','Z', 'L', 'Phi', 'Q'};
filename = 'output_data.csv';
save_vectors_to_csv(f,Z,L,Phi,Q,col_names,filename);

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
