% J309/J310 JFET Kennlinie aufnehmen
% basierend auf 
% Keithley 2700 Multimeter
% Advantest R6144 DC-Source
% Agilent 66309 Netzteil
% NI GPIB USB Adapter
%
% Uwe Rother

%Cleanup workspace
clear;
clc;
close all;
instrreset;

% erzeugt myGpib Objekt
run('GPIB_preludium.m');

% da die Objekte auch in Funktione benutzt werden, müssen sie global sein
global myGpib;
global hDmm;
global dmm;
global hSupplyDrain;
global supplyDrain;
global hSupplyGate;
global supplyGate;

% initialisiere alle Messgeräte
dmmInit;
supplyDrainInit;
supplyGateInit;

%-------------------------------------------------------------------------
% Hier geht es los
%-------------------------------------------------------------------------
% feste Spannung UDS festlegen
UDS = 12;
UGS = -4.0:0.05:-0.0;
Imin = 10E-6;
[~,numSamples] = size(UGS);
[~,numCurves] = size(UDS);
ID = zeros(numCurves,numSamples);


% Messung starten
% Gate mit maximal negativer Soannung einschalten
supplyGate.setVoltage(UGS(1));
supplyGate.on();
supplyDrain.setVoltage(UDS(1));
supplyDrain.setOnOff(1);

for k = 1:numCurves
        supplyDrain.setVoltage(UDS(k));
    for i = 1:numSamples
        % Messdaten abrufen
        supplyGate.setVoltage(UGS(i));
        pause(0.1);
        T = dmm.read;
        [ID(k,i),~,tlog_] = str2value(T);
    end
    
end

supplyDrain.setOnOff(0);
supplyGate.setOnOff(0);

% Verbindung trennen
myGpib.close(hDmm);
myGpib.close(hSupplyGate);
myGpib.close(hSupplyDrain);

figure;
hold on;
grid on;
semilogy(UGS,ID);
xlabel('U_G_S');
ylabel('I_D_S / A');

IDSS = ID(end);
JFET_fitfunc;

IDSSmA = IDSS * 1000;
disp(['IDSS: ' num2str(IDSSmA) 'mA']);
disp(['Up: ' num2str(Upinchoff) 'V']);


N = find(ID >= Imin,1) -1;
Up = UGS(N);
disp(['Upinchoff = ' num2str(Up) 'V']);

function dmmInit
% Keithley 2700 Multimeter
% GPIB Handle erstellen
global dmm;
global hDmm;
global myGpib;
global gpibAddrKeithley2700;

try
    hDmm = myGpib.connect(gpibAddrKeithley2700);
catch exception
    fprintf(' Fehler beim GPIB connection: %s\n', exception.message);
    return;
end
% und mit Gerätetreiber verbinden
dmm = Keithley2700(hDmm);

dmm.reset();
dmm.setIDC();
dmm.send(':SENS:CURR:DC:RANG 0.1');
dmm.send(':SENS:CURR:DIG 5');
dmm.setValueOnly();

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end

end

function supplyDrainInit
% GPIP Verbindung mit HP66309D aufbauen
global gpibAddrHP66309D;
global myGpib;
global supplyDrain;
hSupplyDrain = myGpib.connect(gpibAddrHP66309D);
supplyDrain = HP66309D(hSupplyDrain);
supplyDrain.setVoltage(0.0);
supplyDrain.setOnOff(1);
% rcl.reset();

if strcmp(hSupplyDrain.status,'open')
    disp([supplyDrain.name ' verbunden']);
else
    disp([supplyDrain.name ' nicht verbunden']);
end

disp("GPIB *IDN?");
disp(supplyDrain.getIDN());
end

function supplyGateInit
% Advantest programmable source verbinden
% GPIB Handle erstellen
global gpibAddrR6144;
global hSupplyGate;
global supplyGate;
global myGpib;

try
   hSupplyGate = myGpib.connect(gpibAddrR6144);
catch exception
   fprintf(' Fehler beim GPIB connection R6144: %s\n', exception.message);
   return;
end

% und mit Gerätetreiber verbinden
supplyGate = R6144(hSupplyGate);
supplyGate.setVoltage(0.0);
supplyGate.on();

if strcmp(hSupplyGate.status,'open')
    disp('R6144 verbunden');
else
    disp('R6144 nicht verbunden');
end
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