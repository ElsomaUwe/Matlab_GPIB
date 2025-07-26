% GPIB Test Suite
% Uwe Rother
clear;
clc;
close all;

instrreset;
run('GPIB_preludium.m');

% GPIP Verbindung mit HP66309D aufbauen
hSupply = myGpib.connect(gpibAddrHP66309D);
supply = HP66309D(hSupply);
% rcl.reset();

if strcmp(hSupply.status,'open')
    disp([supply.name ' verbunden']);
else
    disp([supply.name ' nicht verbunden']);
end

disp("GPIB *IDN?");
disp(supply.getIDN());