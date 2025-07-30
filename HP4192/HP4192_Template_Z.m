%[text] # HP4192A Vorlage für Z-Messung
%[text] this one uses visadev instead of gpib as gpib seems to become outdated in matlab
%[text] 28\.07.2025
%[text] HP4192A is a little bit sticky to program. Sometimes it takes long to answer
%[text] ## Hinweis zur Kalibrierung
%[text] ### L-Messung
%[text] wichtig ist short-Kalibrierung bei niedriger Frequenz
%[text] die open-Kalibrierung kann bei hoher Frequenz durchgeführt werden. Der Unterschied ist relativ gering:
%[text] 
%[text] 
%[text] ### ToDo
%[text] \- when sweep is set to Auto, then Range is also automatically switched to auto
%[text] \- it seems, responsetime depends on B display calculation.
%[text] ## 1) Aufräumen
clc;
close all;
clearvars -except runcounter measData
delete(visadevfind());
%[text] ## 2) Manage some persistent variables
%[text] for comparison of ongoing measurements
if exist('runcounter') == 1
    runcounter = runcounter + 1;
else
    runcounter = 1;
    measData = {};
end
%[text] ## 3) Path and Names
titleString = 'HP4192A Messung';
A_Header = 'Z';
B_Header = 'Phi';
IniString = 'A1B1'  %Z,deg %[output:9cc28cf4]
%IniString = 'A2B1'  %R,X
%IniString = 'A3B1'  %L,Q
%IniString = 'A3B3'  %L,R
%IniString = 'A4B1'  %C,Q
%IniString = 'A4B1'  %C,R


% Unterordner "Messungen" erstellen, falls nicht vorhanden
messFolderName = '.\data';
if ~isfolder(messFolderName)
    mkdir(messFolderName);   
end

% Unterordner "Graphs" erstellen, falls nicht vorhanden
pngFolderName = '.\png';
if ~isfolder(pngFolderName)
    mkdir(pngFolderName);
end

currentFolder = pwd;
messFolder = fullfile(pwd,messFolderName);
pngFolder = fullfile(pwd,pngFolderName);

clearvars("messFolderName");
clearvars("pngFolderName");

%[text] ## 4) GPIB Definitions
% GPIB-Adresse des Messgeräts (je nach Konfiguration ändern)
gpibAddrHP4192A         = 1;        %Impedanz-Analyzer
gpibAddrHP66309D        = 6;
gpibAddrKeithley2700    = 8;   %Multimeter
gpibAddrIL800           = 16;
gpibAddrR6144           = 17;         %Programmable Voltage/Current source

% find all gpib Devices
function devlist = getDevicelist()
    %myDevices = string.empty;

    deviceList = visadevlist;
    [deviceCount,~] = size(deviceList);

    for k=1:1:deviceCount
        myDevices(k).type = string(deviceList{k,"Type"});
        temp = deviceList{k,"ResourceName"};
        temp = split(temp,'::');
        myDevices(k).adapter = temp(1);
    end
    devlist = myDevices;
end

warning('off','interface:visa:resourceNotIdentified');
devlist = getDevicelist();
disp(devlist); %[output:8509de48]
%[text] ## 5) Init of HP4192A
% use of short name "d" for HP4192a device
deviceID = "GPIB0::" + string(gpibAddrHP4192A) + "::INSTR";
md = visadev(deviceID);
d = HP4192A(md); %[output:9a154782]
d.init(); %[output:46dfac03]
pause(4);
% d.EOIMode = "off";
d.setTimeout(1);
%[text] ## 6) Setup HP4192A for this measurement
%[text] #### Stop generating SRQ
%first switch off any SRQ gen sources
d.send('D0');      %Data Ready off
d.send('T2');      %Trigger ext

%read and dismis status byte
[tf,statusByte] = getStatus(d);
%[text] #### Configure Type of Measurement (Z, L, C...)
d.send(IniString);     
d.send( 'F1');         % Display A/B/C
labelLeftY = A_Header;
labelRightY = B_Header;
%[text] #### Set Start-, Stop-, Step- and Spot Frequencies
% Frequenzparameter setzen (in Hz)
startFreq = 100000;
stopFreq  = 2000000;
stepFreq  = 50000;

f_Hz = transpose(startFreq:stepFreq:stopFreq);
f_kHz = (f_Hz ./ 1000);
[l,~] = size(f_kHz);
A = zeros(l,1);
B = zeros(l,1);
data = struct('f',f_kHz,'A',A,'B',B);
data.f = f_kHz;

strSpotFreq = sprintf('FR%09.4fEN',startFreq/1000);
strStartFreq = sprintf('TF%09.4fEN',startFreq/1000);
strStopFreq = sprintf('PF%09.4fEN',stopFreq/1000);
strStepFreq = sprintf('SF%09.4fEN',stepFreq/1000);

d.send( strSpotFreq);       % Spot Freq
d.send( strStartFreq);       % Startfrequenz: 1 kHz
d.send( strStopFreq);       % Stopfrequenz: 1 MHz
d.send( strStepFreq);        % Schrittweite: 10 kHz
%[text] #### Use Manual Sweep with SRQ on Data Ready
d.send('W0');                % sweep Man
d.send('D1');                % Data Ready on

%clear status, just in case
statusByte = 255;
[tf,statusByte] = d.getStatus();
if tf
    disp(['found non empty status: ',dec2hex(statusByte)]);
else
    %disp('Status empty')
end

%[text] ## 7) Prepare Measurement
% Grafik erstellen
h= figure; %[output:29ae37b1]
title(titleString); %[output:29ae37b1]
grid on; %[output:29ae37b1]
hold on; %[output:29ae37b1]
set(gcf,'Visible','on'); %[output:29ae37b1]
yyaxis left; %[output:29ae37b1]
p1 = plot(data.f,data.A,'XDataSource','data.f','YDataSource','data.A'); %[output:29ae37b1]
xlabel('f/kHz'); %[output:29ae37b1]
ylabel(labelLeftY); %[output:29ae37b1]
%ylim([5e-06 10e-06]);
yyaxis right; %[output:29ae37b1]
p2 = plot(data.f,data.B,'XDataSource','data.f','YDataSource','data.B'); %[output:29ae37b1]
ylabel(labelRightY); %[output:29ae37b1]
linkdata on; %[output:29ae37b1]

xlim([f_kHz(1) f_kHz(end)]); %[output:29ae37b1]
% ylim([-1 5]);
%[text] ## 8) Start Manual Sweep
d.send('W2');  %start sweep
d.send('R8');  %Range (only valid without auto sweep)
%[text] #### Loop for each frequency in f\_kHz
for j=1:l
    d.trigger();    %equal to d.send('EX')
    pause(0.200);

    while true  %wait until data ready in status
        [tf,statusByte] = d.getStatus;
        measReady = bitget(statusByte,1,"uint8");
        if measReady
            break;
        end      
    end
    y = d.read.split;
    data.A(j) = str2double(extractAfter(y(1),4));
    data.B(j) = str2double(extractAfter(y(2),4));
    data.C(j)= str2double(extractAfter(y(3),1));
    clearvars("y");

    refreshdata(p1); %[output:29ae37b1]
    refreshdata(p2);
    % next sweep manual step
    d.send('W2');
end

% add this sweep to collection of all sweeps in a cell array
measData{runcounter} = data;

%finally clear any SRQ request flag
d.getStatus();
%[text] ## 9) Add previous measurement for comparison (if exists)
% if there is a previous measurement add it to the current figure
if(runcounter > 1)
    try
        lastplot = measData{runcounter-1};
        yyaxis left; %[output:29ae37b1]
        plot(lastplot.f,lastplot.A); %[output:29ae37b1]
        yyaxis right; %[output:29ae37b1]
        plot(lastplot.f,lastplot.B); %[output:29ae37b1]
    catch
        disp('no previous measurement')
    end
end


%[text] ## 10) Save figure file
% Aktuelles Datum im Format YYYY-MM-DD
datum = datestr(now, 'yyyy-mm-dd');

% save figure to file
figdateiname = sprintf('Figure_%s_%d.png', datum, runcounter);
saveas(gcf,fullfile(pngFolder,figdateiname)); %[output:29ae37b1]
%[text] ## 11) Save data to csv file
% Dateiname generieren
dateiname = sprintf('Messung_%s_%d.csv', datum, runcounter);
csvFile = fullfile(messFolder,dateiname);

% Headerzeile für csv definieren
header = "Frequency (Hz);" + A_Header + "; " + B_Header + ";";

% Datei öffnen
fileID = fopen(csvFile, 'w');  % Datei zum Schreiben öffnen

% Header schreiben
fprintf(fileID, '%s\n', header);

% Daten Zeile für Zeile schreiben
for i = 1:l
    fprintf(fileID, '%.4e;%.4e;%.4e\n', data.f(i), data.A(i), data.B(i));
end

% Datei schließen
fclose('all');
%[text] ## 12) save data to xlsx file
% Dateiname generieren
dateiname = sprintf('Messung_%s_%d.xlsx', datum, runcounter);
xlsFile = fullfile(messFolder,dateiname);

% Headerzeile für csv definieren
header = {'f in kHz', A_Header, B_Header};
dataMatrix = [ data.f(:), data.A(:), data.B(:)]; % Spaltenweise Anordnung
dataTable = [header; num2cell(dataMatrix)]; % Kombiniere Header mit Daten

% Schreiben in eine Excel-Datei
writecell(dataTable, xlsFile);
%[text] ## 13) cleanup
clearvars -except runcounter measData
disp('thank you for running this skript'); %[output:5b40fe39]
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.6}
%---
%[output:9cc28cf4]
%   data: {"dataType":"textualVariable","outputData":{"name":"IniString","value":"'A1B1'"}}
%---
%[output:8509de48]
%   data: {"dataType":"text","outputData":{"text":"  1×4 <a href=\"matlab:helpPopup('struct')\" style=\"font-weight:bold\">struct<\/a> array with fields:\n\n    type\n    adapter\n\n","truncated":false}}
%---
%[output:9a154782]
%   data: {"dataType":"text","outputData":{"text":"HP4192A Konstruktor\n","truncated":false}}
%---
%[output:46dfac03]
%   data: {"dataType":"text","outputData":{"text":"HP4192A init\n","truncated":false}}
%---
%[output:29ae37b1]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAjAAAAFRCAIAAADl0wBaAAAAB3RJTUUH6QccEwIH50I+1QAAIABJREFUeJzt3XtcU3eeN\/AvmECOBjHcJFyUFrQ6kKfuzITSVVt0dKz7zFN01D5l22plnVlvr52x007HltZLaR23rd3O44Wd7eBltqVbtEpnttQZR3GqO5S8+hp2gKmrRBGBUBACAuZAIjx\/\/PR4TEK4JeecJJ\/3X8nJycmXBPLh9zvfc05Ib28vAQAAyC1U7gIAAACIEEgAAKAQCCQAAFAEBBIAACgCAgkAABQBgQQAAIqAQAIAAEVAIIHSHTt2LCMj49ixY8ISm832wgsvZGRkVFZWWq3W3NzcjHu98MILNpvNaTt79uxx2g4Rsafn5uZarVanjbtux2w2L168mD20Z88et3WKN+VEXKpQhvjlXLcJEFQQSBCAysrKXn31VXGWVFZWFhUVua558ODB6upq4a7NZnv11VfLyspct2M2m9evX2+xWNhDRUVF4vywWq1Hjx4lourq6kuXLg1bYUVFBdssz\/ONjY1j+BkBAg8CCQKBwWD4\/PPPa2pqampqSktL9Xp9VVVVc3Mze9Rms5WUlDg9hQ1NnFKqurq6rKyMbc1kMi1durSsrIwlVlVVlcViycvLq6mpYc8ymUzCYOjSpUvV1dVPPPGEXq8vKSlxHZ8J9Hq9wWBobGzkeV54ovfeCQA\/hkCCQJOQkDBnzhyLxdLe3s6WfPrpp2VlZX\/7t38rrCOMhAwGg16vd9qC0WjU6XQcx61atYqIrl27ZrPZKioqiGjevHlENGPGDIPBIH7KuXPn9Hr9U089tXTpUnEWuoqJiUlKShIGUufOnSOivLw88Tps9o+prKwUlrNZR9fpRLfL2QSjcFc8OSk8dPbsWfasxYsXm81mtjVhajE3N\/fKlStOU5oAvoNAAv+wbds24TvXaDQKs2qumpubq6qq9Hp9dHQ0EZnN5sLCwry8vCVLljitWVRUVFBQ4LoFYejD0uLq1ascx7355ps1NTWZmZl0Z1jDcouIrFaryWSaM2dOQkLCvHnzLBZLaWmph59l0aJFdCfnLBaLwWBIT08XHj127Ni2bduEu3l5eSyT9uzZIx7PlZWVHThwwMPyYZWVlW3atIndtlgshYWFNpvNarVu3LiRDdqqq6tfeuml69evj2RrAOOnkrsAAC+orq6eP3++eMnSpUsTEhJsNlthYWFMTMzatWtPnz4tPMoChoiEYQFjMBjYNJ3T1sTMZvPLL7+s1+tzcnLYktOnT1dXV69cuZLjOLYFFmksrlzpdDq9Xl9RUTFz5syqqqo5c+ZoNBr2ENsXpdfrCwsLU1NT2Y6rkpISYUBWVFTEQtHJUMs9Y8+qrKzMy8tjs4gsaw0Gw\/79+3U6HUvHmJiY0W4ZYAwwQgL\/sGPHjpo72N4dDyvn5eW9+eabHMexybotW7YMlQ1OOI7buXOnsHGnmTQStTa8\/vrrqampRCTM5rExHBu9eW5tSEpKmjNnTmNjY3Nzs8ViycrK4jiOPdTR0XH9+nWLxZKTk5ORkZGTk2OxWFhUsNnCvLw8p6m8oZYPy2AwzJgxg+6dgbx27RoRrVy5kr1jCxcudJqcBPAdBBIEAnFTQ01NzXPPPUeiqGBf1mwebNu2bW6bwgXC7FxNTQ37rp8+fTp7SEgj8XCEzRC6bsdDawPHcXq9vrq6+ic\/+QkRJScnj+RnzMzMFPop2A\/FfpChlrO7QvcEizrxBpOSkoSRGYASIJAA7mL789kefqE3jwWG1WrNz8+3WCw7duwQT46x7jvXAZzn1gYWdSQapjBRUVExMTF6vb60tFTYYHFxsTDCY\/Hz+eefGwwG8UsMtfz69esdHR1CncO+A+yHPXr0KNuLxmYjR\/4GAowH9iFBwGJjHbaviO40C+zYsWPFihVDPUWn0xmNxqKiImH\/0NKlS9mclXDE0rZt29hgy2AwFBQUsF0+c+bMEb9uVlZWWVlZaWkpG6u5io6O1uv1FovFaZii0+lWrly5bds2oQAiysvL27Bhg\/gAKaE2nU73wgsvuC5PSEjgeT4mJqa6ulq8qWGx6Tthn5zbLkQAH8EICeAeGzZsEO9DYvuiWB+d68r19fXV1dWsv068fM6cOXq9XnygkhPWm05E4h1IzIoVK3bs2CHczcvLe+6551i4ivdpGQyGl156KSoqyu1yjuN0Ol1BQYEQJ2+\/\/fZI9gbpdLr9+\/ezNQ0GwxtvvIGOBpBMCC5hDgAC1nEntPmxu0LTndzVQYBT6JRda0\/\/qve+Ml\/niWjhzMgDT6ZNCrun1N5+x4YP605f7GJ3nzHG7sq5X4ZCAQKLMGUnnugTjriCwDNgbW5\/beGt9mtEFLn5fc64jC3vObGr53gBEWmX52uXbZWmGCWOkFjYPJIauW6unt1OjAxzypvWnv4ffnDp9cfvS4+fKFedAAHJ6ax9bM5Q3pLARwZt3R1vLQ83fEe7bKvNdOLGrzZEPf+JOs1orzN17H06avO\/ExG7oU4zSlCPEkdIk8JUR1bPEm4\/khr5R3NXb79DPEhq63EQUaxWifUD+LXU1NTf\/\/73clcBUhjkuwesjRMSZxNReFpm6MRIh7VJTca+mlOq6GRV4qwQLiJsRlZfzSlpAslfmxpab\/RbbzrkrgIAwI+FaCJCdUm3mr4ior66SiIKT8skInvThdCoxBAugq1mb7ogTT1KH2G09vT\/2tT6jDHOaR+Suc1mvs5\/8+d\/JqLUGE3Jutlx2jCn516z9jV29rHb8ZPD4ic7rwAAENhCOxpCrNfY7Qkx0ybETBc\/GsJFRL9yyrpvTcuaSeq0h2NeNwkhpE6cJdxAIBER9fY7nv\/48vSo8FxjrNND5us2odlha+nl5z++7NT4cM3a9\/yJ+vPmTnb3B\/MSfzg\/aVSv7nA4em\/enDRxokol87uESpRZBipRbBmo5K6z74f85xvspiY9OyJvvziTWEcD98ga3eFee52pdeu3Jdtd5JZyA4m1MxCRa4sdEYl7HJ5+KH7DBxfrO\/rT4++u1tjZd97cuS93drJOQ0QJU8L1kaMbIfG2wZaem3HayRpN+Nh\/DG9AJcosA5UotgxUctdj68i4mIj42rPWku0TrzeIA4lN0018dA0RqdOMYTOyek7u1aUdJtE0nWTDI1JsIA3VXDeUKK3abYNDsk4zL23K2GoIuTVBowrh1KEa9YSxbcFbUIkyy0Alii0DldwVfx\/F33f7tvNVKofkNE0nTN\/5mkKbGgrKGogof+k0t4\/29jtWH7nw3nkLu737dw2zp3Ku+5AAAMAD1sJw8+xhIrLXmfqrf6fJXE5E4RmL+i9V2OtM9jpT\/6WK8IxF0tSjxBFSa0\/\/f13pNl\/nH9j5JVvC2hYmhYVu+LBubVb8gplTDjyZtuHDuu1lDUS0cGbkUNEFAABDCdUlTNn46463HmfHwAoHxqrTjJOyn21\/LZuItMvzJdurpMRAitOGnf3xg24fEh+fJNwGAICxUacZpxa6OQ28dtlWyU7QIFDolB0AAAQbBBIAACgCAgkAABQBgQQAAIqgxKaGAOZoqycie2s9u+FovXp7SVu95ycO2mzWhDSVSq2KTWFLVHHTiYjdVcelCMsBAPwUAslXHG31ttpyIuJrz9rb6h13QkiMpYgqLkXtMU4cDjtx\/KC1yU7Etum6KWGDbGtsy5r0R5FVAOAvEEje4WirZ+MeFj98bTlbLiSEOjZFk\/4o3QkhLj175BvneZ63WKL0eo1G4\/Si7AZ7aUfr1duVtNV3lx8iuntgtvCiqtgUVdx0VWzKqAoAAJAAAmlcHG31rfvWCqMf4Xs\/YtNBCb70707fDTEGEmKSZZXtr+W3g+rOs1RxKdw3solIk\/4oIgoA5IVAGjvrRzusJds16dlcerYm\/VEFDjtUsffM1+loG90ZV9lqy9keLNtfy\/nacjaWEg+kMN0HABJDII2FMDCK3XQwIvtZucsZHZYxTmWzsRRfe5aEgZRouo8NpFRx00mXRJNTJS4YAIIEAmnU2MBIt2q7bvs2uWvxGjaWYiM8YSAljihryXZh5dY7EYWJPgDwIgTSKDja6rvPHO4uP6RbtV33ROCkkVtuI8pm469\/8VvO3mm\/eN5asl080ceGXIgoABgzBNJI2WrL2\/atVcWlJOw4E5x7VlSxKWqep2+viLjT7+c0ihLvixJ2RCGfAGCEEEjDEwZGEdnPBvzAaFTcj6Jqyx2tV8U7opBPADASCKRh2FvrW3++lIiCdmA0KqrYFDZ35zmfsAsKAFwhkDyyNlrfW42B0Zi55hOb4rvdJYHxEwCIIJCG1tE4uOuR2O1n8C3pLcIUn+fxE\/ojAIITAmlIHb\/8AX17RUhqltyFBCzX8VP3mcMk6o\/A5B5AUEEguWerLeeb60Ke+KHchQQRVWwKmxoV55OjrV48uccCTPXAXByfCxB4EEhuONrqrSU7VA\/MvYXhkXyEfIrddFC88+n2iWt1Sa1xKRH\/axEGTwABA4Hkhq223NFaH\/ezMovFInctQOSy86m74ULbZ4WcVus6eEL7CYD\/QiA5c7TVWz\/age81JVPHpYQs\/lGEXh\/79wXizgi+ttxash1tewB+CoHkjF0BLyL7WZ7n5a4FhifujBDP7LG2PbRFAPgRBNI9HG31bfvW6refkbsQGAvXtvLuM4eFY54QTgBObKYTXXufEi8Jz1yp23SYiHpO7Oo5XkBE2uX52mVbpakHgXQP60c72PWN5C4EvIC1RSCcAIbCGZdxh3vZbXudqWPv09olm9nt3vJD0a+UE1HH3qfDMxap04wS1BPIgfSvrVuIyke+vqOtvrv8EIZHAck1nIjIqScC4QRBa9DWfaN466TsZ1nw9NWcUkUnqxJnhXARYTOy+mpOIZC84P5\/X04jDpjWfWsjsp\/FV1LAu3vA0xPbEE4ARMTX\/GHA2jjx0TXsrr3pQmhUYggXIdyVpoxADqR\/jHunrOMl2r4gYQSZxFq9davQXBdcEE4Q2FinD7sx1DqDtu6bn+3lHlkTqksQFqoTZwk3EEjeYf+nMvXJLc3DZRI7EpbD3qPghnCCwNN95rD4cs9uOZouONqvTc5YJElFngR4IBFR7KaDbfvWNmy8b9r+K0Otw4ZHIxlIQZDwEE7ihgic6hAULmLBGk36o0TE154dKpkc1ia2x0i8UBgVSTY8omAIJBouk3AkLHjmGk7ibr3BiKndDy5SLV6Hy2WBArFjIW7fKXG\/Dl95XLzHiFym6dT3ZpXvBEUgEVHspoPd5YfcZhL755cdXAngmVO3nvX373X\/96nu4693H39dOEME\/rkBPzJo6x7oaJr42GbxwvCMRb3lh+x1JiLqv1TBesElECyBRHcip2HjfbGbDgq7AdjJpNHqDWOgik2J+H5+z8P\/oNfrVd0tbOTUXX6Inb4I59YDKTV08MUmS0OHh\/PLTO2OevEXLksH+e4Ba6PTQnWacVL2s+2vZRORdnm+ND3fFFSBRHcyqW3fWiGTcCQseIXbg3CFc+uhGwJ851xdZ7HJUmxqmRal8bCavbWewh90XR6qS4jd42YvkXbZVslO0CAIrkAioojsZ1WxKSyT1HEpOBIWvE4IJ+HcemzYRGjVA+9p6ODPmzs\/qLScN3fmGuM\/2fg389KmeFjfVttn2b6A6DPJKhyDoAskIuLSs1mbAxHhSFjwnbvn1ntim3BWcvSRwzix2bndJ+unRWlyjfH7cmd7Hhv5kWAMJLqTSdYSNNeBRMR7lYbqI49YsAatejAU8ZBoWpTmxSUpLy65T+6ivCxIA4mIcBgsyGWoPnJ0Q4BbbEhUbGohormpU15cMszsnP8K3kACUAJ0Q4AHDR387pNXWMNCrjE+16gPmNk5txBIAErh2g0h7HDSpGdjTi94OM3O7cudnWuMl7soKSCQABTHqRui+8xhdsAc5vQCXvDMzrmFQAJQNGGHU+ymg5jTC2BOs3OB17AwEggkAL\/h4QgnTXr2YMKD9sfWa6ZJdNox8Arx7Nzc1CnBMzvnFgIJwP+4zunxlkv0+3fbfv+uFXN6fkJ8OFEQzs655a+B1NrTv+q9r8zXeSJaODPywJNpk8L89WcBGA82bOJ5nn\/8tZgJfY6K\/8CcnsIVm1oC+3CiMfPLL\/HefsfzH19+xhi3bq6+t9+x4cO6grKGXTn3y10XgMzUcSkRQ8\/poU9PXkHesDASfhlIk8JUR1bPEm4\/khr5R3NXb78DgyQABn16itJ8w3HkL1fePRsshxONWYB\/g583W9mNhCnh+siwUT2Xtw\/wjkFb\/63BCbd8UBoq8fsy\/KaSKcma5flEpP3he47Wq93lh6xVf6BLn4vn9GjmfJ+XIS2FVHKiqo3Nzukjw99aMTM383bDgs0udVWOgUGJX3EM\/D6QWnv6f21qfcYY53Z4tPtkPVE9Ef1gXuIP5yeNast9fX2tPY5Brj+8L8QblY4dKlFmGX5ZSVg8ffdn9N2fUftVuvS5vf3OyV6jp9OM+YPR0+h\/vyxFGb4nbyWWrr4vG2788vMmInowceLO78YszEgKDw9v7uyTvpjbbvTL\/JGMgH8HEtuZND0qPNcY63aFfbmzk3UaGtsIyTYYYlPFR4ZrNOFeqHUcUIkyy\/DvSqbMpNSZRERP7aT2Bv6PR2x\/Lecr\/p3+8w2Knq6Zv5pLz9akP+rzMnxGrkoaOvhiU8svTjdMi9KsztKv+la8Lmyg5euvZX9P+Elqq4wvPzJ+HEisnYGIPLTYJes0Y95tGHJrgkYVwqlDNeoJY6\/SG1CJMssInEri7+NcWyFOvCachnzke5sC5A0ZE\/GRreLeOZ7nFfGeqEPlfPWR8ddAYmmUGBmG5joAb3FthXA6DTk6yF0F7XnnfMFfA6mgrIGI8pdOk7sQgMDkehpydJA7QRu31\/llILX29P\/XlW7zdf6BnV+yJakxmpJ1s+O0o9tLBAAjcTuchuggD8Jhk9M1W9HG7S1+GUhx2rCzP35Q7ioAgo7bM72yYRMLJ1XW\/yWSuZ3Bp8RRhJMseJ1fBhIAyE58plfRFdm3ky6pO3uNTaUOsANvz9V17j55BTuKfAqBBADjIr4ie3fDhbbPCu0Xz3cHysn0hJ6Fa1YeO4p8DYEEAF6jjksJWfyjKL1e1d1iqy13tN4+8JY17wnR5RfEPQsBvKNo0Nbd8dZye92fiEi7PF+7bCtb3nNiV8\/xAqeFvoZAAgDvE58xT9jbxPr0lD9scupZCOwdRZ1Fm4loamHLIN\/d\/trCCYmzOeMye52pt\/xQ9CvlRNSx9+nwjEXqNKMExSCQAMC3xB3kttpy4RzkwoG3yukgH+rg1kA1YG12NP51yj\/sD+EiQriI2D0X2PK+mlOq6GRV4qwQLiJsRlZfzSkEEgAEGi49W4EH3jod3PrJxmDZUdRXV0l93ROiE52W25suhEYlhnARwl1p6kEgAYAMPBx4y8JJmmETi6LdJ69QgB7cyk4HxW64XSFUl9T92f+zffYLund3kTpxlnADgQQAwcLpwFsiEg+bVHHT2e4o7wqSg1u7zxxmMT8Ue92fwg3fiT\/ca68zdbz1ONuHJFV1zhBIAKAU4g5yYU6PLylv27fWi3N6QXVwa8SCNeys7XztWbfJNCE6eeKja4hInWYMM3yXrzzOAkkYFUk2PCIEEgAo0xAH3tJ4rngbVFHEsBPm3r5T4vKoLpHCI8RL2Eyd0zSdMH3nawgkAFA098OmUR54K26fw3kWBKrEWaETI2+ePaxdttVeZ+q\/VKFdspmIwjMW9ZYfsteZiEhYKEU90rwMAMD4iYdN7NJNwx5429DBbyr+6ry5c27qlOBpnxuhEC4i6vnjHW8tZ8fARm5+n7V3q9OMk7KfbX8tm4i0y\/Ol6fkmBBIA+CO3l24SH3iremDub5qmln1Sbel2BGT7nLeEcBHRr5xyXa5dtlWyEzQIEEgA4N+chk0Xz33mKNlORN9UxesnTJ05\/7H0RetVsUgjP4BAAoAA0TwhvrhxsLgthx7M2TibX9Reen\/zf\/Ondjec2q388xUBIZAAIAC4nn2O53mLJSVKr9doNG4v3YRwUiAEEgD4sZF0cnvoIPe7c5AHNgQSAPilMRxU5LaD3F\/OQR4MEEgA4Ge8clCRawe5Ys9BHjwQSADgN3xxUJHbDnIlnIM8CCGQAMAPnKvr3H3yynlzZ64x3ncHFbmegxytEFJCIAGAohWbWj6otFyz8hIf34pWCOkhkABAiYSL5rEo2pc7W67LQ6AVQjIIJABQFvFF85R2paKhWiGISJOejVaIcUIgAYBSsE7uYlMLKS+KnLi2Qjja6iW4rmBgQyABgPycosi\/rlQkzOnFbjroel1Bbt5TFJdO+uVyl+kHEEgAICe\/jiJX7lshiFo\/RivE8BBIACAP1xPQyV2RNwnZwz3+ouWvJu7CSfvF82iF8AyBBABSC7pLieuSIr6fr9FoiMhWWy5uhUA4iSGQAEA6QRdFLrj0bHErBOHwJhEEEgBIAVHkBIc3uUIgAYBvIYqGhcObGAQSAPiKOIrGfFruoDLs4U1EFMBzeggkAPA+RNH4uT+8qbY8gOf0EEgA4E3NNxxH\/nLl3bPjulgROPEwpxdI4YRAAgDvuDMqapwWpfHWxYrAieucHon69MRrOtrqZalwPBBIADBewgRdwmTVL78f\/71v38eOuQGfcu3TG3LNuOlsUCVdcWOCQAKAsRPvK\/pk4998O0ljsVjkLioYDXsAkyo2xW0g2UwnuvY+xW6HcJOjnv9EnWYkop4Tu3qOFxCRdnm+dtlW71fstkhpXgYAAoxTFLEJOp7n5a4LRudW01fhmSt1m+4ZXdnrTL3lh6JfKSeijr1Ph2csYinlawgkABgdt1EEfsredEGdOMtpYV\/NKVV0sipxVggXETYjq6\/mFAIJAJQFUeR3WFceDdHjMGjrHuhoIpdAsjddCI1KDOEihLu+rfIOBBIADA9R5Ke6zxxm3eFuDfLdA9bGnuMFrruLhGGTOnEWAgkAFAFR5NciFqzRpD9KRHztWddkutXeNHCzK3Lz+5xxmb3O1PHW4xMSZ3PGZTIUSkQIJAAYCqIoALDjlm7fKXF+VJ1mnFpoEW6HGb7LVx5ngSSMiiQbHpHyA2lr6eXUGG7dXL3T8t5+x4YP605f7GJ3nzHG7sq5X\/LqAAITTvwTtNhMndM0nWvXg48oOpC2ll7+talt+9Jprg\/19g\/c4G+d3GxIj58ofWEAgQpRFFRsphM9xT+LfuV0qC7BZjrRX\/077ZLNRBSesai3\/JC9zkRE\/Zcq2EIJKDSQWnv6V733lW6i6tvTtG5XaOtxEFGsVqH1A\/gdRFEQYrNzrT+ewe5Gbn6ftXer04yTsp9tfy2biLTL86Xp+SbFBhIRFT6ZNi0qfMOHdW4fbb3Rb73pGHYj581WdiNhSrg+MmxUBfD2Ad4xaOu\/NTjh1qie6HWoRJllBEwllq7+ki9bdp+s10eG\/9PCaS8uSSEim30sP1FgvCEBWYljYNDtcs64jDvc67pcu2yrZCdoECg0kOK0YXHasN7+ISPH3GYzX+e\/+fM\/E1FqjKZk3ew4rZu82X2ynqieiH4wL\/GH85NGVUNfX19rj2OQ6w\/vCxnVE70OlSizjACoxNLV95u\/tP3buSZ9ZLjwN9Lc2SdxGb6ASpzd6Jf5jRgBhQbSsMzXbQtnRh54Mm1SmGpr6eXnP77Mbjutti93drJOQ2MbIdkGQ2yq+MhwjSbca3WPCSpRZhl+XUlDB19sain58mv1hJAXl6T800I3e2olKMN3UIlzGZPUVhlffmT8NZDEPXVPPxS\/4YOL9R396fHOP06yTjPmXtWQWxM0qhBOHapRTxh7od6ASpRZhp9W0tDBnzd37j55hYhWZ+m9e0Fxf3xDgqUSdaicrz4y\/hpITqK0ajQ4AHgmjqJcY7x3owhg\/PzyS5wdhPRIauS6ufrefsfu3zXMnsq53YcEAEyxqeWDSss1K48oAsXyp0BiObQ2K37BzCkHnkzb8GHd9rIGIlo4MzLf3bFKAEBE5+o6d5+8wqIo16ifFoVL54FCKTqQJoWpjqye5fau00MA4Kqhg99U\/BWiCPyFogMJAMZGiKK5qVP25c5GFIFfQCABBJSGDn73ySvFppZcYzyiCPwLAgkgQDTfcBz5y5V3z7bkGuNxcm7wRwgkAL935zR0jbhOBPg1BBKAHxPOiJowWfXL78d\/79v3aTSYowN\/hUAC8EtOJ+debphisVjkLgpgXBBIAH7G7XUieJ6Xuy6A8UIgAfgNcRS9uCQFJ1yAAINAAvADLIqKTS1EhCiCQIVAAlA0nBEVggcCCUC5ik0tiCIIHggkACUSn4YOUQRBAoEEoCw4Iyr4hQFrc\/trC7W5Pw9Py2x\/beGt9mtOK0yITo5+5XSoLmHk20QgASgFTkMHfiRUlxC75wK7LdwYJwQSgPyEfm6chg6CGQIJQE7iQ4sQReCn7HWmjrceH7TdEC\/ElB2A33B7wgUAuVj3rSEi3abD7G7PiV09xwuISLs8X7tsq4cnDtq6bxRvDTN8V3jumCGQAKSGEy6A0thMJ\/oqj4ZnrmR37XWm3vJD0a+UE1HH3qfDMxap04xDPXeQ7x6wNk58bPP4y\/BhILX29D\/\/8eW3vn9\/nDbM9dEzFzu3f3q1ZN1st48CBCSccAEUaNDWbTt7OESXJCzpqzmlik5WJc4K4SLCZmT11ZzyEEghmohQ0XPHw7cjpKsdfd\/8+Z+fMcbuyrnfpy8EoHA44QIoVu\/JvWFpmSHcZGGJvelCaFRiCBch3PXw9BAuYuJjm3uKfxaeljmqPUaufD5l99NFyb\/8L8tvar\/8j7zZ6fETff1yAApUbGr5oNKCo1xBeo62entrPbvhdoUBa3Nf9R90m490fXDPjiJ14izhhttAYschiQ8\/av3xDPEKSmxqMCRMrHnpW++dtyzZW71wZuSBJ9MmhWHHFQQLHOUK8uo+c9hast3DCl0fbJ342OYxjGzExyF5i0TZsG6u\/vHym9JIAAAcbklEQVQHo1e999UDO7\/89eoHFsxEbysEOHaU63lz59zUKTjKFeQSsWCNJv1RIuJrz7omk73ONGi7ocn4jusThVGR5\/k675JusBKnDTv74wfPXOx85sj\/pMZoNj0yrqlGAMVyOsoVUQQyUsWmqGJTbt8pcX60r+ZUf\/Xvvl5\/95CD9o6mqOePO03TCdN3rqz71vRVHqUxTdC5qXY8Tx6DBTOnNBY8tLX08nMfX06NwR8qBBQc5Qr+Rbtsq3CMkfg4pPCMRb3lh+x1JiLqv1ShXeK+pdu6b81AR9PUwpYQLqLnxK721xaOM5N8GEhsSOT2oV0592\/5TtLzH1\/23asDSAlHuUIgUacZJ2U\/2\/5aNhFpl+e77fketHUPdDRNfGwza8abtGRzX\/Uf+uoqOeOyMb+ubP0FcdqwI6uHHAYC+IvmG44jf7lyvLqTcGgR+DOn8yyIB09useNhnRbeavqK\/DGQAAJAyZ\/bdp9sUalU6OcGGD8EEsBYsH7uK20935ul3b5stkaDHaIA44VAAhgdcT\/328vvU\/dZ5a4IIEAgkABGyrWfm+d5i0XusgDk07X3qS7RXXvdn9g5wkmZZ2oACADo5wZw4sdnagDwU+jnBpAMAgnAPVwqAkBiCCQAN4pNLbhUBIDEEEgA9xCfnxtRBCAlBBLAbeImOpyfG0B6CCQANNEBKAICCYIaoghAORBIEKQaOvjz5k7WuYAmOgAlQCBBMEITHYACIZAguKCJDkCxEEgQLMQnRUUTHYAC+X0gbS29nBrDrZurl7sQUC7Xk6LKXREAuOHfgbS19PKvTW3bl06TuxBQKDTRAfgRfw2k1p7+Ve99pZuo+vY0rdy1gBLhpKgAfsdfA4mICp9MmxYVvuHDOrkLAWVBPzeAn\/LXQIrThsVpw3r7HZ5XO2++fTXPhCnh+siwUb0Ebx\/gHYO2\/luDE26NsUovQSUjL+NEVdvuk1fstwZXfWvqi0tSiMhm92GpCnlDlFOJQspAJa4cA4MyvvoI+WsgjdDuk\/VE9UT0g3mJP5yfNKrn9vX1tfY4Brn+8L4QX9SGSrxbhqWrb8dvLzd39X3PEMM+6+bOPlkqkYVCKlFIGajEjRv9Mr8RIxDggbQvd3ayTkNjGyHZBkNsqvjIcI0m3DfVoRLvlNHQwRebWn5xuiHXGP+vT39jtB+0FyuRkUIqUUgZqMRNGZPUVhlffmQCPJCSdZoxN1aF3JqgUYVw6lCNeoJ3q0Il3iqjtdsubxOdQt4Q5VSikDJQiRvqULeLbaYTXXufIqIQbnLU85+o04xsec+JXT3HC4hIuzxfu2yrNDUGeCBBoGq+4Tjylyvvnm1BEx3AmNnrTDfefzH6lXJ1mrHnxK7O\/c9Ev3I6VJdgrzP1lh+KfqWciDr2Ph2esUgIKp9CIIGfaejgz\/5P2+6TLSqVCk10AOOhTjNO\/Zf\/YbfDMxb1lh+61d4Uqkvoqzmlik5WJc4K4SLCZmT11ZxCIA1vUpjqyOpZclcB0mFnorvS1vO9Wdrty2ZrNDjnAoB3CCFERPamC6FRiSFcBHvI3nRBmhr8O5AgeIhPivr28vvUfcrfQQsgP0dbvb21nt0Yah17nanjrccHbTciN78vhJA6cZZwA4EEcJvrlcV5nrdY5C4LwB90nzlsLdnueR11mnFqoYXFEhFxxmVSVOYOAgmUC2eiAxiniAVrNOmPEhFfe9ZzMqnTjGGG7\/KVx1kgCaMiyYZHhEACZcKZ6AC8QhWboopNuX2nxNOag7bugY6mcMN3yGWaTpi+8zX3nekAMio2tTy+\/8\/FppYXl6RU5T+MNALwEXud6esfP2CvMxERX\/MHR1NteMYiIgrPWNR\/qcJeZ7LXmfovVbCFEsAICRQEl3MFkJI6zTj5qd3tr2Wzu5Gb32ft3eo046TsZ9ly7fJ8aXq+CYEECiFczjXXGJ9r1OMaegDS4IzLuMO9rsu1y7ZKdoIGAQIJZIbLuQIAg0AC2aCJDgDEEEggAxZFxaYWwjX0AOAOBBJIrdjUwi7nis4FABBDIIF00EQHAB4gkEAKaKIDgGEhkMC30EQHACOEQAJfQRMdAIwKAgm8D010ADAGCCTwMjTRAcDYIJDAa9BEBwDjgUACLxCa6OamTmHX0JO7IgDwPwgkGBc00QGAtyCQYIzQRAcA3oVAglFr6OCPV+NyrgDgZQgkGIXmG45fftH52wuNKpUK\/dwA4F0IJBgp1s\/tcDieeTgJUQQAXodAguEJ\/dzLDVNW\/y+NXq+XuyIACEAIJPDEqZ87biJZLBa5iwKAwIRAAveEJrq5qVP2PjmbNdHxPC93XQAQsBBI4Az93AAgCwQS3IWTogKAjBBIcNu5us7NH35FOCkqAMgEgQQ4KSpA8Oo5savneAG7Hbn5fc64zGm5dnm+dtlWaYpBIAU18ZnocFJUgGBjM52w\/fFw3L9cCtUl2Ewnbvxqg0qXqE4z2utMveWHol8pJ6KOvU+HZyxSpxklqAeBFKTQuQAAnHGZMCQKT8sMnRjpsDapydhXc0oVnaxKnBXCRYTNyOqrOYVAAp9A5wIAeGZvuhAalRjCRQh3pXldBFJwQecCQFBxtNXbW+vZDc9r3jx7mIjC0zLZXXXiLOEGAgm8DJ0LAEGo+8xha8n2YVezmU70HC+I3Px+qC7B90UNCYEU+NC5ABC0Ihas0aQ\/SkR87dmhkslmOtG19ylxix2JpukkGx4RAimwoXMBIMipYlNUsSm375S4WYE110W\/Ui5uW3CaphOm73wNgRSYxFGEa+gBgFv2OtONX22Y\/A8HnJrowjMW9ZYfsteZiKj\/UoV2yWZp6kEgBRo00QHACPXVnBq03eja+1TXnSXsMFh1mnFS9rPtr2WzJdL0fBMCKcCwa+gRmugAYAS0y7YOdRYGDw\/5DgIpQKCJDgD8HQLJ7wnX0Ms1xuca9WiiAwA\/hUDyY+J+7k82\/g2iCAD8mnID6b3zlu1lDUS0fem0dXP1To\/29js2fFh3+uLtXXHPGGN35dwvdYnyQT83AAQehQZSbcvNI198fXKzgYg2fHDx4dTI9PiJ4hV6+wdu8LdObjY4LQ946OcGgECl0ED6k7krJUaTEhU2KUw1N3Xyn8xdTsHT1uMgolitQuv3EaGJDv3cABB4FPqFbr5uS4wMmxSmEu46rdB6o9960yF5XbJpvuHY+Em1pduBJjoACFQKDSQiSo3hhBuugWRus5mv89\/8+Z+JKDVGU7Judpw2zHUj581WdiNhSrg+0s0KHvD2Ad4xaOu\/NTjh1qir9x5LV\/\/bv6\/\/w1dtT2Ym5hrjp0VpbHbZ6lHIe6KQMlCJYstAJa4cA4MyvvoIKTeQPDNfty2cGXngybRJYaqtpZef\/\/gyu+202u6T9UT1RPSDeYk\/nJ80qpfo6+tr7XEMcv3hfSFeqnp0LF19v\/lL27+da3rsG7qdi2Mz7otShYY0d\/bJUgwj+3uiqDJQiWLLQCVu3OiX+Y0YAeUGkjAqch0eEZG4p+7ph+I3fHCxvqM\/Pd75x9mXOztZp6GxjZBsgyE2VXxkuEYTPrrSx62hgy82tfzidANrokuPU7d8\/bUslTiR8T1RYBmoRLFloBI3ZUxSW2V8+ZFRaCA5TdMJ03dDidKq3TY4JOs0Y26JDrk1QaMK4dShGvWEsW1hDNw20fE8L30lbsnynii2DFSi2DJQiRvqUDlffWQUGkgPp0Ye+eLr2pabRHTefOPph+5pbmYHIT2SGrlurr6337H7dw2zp3Ju9yH5EZwUFQCCnEIDKT1+4uqHpi7ZW01E25dOYz3fLIfWZsUvmDnlwJNpGz6sY0fOLpwZmb90mswVjw9OigoAoNBAIqJ1c\/VOJ2iYFKY6snqW622\/hpOiAgAwyg2kgIeTogIAiCGQZICTogIAuEIgSQonRQUAGAoCSSJoogMA8AyBJAU00QEADAuB5FtoogMAGCEEkq8ITXRzU6fsy52NzgUAAM8QSN6HJjoAgDFAIHkTmugAAMYMgeQduLI4AMA4IZDGC\/3cAODv7HWmzl9tjP5paagugS3pObGr53gBEWmX52uXbZWmDATSuKCfGwD8nb3O1PHW46ETI8VLessPRb9STkQde58Oz1ikTjNKUAkCaYzO1XXuPnkF\/dwA4NfYSCg8c6XD\/IWwsK\/mlCo6WZU4K4SLCJuR1VdzCoGkUOJDi3BSVABQMkdbvb21nt1wu0JY6kNTC1v4mj\/0iALJ3nQhNCoxhIsQ7vq8UCJCII0KO7So2NSSa4zHoUUAoHzdZw5bS7Z7WCHMsNDtcnXiLOEGAklZnA4tQj83APiFiAVrNOmPEhFfe9ZzMikBAmkYDR388WocWgQAfkkVm6KKTbl9p2QUTxRGRZINjwiB5EHzDccvv+j8ZSUOLQKA4OI0TSdM3\/kaAslZQwd\/3tz5QaXlvLkzYbIKhxYBQLAJz1jUW37IXmciov5LFdolm6V5XQTSbQ0dvHCI67QozdzUKT96dFbqJF6v18tdGgCApNRpxknZz7a\/lk1E2uX50vR8EwKJRKdaaOjg2Zm52ewcz\/MWi0Xu6gAAfI4zLuOMy8RLtMu2SnaCBkFQB1KxqYVNzU2L0uCgIgAAeQVpIAkHt85NnfLiEvTOAQDIL+gCSZigw5AIAEBRgiiQhINb56ZOwXXzAACUJigCSXyFCBxRBACgTIEfSOfqOjd\/+BXhChEAAMoW4IGEK0QAAPiLAA8kdtYf7C4CAFC+ULkL8C300QEA+IsADyQAAPAXCCQAAFAEBBIAACgCAgkAABQBgQQAAIqAQAIAAEVAIAEAgCIgkAAAQBEQSAAAoAgIJAAAUAQEEgAAKAICCQAAFAGBBAAAihDgl58AAAhIjrZ6dsPeWu\/6KJeeLb5rqy0X1lcyPw6k985btpc1ENH2pdPWzdV7ffstLS1HjhxZs2ZNSkqK1zeOSgKgDFSi2DJGUon4C9r1O93pC727\/NA9z2296rS+7oltTkva9q0Vbg82fNWqVqtUd79vE7afEa\/csPHuFUTdJsf9JYNOS8RPGXZ9y\/YFQ605YG1uf23hrfZrE6KTo185HapL8LBZX\/PXQKptuXnki69PbjYQ0YYPLj6cGpkeP9G7L9HS0nL48OElS5Yo4U8LlSiwjGCoRPhyVMU6b9ZWW+5m\/cbGqo\/\/dW54S8rPDoiXC1\/orl\/ljIcvdLu7L+iRfKE\/QzTwwvbLRDTuL3RxupC7d8O1fqHspsbGxsbGef\/nSQ8vF5H97D3bj5vuYWVGf+87oI5zLkls2v4rttpyp5+C6fpgqyr1odg9F6z71nR9sFW36fCwL+07\/hpIfzJ3pcRoUqLCJoWp5qZO\/pO5y+uBBCDm9H+r01cSe9Tt5Anj9B83ufzTfXs7d76vnb7grB\/tcK3hHt\/6R6cFzff+U+y4t7Zp+6+I715eFTLklonI3Re623+6Q4nenkn0ZSHRPYEk\/ip0\/TYnj1\/oRKR29xQx1y\/0Lyq+OHrs2I9+9KOkpES3TxnVF7rrjz8sITIbKip+8vd\/\/8G3\/jErK2uolV1\/\/GG5\/kZ5oIpNcfu2D1ibHeYvtLk\/JyLtks2dv9o4YG2WcZDkr4Fkvm5LjAybFKYS7rpd7bzZym6E3rweevP6qF6iqamJiL744otxlDku8eEOdsPR1jQ1zFH\/5\/PCEiJq6VO5XdnV1DAHEf13t\/OVcx+M4D28utP66fwFIopsbPpudE9P+eFu\/oLT+rWaWU5LHmg46WH7\/zNtidPKnue4zaIvXPbRTHjvmebPkoZav+GxXeK7CUdyPWzc0Vbf+pM\/OS2Me\/thD09h6wu\/JHFv\/9jDysL692zf3b+rRNTSryKi0Hvfn4H3C4TbX\/e5+bMdiP8e3fvr2na55d5VNCQKg+aKCvFjPd9a76F4VVxKQ9FuzTceFS\/kl\/6cXNKlsbHx3XffXblyxdx7t08uP74Tp3qIiO79BJ2Ynda\/9+0ioq4ZEb9rPzm7XftQ2iwiItft071\/Ed33vl1mp3dv7OT9JokPd7BvALd\/X7famwYGBlW625k9YLtxq71JxkAK6e3tleu1x2Nr6eXUGI7tOnrvvMV83bYr537xCtesfW3Pf0O4y9IoPuzut3YWd0B77p\/FTzn1rXv+Z3Qy2vUXfXnPhIDnlcdfz7Dbd6pn2Kd4q\/5mVbzb9Vd\/wYnvHnno7r8UlglTXdd\/8b9uOC3Z\/beTPWyfiN7940Xx3ScWPDLUmsxHZ\/4ovjtv8RNuV7OophKR9tyb4szumffTByPu\/ggtfWrXJ\/ae3iO+2zPvp57rcXo\/Pa\/vtLLX1x9tPaNdX+H1jHbjvq5n5Ouv1ltXJ3T+Y9zt372PX3xsQszd+UB7nanzVxujf1oaqksYsDa3\/3POlH\/Yr04zeq7cdwI2kIjomrWvsbOP3Q692T7aERIAgL+bGuYQpk8mxEwTpxEpL5D8dcqORNN0Q83XJevCk3Xhd+5NJvK0DxMAIAgJ03S32psGbM7zEBLz1wNjU2M4D3cBAGBYE6ITQ7nJwt1QbvKEaPc9INLw10B6ODXyvPlGbcvN2pab5803Hk6NlLsiAAA\/E6pLUCV9o+fkXiLqOblXlfQNeY9D8td9SOT7A2MBAAKeog6M9eNAAgCAQOKvU3YAABBgEEh07NixjDsqKyuF5Xv27HFdaDabFy9enJGR8cILL9hs7rv7xm\/Pnj179uwR35WyEpvN9sILL7BXPHbsmFxlEJHVas3NzZX3o2HvhviFhF8Y8ZsjlJqbm2u1Wj2vPP4yxO+M+Of1dRmulQjMZnNubq7ZbJaxksrKSrZx8YtK\/NGItyzZRyP88mdkZIi\/OmT5XR2PYA+kysrKo0ePfv755zU1NUVFRS+\/\/DL7i6qsrDSZTJ9\/\/nlRUdE777zDPjabzVZYWLh+\/XqTyUREn376qY9KKioqEt+VuJIDBw4QEXvRo0ePsr806cuw2WxvvPHGypUrZfxobDbbq6++WlZWJiwxm81Hjx4tLS0tLS09evSo8P178OBBo9FYU1NjNBoPHjzoeeVxliF+Z9jPyz4yX5fhWol4eWFh4fXrdw\/1k74Ss9n88ssvFxUV1dTUrFy58o033mBhIOVHQ6KvFMk+GqvVmp+f\/\/rrr9fU1LDXZYkiy+\/qOAV7IGVmZhYXF+t0OiKaMWNGTExMe3s7EZ07d85oNOp0OoPBkJSUdOnSJSJqbm5ubGycM2cOx3GrVq2qqKjw+pjAZrN99tlnBoNBWCJxJVar9eLFi+vXr+c4TqfTFRcXZ2ZmSl8GEfE839jYmJycTDJ9NGaz+fHHHyci8cdRVVWVlJSUkJCQmppqNBqrqqqIyGq1mkymefPmEVFOTs7FixdZTLpdefxlcBz35ptvrlixgt3OysqyWCw2m82nZQz1hjDV1dWNjY0xMTHsriyVVFVVLV26lP26rlix4s033+Q4TuKPhoiuXbuWlJSk0Wgk+2jEf6c6nc5oNF69enWojfv6oxmnYA8kt2w2m8VimT797iHN165dIyL2hRgVFcUWNjY28ryn08GNwaeffpqenm40GuWq5NKlS11dXcKW5SqDiDQaTVJSEnshljozZsyQshKO4w4fPvzSSy+JF169elWv13McJ9wloo6ODiKKjo5mC7u6utgStyt7pQy3fFqGh0qsVmtJScmWLVtkrMRms1VUVIh\/MSSoxO0bkpyczH79WElZWVkcx\/n6DXFL+t\/V8UMg3XX69GkimjFjBrvL\/jfnOE6vv9tTzv73IaLo6OjISC8f\/GS1WisqKhYuXOi0XOJKkpKSfvvb37rOJktcBhsHXL16NSMjo6SkpKioiA1kJaskISEhIcFNC6zwrSf++ouMjGRxGBUVJX51tyt7pQzGarUePXqUfev5tAwPlZw+fTorK0v4jmNkqUSr1bruHZH4o8nMzCwoKHjiiSeMRuOqVavYQNanZYiZzeaysjI2ABpq49JUMjYIpNsqKyu3bdu2ZcsW4VtPegcPHly1apWMBTBlZWUTJ06sqakpLS0tLCx03X0tDbbrdfr06TU1NevXr8\/Ly5NrXlux2M6kpKSkv\/u7v5OrBrPZXFtbK2MBYocOHdq\/fz\/bOyLsQ5LYsWPH8vPzP\/roo5qamnPnzolbDHyN7UwS5i39EQKJiKiysjIvL6+oqEj8QbK5IDZHJCwU5oLa29u7urq8WIPZbO7p6XGdnZe+EoPBwEZpqampS5cuPXfunCxlsGk6oRKj0VhaWipLJU6E2QzxtIYw9dHR0SF+dbcrewXbnU5EO3fuFGZapC+jtLT0scceEwoQSF8JEa1cuZL9P5eTk9PY2Njc3CxxJWyaTlyGyWRi\/0j5ugyr1bpx40aj0fjcc8953rgsH80I+fHJVb2lsrLy5ZdfLi0tTU1NZUuc5oLozhyR01yQMEfkFVVVVR999NFHH30kLLFYLDt37pS4Etf5runTp8vyhrgleyXTp08X\/7myyQ2nqQ9hSsTtyl7B0kiv14u\/faQvg+0hFzeF5uTkFBUVzZgxQ+JKXH8xhBeVuBK3fP3RsDRauXKlMEM41Mal\/yUZlWAfIbFW0ddff11II2bevHlHjx61Wq2sfYjtWEpISIiIiDh9+rTNZispKREm7r1ixYoVNXfk5eXl5eWxNiGJKxG2TERms9lkMs2ZM4fkeEPYSwiVCDPj0lciNmfOHPY\/r\/jN0el0M2fOZAO40tLSmTNnsn+Q3a7sFayZeMOGDeKF0pfB+rvYL21paanBYCgtLc3MzJS+EhL9YohfVOJKWGeduAzWuubTMtjMrdFoFKfRUBuX5aMZuWAPpKqqKovFkpeXJxwby3bjZ2ZmGo3G+fPn5+XlCTuWOI5bv359YWEh64KTZt5c4ko4jtu5c2dFRUVGRkZOTs6WLVtYVEv\/huh0uoKCgsLCQlbJ66+\/ziZU5f1oUlNTV65cmZOTk5OTs3LlSuH\/mLVr15pMpoyMDJPJtHbtWs8rjxMbl5SVlRmNRqfjQKUswzPpK8nMzNyyZcv8+fMzMjIsFouQ1hJXsmLFCvb7ycoQJlR9V0Zzc3NVVVVRUZHwJcYOyFXC7+po4Vx2AACgCME+QgIAAIVAIAEAgCIgkAAAQBEQSAAAoAgIJAAAUAQEEgAAKAICCWAs2EUChQOAjt3henlAdlI+p1MCsqu6yXglNAAFQiABjBo7mr20tJRdTMtms9XW1sp1cDtAwEAgAYya0+WX2Ek8PVwkAgBGAoEEMDrHjh3Ly8urrq6eP38+m3Nrb2\/XarVOZ887duxYRkbGsFcfYBN6GSKLFy\/GhTYgOOFs3wCjs2LFiuTk5HfeeWf\/\/v3sTHrnzp0TLonGHDt2rLCwkJ1CXrhSnFvs\/KTstnAOb7nOJAYgLwQSwLhYrVaLxSJcaJiIjh49euTIkcLCQnGu5OXluT43KytLfNftObwBggcCCWBcOjo6IiIihMsvlZWVlZWVGQwGYQ8T43T5R+HyeoJjx46ZTKb9+\/f76MIZAMqHfUgA41JVVZWeni6kiF6vLy4uTkpKOnjw4Mg3UllZWVhYWFBQIPsF7AFkhEACGDvXhu85c+akpaWtWrWqqKjI6dijoQx1lUiAYINAAhg7nue7u7udZueIKDMzMy8v75133vHc0UBEVqs1Pz9\/6dKl4gk9gOCEQAIYu0uXLun1erfzbOxanG+88YbTiRucnD59urq6Wny5z4yMjBEOrQACDK4YCwAAioAREgAAKAICCQAAFOH\/A3zTEklCW9g2AAAAAElFTkSuQmCC","height":268,"width":446}}
%---
%[output:5b40fe39]
%   data: {"dataType":"text","outputData":{"text":"thank you for running this skript\n","truncated":false}}
%---
