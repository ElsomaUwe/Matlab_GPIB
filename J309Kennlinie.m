% J309/J310 JFET Kennlinie aufnehmen
% basierend auf 
% Keithley 2700 Multimeter
% Advantest R6144 DC-Source
% Agilent 66309 Netzteil
% NI GPIB USB Adapter
%
% Uwe Rother

clear;
clc;
close all;
instrreset;

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
dmm.setIDC();
dmm.send(':SENS:CURR:DC:RANG 0.1');
dmm.send(':SENS:CURR:DIG 5');
dmm.setValueOnly();

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end

% GPIP Verbindung mit HP4192A aufbauen
hSupply = myGpib.connect(gpibAddrHP66309D);
supply = HP66309D(hSupply);
supply.setVoltage(0.0);
supply.setOnOff(1);
% rcl.reset();

if strcmp(hSupply.status,'open')
    disp([supply.name ' verbunden']);
else
    disp([supply.name ' nicht verbunden']);
end

disp("GPIB *IDN?");
disp(supply.getIDN()); 

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

UDS = 0.0:0.5:10.0;
UGS = -4.0:0.2:0;

[~,numSamples] = size(UDS);
[~,numCurves] = size(UGS);

ID = zeros(numCurves,numSamples);


% Messung starten
R6144.setVoltage(UGS(1));
R6144.on();
supply.setVoltage(UDS(1));
supply.setOnOff(1);

for k = 1:numCurves
    R6144.setVoltage(UGS(k));
    for i = 1:numSamples
        % Messdaten abrufen
        supply.setVoltage(UDS(i));
        pause(0.1);
        T = dmm.read;
        [ID(k,i),~,tlog_] = str2value(T);
    end
    
end

supply.setOnOff(0);
R6144.off();

% Verbindung trennen
myGpib.close(hDmm);
myGpib.close(hDC);
myGpib.close(supply);
% fclose(gpibObjRCL);
J309_eval;

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