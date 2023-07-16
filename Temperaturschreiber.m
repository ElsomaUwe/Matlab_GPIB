% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

run('GPIB_preludium.m');

% Keithley 2700 Multimeter
hDmm = myGpib.connect(gpibAddrKeithley2700);
dmm = Keithley2700(hDmm);

dmm.reset();
dmm.setTEMP();
dmm.setValueOnly();
dmm.setTempRefSim(34);

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end


% Vorbereiten der Messdaten
tMax = 600;           % Messdauer in Sekunden
sampleRate = 1;      % Abtastrate in Sekunden
numSamples = tMax / sampleRate;
temperatur = zeros(numSamples, 1);
time = zeros(numSamples, 1);
tlog = zeros(numSamples, 1);
tstart= 0;

% Grafik erstellen
h= figure;
p = plot(tlog,temperatur);
grid on;
xlabel('time');
ylabel('Temperatur');
title('Temperaturverlauf T-962');
% Y-Achse skalieren
ylim([20 280]);
xlim([1 tMax]);
xticks([0:20:tMax]);
yticks([20:10:300]);
p.XDataSource = 'tlog';
p.YDataSource = 'temperatur';

T = dmm.read;
[~,~,tstart] = str2value(T);

% Messung starten
% fprintf(gpibObj, 'EX');
for i = 1:numSamples
    % Messdaten abrufen
    T = dmm.read;
    [temperatur(i),~,tlog_] = str2value(T);
    tlog(i) = tlog_ - tstart;
    time(i) = i * sampleRate;
    
    refreshdata(h);
    % Warten bis zur nächsten Messung
    pause(sampleRate);
    
    % Nächste Messung anfordern
    %fprintf(hRCL, 'EX');
end


% Verbindung trennen
myGpib.close(hDmm);
% fclose(gpibObjRCL);

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