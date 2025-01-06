% GPIB Test Suite
% Uwe Rother

clear;
clc;
close all;

instrreset;
run("GPIB_preludium.m");

if(hIL800 ~= 0)
    el  = IL800(hIL800);
else
    el = IL800(IL800ComPort);
end

el.init();
el.setCurrent(0.100);
el.on();