% GPIB Test Suite
% Uwe Rother

clear;
clc;
close all;
instrreset;

% GPIB-Adresse des Messgeräts (je nach Konfiguration ändern)
gpibAddrHP4192A = 1;
%gpibAddrKeithley2700 = 8;
%gpibAddrIL800 = 16;
%KAPort = 'COM3';

% init GPIB Controller
myGpib = gpibClass;
% reset interface
myGpib.init();

% connect with some instruments
hRCL = myGpib.connect(gpibAddrHP4192A);

if strcmp(hRCL.status,'open')
    disp('RCL verbunden');
else
    disp('RCL nicht verbunden');
end

% Messparameter einstellen
fprintf(hRCL, 'A4B1T3F1D1'); % Messbereich auf Kapazität einstellen
fprintf(hRCL, 'FR+0010.5000EN');

% Vorbereiten der Messdaten
tMax = 20;           % Messdauer in Sekunden
sampleRate = 2;      % Abtastrate in Sekunden
numSamples = 20;
C = zeros(numSamples, 1);
time = zeros(numSamples, 1);

% Grafik erstellen
h= figure;
p = plot(time, C);
xlabel('Zeit (s)');
ylabel('Kapazität (F)');
title('Kapazität über der Zeit');
% Y-Achse skalieren
ylim([0 2E-6]);
xlim([0 20]);
p.XDataSource = 'time';
p.YDataSource = 'C';

% Messung starten
% fprintf(gpibObj, 'EX');

for i = 1:numSamples
    % Messdaten abrufen
    fprintf(hRCL, 'EX');
    pause(1/1000);
    [C(i),Q(i)] = rclReadCapQ(hRCL);
    time(i) = i;
    refreshdata(h);
end

% Verbindung trennen
myGpib.close(hRCL);
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
