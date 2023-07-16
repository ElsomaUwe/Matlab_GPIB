% GPIB Test Suite
% Uwe Rother

clear;
clc;
close all;

run('GPIB_preludium.m');

% Keithley 2700 Multimeter
hDmm = myGpib.connect(gpibAddrKeithley2700);
dmm = Keithley2700(hDmm);
R = 558.734;

% Reichelt RND Labornetzteil KA3000P
supply = KA3000P();
supply.init(KAPort);
supply.setVoltage(0.0);
supply.on;

dmm.reset();
dmm.setVDC();
dmm.setValueOnly();

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end


% Vorbereiten der Messdaten
tMax = 10;           % Messdauer in Sekunden
sampleRate = 0.25;      % Abtastrate in Sekunden
%numSamples = tMax / sampleRate;
Vsupply = (0:0.1:10.0)';
numSamples = size(Vsupply,1);
Vzener = zeros(numSamples, 1);
VR = zeros(numSamples, 1);
I = zeros(numSamples,1);
Rz = zeros(numSamples,1);
time = zeros(numSamples, 1);

% Grafik erstellen
h= figure;
p = plot(Vzener,I);
grid on;
xlabel('Vzener/V');
ylabel('I/mA');
title('Zenerdiode');
% Y-Achse skalieren
% ylim([-1 5]);
xlim([0 5]);
p.XDataSource = 'Vzener';
p.YDataSource = 'I';

% Messung starten
% fprintf(gpibObj, 'EX');
for i = 1:numSamples
    % Messdaten abrufen
    % Spannung über der Zener-Diode
    dmm.close(1,1);
    V = dmm.read;
    [Vzener(i),~] = str2value(V);
    % Spannung über dem Widerstand
    dmm.close(1,2);
    V2 = dmm.read;
    [VR(i),~] = str2value(V2);
    
    I(i) = VR(i)/R * 1000;
    Rz(i) = Vzener(i) / I(i);
    time(i) = i * sampleRate;
    
    refreshdata(h);
    %drawnow
    supply.setVoltage(Vsupply(i));
    % Warten bis zur nächsten Messung
    pause(sampleRate);
    
    % Nächste Messung anfordern
    %fprintf(hRCL, 'EX');
end

%supply.setVoltage(0.0);
supply.off;

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

function [value, unit] = str2value(str)
    % Float-Zahl mit optionaler Einheit extrahieren
    %match = regexp(str, '(-?\d+\.?\d*(?:e-?\d+)?)\s*(\w*)', 'tokens', 'once');
    match = regexp(str, '([-+]?\d*\.?\d+[eE][-+]?\d+)\s*(\w*)', 'tokens', 'once');

    if ~isempty(match)
        floatNum = str2double(match{1});
        unit = match{2};
    
        fprintf('Extrahierte Float-Zahl: %s\n', floatNum);
        fprintf('Extrahierte Einheit: %s\n', unit);
    else
        disp('Keine Float-Zahl gefunden.');
    end
    value = floatNum;
end