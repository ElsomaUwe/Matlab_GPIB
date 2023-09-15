% Chauvin Arnoux Kennlinie aufnehmen
% 
% basierend auf 
% Keithley 2700 Multimeter
% NI GPIB USB Adapter
%
% Uwe Rother

clear;
clc;
close all;
instrreset;

Range = 20;

% erzeugt myGpib Objekt
run('GPIB_preludium.m');

% Keithley 2700 Multimeter
% GPIB Handle erstellen
try
   hDmm = myGpib.connect(gpibAddrKeithley2700);
catch exception
   fprintf(' Fehler beim GPIB connection: %s\n', exception.message);
   return;
end
% und mit Gerätetreiber verbinden
dmm = Keithley2700(hDmm);

dmm.reset();
dmm.setVDC();
dmm.setValueOnly();

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end

% Advantest programmable source verbinden
% GPIB Handle erstellen
try
   hDC = myGpib.connect(gpibAddrR6144);
catch exception
   fprintf(' Fehler beim GPIB connection R6144: %s\n', exception.message);
   return;
end
% und mit Gerätetreiber verbinden
R6144 = R6144(hDC);
R6144.setVoltage(0.0);
R6144.on();

if strcmp(hDmm.status,'open')
    disp('R6144 verbunden');
else
    disp('R6144 nicht verbunden');
end

% Vorbereiten der Messdaten
tMax = 600;           % Messdauer in Sekunden
Usoll = -32.0:1.0:32.0;

sampleRate = 1;      % Abtastrate in Sekunden
[~,numSamples] = size(Usoll);

Uout20 = zeros(numSamples, 1)';
Uout50 = zeros(numSamples, 1)';
Uout200 = zeros(numSamples, 1)';

time = zeros(numSamples, 1)';

% Grafik erstellen
h= figure;
p = plot(Usoll,Uout20);
grid on;
xlabel('time');
ylabel('U_soll');
title('Chauvin Arnoux DP');
% Y-Achse skalieren
switch Range
    case 20
        ylim([-1.8 1.8]);
        p.YDataSource = 'Uout20';
    case 50
        ylim([-0.8 0.8]);
        p.YDataSource = 'Uout50';
    case 200
        ylim([-0.18 0.18]);
        p.YDataSource = 'Uout200';
end
xlim([-32 32]);
xticks([-32:2:32]);
%yticks([20:10:300]);
p.XDataSource = 'Usoll';
% dummy Messung
T = dmm.read;
[~,~,tstart] = str2value(T);

% Messung starten
% fprintf(gpibObj, 'EX');
for i = 1:numSamples
    % Messdaten abrufen
    Utest = Usoll(i);
    R6144.setVoltage(Utest);
    pause(0.5);
    T = dmm.read;
    switch Range
        case 20
            [Uout20(i),~,tlog_] = str2value(T);
        case 50
            [Uout50(i),~,tlog_] = str2value(T);
        case 200
            [Uout200(i),~,tlog_] = str2value(T);
    end
    tlog(i) = tlog_ - tstart;
    time(i) = i * sampleRate; 
    refreshdata(h);
end

switch Range
    case 20
        err = Uout20 - Usoll/20;
        DP25data20 = [Usoll;Uout20;err];
        save('DP25data20.mat','DP25data20');

    case 50
        err = Uout50 - Usoll/50;
        DP25data50 = [Usoll;Uout50;err];
        save('DP25data50.mat','DP25data50');


    case 200
        err = Uout200 - Usoll/200;
        DP25data200 = [Usoll;Uout200;err];
        save('DP25data200.mat','DP25data200');
end
% Verbindung trennen
myGpib.close(hDmm);
myGpib.close(hDC);
% fclose(gpibObjRCL);

% SRQ-Ereignisbehandlungsfunktion
function handleSRQ(src, event)
    % Hier können Sie den SRQ-Ereigniscode bearbeiten
    % Fügen Sie Ihren Code zur Verarbeitung des SRQ-Ereignisses ein
    disp('Service Request empfangen');
end


function [value, unit, time] = str2value(str)
    % Float-Zahl mit optionaler Einheit extrahieren
    resVektor = string(strsplit(str,','));
    
    match = regexp(resVektor(1), '([-+]?\d*\.?\d+[eE][-+]?\d+)\s*(\w*)', 'tokens', 'once');
    ltime = regexp(resVektor(2), '([-+]?\d*\.?\d+)\s*(\w*)', 'tokens', 'once');
    time = str2double(ltime(1));

    if ~isempty(match)
        value = str2double(match{1});
        unit = match{2};
    else
        disp('Keine Float-Zahl gefunden.');
        value = NaN;
        unit = '$';
    end
end