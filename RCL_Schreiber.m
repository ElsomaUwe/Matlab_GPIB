% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;
instrreset;

run('GPIB_preludium.m');

% GPIP Verbindung mit HP4192A aufbauen
rcl = HP4192A(hHP4192A);
% rcl.reset();

if strcmp(rcl.h.status,'open')
    disp('HP4192A verbunden');
else
    disp('KHP4192A nicht verbunden');
end


% Vorbereiten der Messdaten
sampleRate = 0.5;      % Abtastrate in Sekunden
f = [440.00:0.25:470.0];
numSamples = length(f);

L = zeros(numSamples, 1);
time = zeros(numSamples, 1);
tlog = zeros(numSamples, 1);
tstart= 0;

% Grafik erstellen
h= figure;
p = plot(tlog,L);
grid on;
xlabel('f/kHz');
ylabel('Z/kOhm');
title('Induktivität');
% Y-Achse skalieren
xlim([f(1) f(end)]);
%ylim([5e-06 15e-06]);
%xticks([0:20:tMax]);
%yticks([20:10:300]);
p.XDataSource = 'f';
p.YDataSource = 'L';

rcl.setRCL(1);
rcl.setModeZdeg();
rcl.setSpotFreq(11.0);

rcl.trigger();
[value qualifier] = rcl.readAll();

% Messung starten
% fprintf(gpibObj, 'EX');
for i = 1:numSamples
    % Messdaten abrufen
    rcl.setSpotFreq(f(i));
    rcl.trigger;
    [value qualifier] = rcl.readAll;
    L(i) = value(1)/1000;   
    refreshdata(h);
    % Warten bis zur nächsten Messung
    pause(0.1);
    
    % Nächste Messung anfordern
    %fprintf(hRCL, 'EX');
end


% Verbindung trennen
myGpib.close(hRcl);

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