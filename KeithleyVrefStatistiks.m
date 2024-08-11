% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

instrreset;

run('GPIB_preludium.m');

% Keithley 2700 Multimeter
hDmm = myGpib.connect(gpibAddrKeithley2700);
dmm = Keithley2700(hDmm);

dmm.reset();

if strcmp(hDmm.status,'open')
    disp('Keithley 2700 verbunden');
else
    disp('Keithley 2700 nicht verbunden');
end
dmm.send('*RST');
dmm.send('INIT:CONT ON');

dmm.send('SENSE:VOLTAGE:DC:RANGE 10');
dmm.send('SENSE:VOLTAGE:NPLC 5');
dmm.send('TRACE:CLE:AUTO ON');
dmm.send('TRIG:DEL 0.4');

dmm.send('TRACE:POIN 20');
dmm.send('TRACE:FEED SENS');
dmm.send('TRACE:FEED:CONTROL NEXT');
pause(20);
result = dmm.recall();
resVektor = char(strtrim(strsplit(result,',')));