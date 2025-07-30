%[text] # HP4192A Vorlage für C-Messung
%[text] this one uses visadev instead of gpib as gpib seems to become outdated in matlab
%[text] 28\.07.2025
%[text] HP4192A is a little bit sticky to program. Sometimes it takes long to answer
%[text] ## Hinweis zur Kalibrierung
%[text] ### L-Messung
%[text] wichtig ist short-Kalibrierung bei niedriger Frequenz
%[text] ### C-Messung
%[text] wichtig ist open-Kalibrierung bei niedriger Frequenz
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
A_Header = 'C';
B_Header = 'Q';
%IniString = 'A1B1'  %Z,deg
%IniString = 'A2B1'  %R,X
%IniString = 'A3B1'  %L,Q
%IniString = 'A3B3'  %L,R
IniString = 'A4B1'  %C,Q %[output:5c7497fa]
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
startFreq = 20;
stopFreq  = 2000;
stepFreq  = 20;
dcOffset  = 0.0;
amplitude = 1.0;

% Achsenskalierungen nach Wunsch
yAchseLeftMax = 10E-6;
yAchseLeftMin = 0;
yAchseRightMax = 20;
yAchseRightMin = 0;

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

d.setOscLevel(amplitude);

d.send( strSpotFreq);       % Spot Freq
d.send( strStartFreq);       % Startfrequenz: 1 kHz
d.send( strStopFreq);       % Stopfrequenz: 1 MHz
d.send( strStepFreq);        % Schrittweite: 10 kHz
if dcOffset == 0
    d.setBiasOff();
else
    d.setSpotBias(dcOffset);
end

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
h= figure; %[output:0606e310]
title(titleString); %[output:0606e310]
grid on; %[output:0606e310]
hold on; %[output:0606e310]
set(gcf,'Visible','on'); %[output:0606e310]
yyaxis left; %[output:0606e310]
p1 = plot(data.f,data.A,'XDataSource','data.f','YDataSource','data.A'); %[output:0606e310]
xlabel('f/kHz'); %[output:0606e310]
ylabel(labelLeftY); %[output:0606e310]
ylim([yAchseLeftMin yAchseLeftMax]); %[output:0606e310]
yyaxis right; %[output:0606e310]
p2 = plot(data.f,data.B,'XDataSource','data.f','YDataSource','data.B'); %[output:0606e310]
ylabel(labelRightY); %[output:0606e310]
ylim([yAchseRightMin yAchseRightMax]); %[output:0606e310]
linkdata on; %[output:0606e310]

xlim([f_kHz(1) f_kHz(end)]); %[output:0606e310]
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

    refreshdata(p1); %[output:0606e310]
    refreshdata(p2);
    % next sweep manual step
    d.send('W2');
end

% add this sweep to collection of all sweeps in a cell array
measData{runcounter} = data;

%finally clear any SRQ request flag
d.setBiasOff();
%d.setOscLevel(0.0);
d.getStatus();
%[text] ## 9) Add previous measurement for comparison (if exists)
% if there is a previous measurement add it to the current figure
if(runcounter > 1)
    try
        lastplot = measData{runcounter-1};
        yyaxis left; %[output:0606e310]
        plot(lastplot.f,lastplot.A); %[output:0606e310]
        ylim([yAchseLeftMin yAchseLeftMax]); %[output:0606e310]
        yyaxis right; %[output:0606e310]
        plot(lastplot.f,lastplot.B); %[output:0606e310]
        ylim([yAchseRightMin yAchseRightMax]); %[output:0606e310]

        
    catch
        disp('no previous measurement')
    end
end


%[text] ## 10) Save figure file
% Aktuelles Datum im Format YYYY-MM-DD
datum = datestr(now, 'yyyy-mm-dd');

% save figure to file
figdateiname = sprintf('Figure_%s_%d.png', datum, runcounter);
saveas(gcf,fullfile(pngFolder,figdateiname)); %[output:0606e310]
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
disp('thank you for running this skript'); %[output:329653b6]
%[text] 

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.6}
%---
%[output:5c7497fa]
%   data: {"dataType":"textualVariable","outputData":{"name":"IniString","value":"'A4B1'"}}
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
%[output:0606e310]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAjAAAAFRCAIAAADl0wBaAAAAB3RJTUUH6QceCgo6zg2ouAAAIABJREFUeJzsvX9ck\/e5\/38FEkiECIkGE0AMQq2MsqPrEC1Wg21H\/Wy19rQ66Q9R57opfrYd1x1nawu0rs7vup6eTqinH+evtuKRddV2O5adtsRWpsjp0RZTnSUQEUlKhAABEiCS7x8X3N7e+UH4keSGXM+HDx\/Jnfd931fuhPuV63pf7+sSdHd3A0EQBEEEm7BgG0AQBEEQACRIBEEQBE8gQSIIgiB4AQkSQRAEwQtIkAiCIAheQIJEEARB8AISJIIgCIIXkCCNgMor7Yk7qhN3VG8\/UR9sW0KId99996677nr33XeZLTab7Ve\/+tVdd9117tw5i8WSl5d31+386le\/stlsnOO8+uqrnOMAAO6el5dnsVg4B3c9jl6vf+CBB\/ClV1991a2d7ENxYJvKmME+nesxCSKkIEEaAeau\/ootGU07s3Y9PDvYthDeOHny5AsvvMDWknPnzu3fv9915IEDB2pra5mnNpvthRdeOHnypOtx9Hr9T3\/6U6PRiC\/t37+frR8Wi+VPf\/oTANTW1n799dfDWnj27Fk8rN1ub2pqGsV7JIjJR6gLks7Us\/JNXUtXHz5t6epb+toXiTuql772BbOR4fw1a+6e2sQd1ZVX2gNuKeGNjIyMzz777OLFixcvXjxx4oRKpbpw4UJzczO+arPZysvLObuga8JRqdra2pMnT+LRampqli9ffvLkSVSsCxcuGI3GDRs2XLx4EfeqqalhnKGvv\/66trZ29erVKpWqvLzc1T9jUKlUGRkZTU1Ndrud2XH8rgRBTGBCWpB0pp4f7r9k6XEwW\/7t46Z7kqVNO7PuSZb+28e3\/W7t7nNY7QMVWzL+99fzD5w1ucoVwRPi4+PnzZtnNBpbW1txy3\/913+dPHnynnvuYcYwnlBGRoZKpeIcITMzUyaTSSSSVatWAcC1a9dsNtvZs2cBYPHixQBwxx13ZGRksHc5ffq0SqV64oknli9fztZCV6ZPn56YmMg4UqdPnwaADRs2sMdg9A85d+4csx2jjq7hRLfbMcDIPGUHJ5mXTp06hXs98MADer0ej8aEFvPy8hoaGjghTYLwH6ErSPuqjLl7ah9KlzFbWrr6\/t5g\/V6aHACezFJe+sbW0tWH80Z3vfy5oa1vzw9T05VToiLCEmIigmd4iFJYWMjcczMzM5momivNzc0XLlxQqVTTpk0DAL1ev3fv3g0bNuTm5nJG7t+\/f+fOna5HYFwfVIurV69KJJLf\/e53Fy9eXLBgAQy5NahbAGCxWGpqaubNmxcfH7948WKj0XjixAkv7+X++++HIZ0zGo0ZGRnp6enMq++++25hYSHzdMOGDahJr776KtufO3ny5BtvvOFl+7CcPHmyoKAAHxuNxr1799psNovFsnnzZnTaamtrn3322Rs3bvhyNIIYO8JgG+B3Kq+06822jdkqfHzgrOmNNalREcJvJ0b944W7zxm6\/t5gxZHmLodzwBk3dVBs2rr6zV2OnDmxTTuzAKClq2\/t4cuv\/PPg7FFUROhqOQ+pra2999572VuWL18eHx9vs9n27t07ffr09evXf\/LJJ8yrKDAAwLgFSEZGBobpOEdjo9frn3vuOZVK9fDDD+OWTz75pLa29rHHHpNIJHgElDSUK1dkMplKpTp79uycOXMuXLgwb948sViML+FclEql2rt3b0pKCk5clZeXMw7Z\/v37URQ5eNruHdzr3LlzGzZswCgiam1GRkZpaalMJkN1nD59+kiPTBCjYPLfVReooz\/Vdyx97YvffNjIqBEALJg1FR+wkUeLFNFCAFBEC+XRIvZLcdER6xcqv\/Pb88ter30yS+m6L+FXiouLLw6BszteBm\/YsOF3v\/udRCLBYN2\/\/Mu\/eNIGDhKJ5MUXX2QOzomkASu14Te\/+U1KSgoAMNE89OHQe\/Oe2pCYmDhv3rympqbm5maj0bhw4UKJRIIvtbW13bhxw2g0Pvzww3fdddfDDz9sNBpRKjBauGHDBk4oz9P2YcnIyLjjjjvg9gjktWvXAOCxxx7DK7Zs2TJOcJIg\/MfkF6SoCOHhtXPvSZZ29ToOr507FiFBb+nis3enK6eMo4XE2GEnNVy8eHHr1q3Akgq8WWMcrLCw0G1SOAMTnbt48SLe62fNmoUvMWrEdkcwQuh6HC+pDRKJRKVS1dbW\/vKXvwSAmTNn+vIeFyxYwORT4JvCN+JpOz5lsidQ6tgHTExMZDwzguADk1+Quvscaw9f\/nuDNTpSuPbw5e4+h5fBGKYDAHOXo62rP1A2EnwB5\/Nxhp\/JzUPBsFgsO3bsMBqNxcXF7OAYZt+5OnDeUxtQ6oDlpiByuXz69OkqlerEiRPMAcvKyhgPD+Xns88+y8jIYJ\/C0\/YbN260tbUxdg57BfDN\/ulPf8JZNIxG+n4BCWIsTP640zlD15KUmI1rB+eQNh2tY6J2HDhhOiZ8R0xQ0NfBuSIYShYoLi5+9NFHPe0ik8kyMzP379\/PzA8tX74cY1bMiqXCwkJ0tjIyMnbu3IlTPvPmzWOfd+HChSdPnjxx4gT6aq5MmzZNpVIZjUaOmyKTyR577LHCwkLGAADYsGHDpk2b2AukGNtkMtmvfvUr1+3x8fF2u3369Om1tbXsQw0Lhu+YOTm3WYgE4Scmv4eUMycWMxrwsZeoXVx0RNoMydvVJgB4u9qUNkMSF03ZdCHHpk2b2HNIOBeFeXSugw0GQ21tLebXsbfPmzdPpVKxFypxwNx0AGBPICGPPvpocXEx83TDhg1bt25FcWXPaWVkZDz77LNyudztdolEIpPJdu7cycjJ73\/\/e19mg2QyWWlpKY7MyMh4+eWXKaOBCBiCEG9hXnmlvei\/rpZvTEPtaenqW7Xvkv6GPWW6mNlIEKEDZtwxaX74lEm6C7Z1xCRnwgvS9hP1KdMljA9EEMRYYK9DYkAvLVgmEX6l6\/iurvcGV+PFbHlHkrmSsz36kR3RK7cHxpiJHbLbfqL+rRpzsK0giMkDJ9AHpEaTGlvNcdunh+Je+1p5qDtmyzudf9zUX1cDAP11Nd3ag9Oe1057XtutPYgbA8BEnbTH2JpsivC7SdHBtoUgJhUpKSn\/\/d\/\/HWwriEAgyVzJuESRqQvCpsQ4LNdFkNl78SPhtJnChLkCiTTijoW9Fz8SpWYGwJ4J7CHtXZP6zro7p4rDg20IQRDEpKL\/+uUweYJAImWeBua8E9VDiouOiIuO8L6o6Jqlt6m9Fx8rp0Yop1KGAkEQoUVYW6PAcg0fh09PCp8+y9PInlOHACAydXCNnShhLvOABGmsXLP0\/vDA5cY2Oz5VxUQaO3prtmf59aQOh6O7pydqyhShMGgXlmzggwHBtOHs24LDP3GWdo\/IBsHz33IufAK+\/9y4mxPSnwUfbDj1juCvL+NDcbpGuqHUrSbZao53vbczZss7YbJ411cDxqQVpKb2XlSjkry0mTJx\/Y2eXxz7h2PAmST3Y60Uu81p6uqJi54qFkf67yxkA\/8NCKIN9ikiC0B8bOSIbDCHCSRiYXTs+Jsayp8FL2x4cCNkPgAAdt0pS3nRlBuNroJkqznesecJdoodsMJ0AXOPYBILEkNephIAFqfG\/uLYP\/630XrnjCj\/nUtwM1wsFEhEYWJR0Ga2yAY+GBBEGxzhAgCQiMJHZMOK+CN5MuU2P5gayp8FL2xQJoMyefAxt0slAICt5njnHzdNe17LTlvghOmY8J2\/mcBJDT5yum6wu2uSXHy6jpqMEQRBDNJfV9P5x01Tf\/QGJ4ku8q77+74+219X019X0\/f12ci77g+MPZNckJLk4t0VDfg4OyW2rMYUXHsIwt\/8JerB7878ZPhxBAHQe\/Ejp62zY88Tpvwo\/Nd1fBcAiFIzozTrWl\/StL6kidKsC0zON0z0kB22lvAyIC9TubvCcLqufXFq7OJUWVmNqbHN7tdpJIIgiIlC9MrtnqoweHnJf0xyDyk7RZadEltWY4ShyaQqfXuwjSIIgiDcMMkFCQC25SaX1ZhwJilJLm5s89iZjSBClvebH3+643CwrSBCnckvSItTYxknKTslllmZRBAEQfCKyS9IMOQkAUCSXEx5DcTk5gfdH\/7PtWXBtoIgRkNICNLi1Ni2V3MAIEkuAQBykgjCC\/QHQgSLkBAkBsprIIhh2V3RIN9aGWwriFAktAQJaHksQQwHekjkJxGBJyQEyWE22HRafJydEhtUWwhiYkCBBCLwhIQg2XRaY1GOw2zYXdFQVmOivAaC8MIHBfODbQIRooSEIDFsy03GMg0UjiAIL1BkmwgKISFIjparzONtuclA4QiC8ApFtomgEBKChPS3GAAgL1OZl6ncXdHAFF0lCIIDrdgjgkJICJLDbGA\/xZZ9uysM83aeob86ggCAFfFH3oxZyzzdlpuMS\/cIIpCEhCC5goG7mTJxQdmlh0rOB9scguALuysa5u08E2wriBAlJASp32yA2\/2kxamxuEj2wo5FADDqv8DGNjtJGsErxtgP6XRd+0wZ9WchgkNICJJbSvLSrlnsZTXGDwrmoziNgip9O\/5j+tIGhsY2OyUKEn6CGoYRwYK\/grSvypi4ozpxR\/W+KqPbAdtP1OOA7SfqR3eKPWvSsH0fRvAQvNfvrmgoKLu0u6LBi9Kge7RnTRpmSYzOhtFRpW+nCTDCH1yzUAfLUKS\/rsa8PXPA0sxs6Tq+C3vItr50v9NmDYwZPO0YqzP1HK7+pmJLBgBsOnJlUUpMunIKe8C+KuPfG6z\/++v5cdER20\/U76sybsxWeTqao8Xgdvvi1NhtueoVpeeB9avQxfMw4Kt5mUq2bjEbF6fGAsCK0vOn69q\/mxiIv2QUwiS5+Mg546h9O4Jg837z49KOdY1t2xrb7FiDuKDsUmObnRbJhgL9dTVtr6wImxLDbLHVHLd9eijuta8FYmnbK4+0798iKzgUAEt4Kkhn9B3q6WK1PCIqQpidMvWMvoMtSN19jk\/1HU9lxsVFRwDAk1nKN041d\/c5oiK8vR32aiSGbbnJQyXABxv3JcklM2XixamxjW32shpjY5sdG5\/vrjDsrjBsy1XnZaoY9SrJSwNWy6XvJt7maa0oPf\/+5vk+\/t7EiShf\/v53VzQkycV71qStKD1PHdmJcQfnkBanygrKLgXbFsLvdB3f1fXezsgFjzn01czGm9cvhckSBWKpQCKNzLivt\/Zjp80qkEj9bQxPQ3b6G7aEmAhGYPQ3hmnz2tTR29034OlVTto3B1yZtC03Gf8xTk+SXLwtN7kkL+3CjkXvb56\/LVcNAJgs7hqge3yBCnULADDit6L0fHZK7LydZ7xPLz1Uch6PhlI0bOgPBXLPmrTFqbFJcjGtppoEjL2c1em6dsazH0s\/JDwI+ycOTVVOeiJSsmbsNYkXPMLeGJ6QNmBpctqtTpu1t\/bjyIz7AqBGwFsPCQBSpkuYBxxBiooQJsREvFXTsuKfpsVFR7xdbaq7YTd3OdBhYlOlt8TfHPxTdwwM2PpvjsIShVSkkIruniVdOS+urMb0+ieNh88a0Vv62bIkHLNynmJ3RcPPy7\/+pxnCN88ZspJj\/vPH3xaFhz0yL27L0Utnti1we2RjR1+Vvv3ny5LQsFcem7No97ms5Jis5Bi34wFgd0WDKiby7llSW\/\/NrffP+sWxf7zy2Bz2AHv\/gN3htPXddIaP5s2OC0G3IegGjMgGdERWzlOM7kTGjr4VpedX3T3jtdV3AoDjphMA8Bs1ouvgGBiov9EDAAqpyNZ\/E7+EV77pVkhFozMMmVifxSS0obURWq+C59\/lERlufr5IMlcKZQnm7Xc7bZ0xW96RZK70q40M\/BUk7+xYnrTpaN13fnseAP71\/plycbjbYbsrDIcdpg8AAMB6vb6zvXcsJxWGCZ7KUj2VpQKAzxs7i\/9Sf\/issfAHs+NjIj\/40qyIjqi+2tnQGv7cg7OyZsv2V13\/f6evq2IijR29K0ou7H0izfWAb37WpIqJTJ4uaW7vxeP\/eHHCP+\/94seLE56+N9F1vLGjt6zGtPeJNByP9V0++NJ8d9JUZkxvb29Ll8Mp6YvsFYzubX7e2PmXL288fW+CKiZydEcYuw1jJOgG+G6DsaMXAJjPdHQU\/mB28V\/qn8pSqWIioadfAIBH8\/06CAacnXaHrrlLFRPJtkRn7Eoe+mk4OibQZzE5bfhwn+CvL490p67ju2yfHlLs+jxMFm8pybefey+k55CAFaZzG6+LihAeXjsXH1deaX\/3gkAR7ea9lOSlqRwyeBUAQCwKk8WO8g7rSnys4qFvK17\/pPGn71wCgCS5ODsldtv98QmRNqVSufjVC6JwARPl+7yxc8vRy3\/+6T9xDvLl9S7NHFn8kFWNbfaKr1pL8tKOnDOuKL3wy\/tn5S24LWdhy9HL2SmxD3371k\/p7JTYjy+3sbfYbU6BTaiMiRSLPb5ZjPtVN3S8tvpO1ymoLUebhWGCn7xz6d9X35mdOpqaZr7Y4FeCboDvNpy6YkmSi9mf4Ch4+t7E4r\/U19+w3T1rqn2KyAKAXyrfr4M5TCARC9ttjtnTJcwXMkku\/srY7fa3ke9MoM9ictrw4EbIfAAA7LpTlvIiX\/bAMJ1kSX6YLB4AonO3tO15sr+uRpSa6VdLgbeCxAnTpXj9jaY322bJI6Mi3MyHzZSJ7+5tx7RxUXiYROTekRo123KT8zJVjW12nHay2+1Go10iClu7UMWk5OVlqgrKLlXp21\/\/pJG9b16mqrqh47nls9Gqxjb7D\/\/flzihhXnkz7x75b0LLYtZklDd0JGXqWSOk50ie3yBqqDs0nPLZzO6IrgZLhYKJKIwsYc3iycCgJky8eufNGJeBsPpuvbqho73N88HgBWl57flqjm5hb4wrA1jZNhUDn8b4As+2vB5Y+dMmXjs38zslNjqho61C+PrO3olAHjAEV0HYVhYc2svDO0LQy74GG2bQJ\/F5LRBmQzKoT\/h8oCeeRTwVJAWpcQcrv5GZ+oBgCp955NZ3OTmfVVG\/Q3brodn60w9r51q\/sNjKd5T7IQKtZ9MTZKLXW+O7Jt4klz8QcH83RUNuysM7OTy3RUGAEC9wUzu7JRYZkeUOmzgxBzq\/c3ztxy9VKUfPALA4AHLaoxuZQMz\/WCod3t2iqxKbymrMWESR1mNqaDsEtOSA9ld0ZCdEotWXdixqKDsUmPbJY5oBRc0O8CV1k7XtVfpLaPQ5mFhfs2MEfxpsi03uUrffj8AfsojPYhrkifVxQ9BMLPO9umhKUvzw2TxXRV7hNNmChPmBuDUPBWkdOWUtVkzcvfUAkDR8iTM+e7uc2w6Wrd+oTJnTmxepmLT0brEHdU4IGfOMH\/SknSN\/632xrbc5OwU2Zajl7BYEQDM23mmsc3+UMn5kry0shrjNQt3zUeSXOyqBMzuMBh5M5bVmDAlHYXk50sH12MxYoaVZAEA11QxTg\/6YWwxa2yzV+nb0T2CISl9qOT8QyXn+bMeJS9TeeScMZAmYdpklb49SS4Z34VfeMGZ6y\/fWnlhxyLf8\/gLym79VkBvpqzGqKtrvx\/gdJ1l7KYuTpXR4uvQJHrl9v7rl1t+cQcAiFIXyZ95L9Sz7DZmqzhrXdnzRuzH3mFyS\/q9Jn8HgMWpsYycYD2Ikry0xjbbvJ1nkuRiRgZ8BxPTk+SSgrJLeZlK9Lp+vlTV3OnY\/H6t0epgFvMy0sUsqMK73rbcZPxZjQdkksjZqer409vTL24mLXi8fun7QkleGubTu3VPx53GNvs1iz07JXbcVyJzkqqT5OIqfXuS3KdT4ERgXqaKWaWQJBfvrjBslouhDcpqTNtyk+OmDHsYn07k\/SKjrB45ZyzJS6NVcRMUSeZKTiqdrOAQBCSRgQ1\/BWm8cLRc9V+8btRU6dux0AMAZKfIxnIrR4+B+SUb\/+wZ3PgfT92KxaF0bctNxjtglb4dFwLnZSrZYoMHwSgfh4KyS5xAWWOb3bUoLZ5x1fzpVmtX0Upu7Qy8c2WnxI7itsX2BtB3xJVebv3I8QXDmHmZqnFfiVyltyTJxcynn50Si78tfLSKvS8MOknted9SQh3gGrXfPzKmGCN+PbxoJH6g+DsG\/UheRXcZ3qtt3\/+p6T+eUswmueQ3k1+Q+MmRc0ampvLYHYsPCuYzgmSz2aaG2X\/w3WSx2M0fH95M2fcX1LO8TCU6HHvWuP+RW1B26Zrl1s95jAduy1WjL3XNYmcWBQPA7z9uAoA3z53BKGJepqpK3366zsIYiWKMRTHwCuCtDWtkuJ69rMZUpW9niwEKKpo0xvCdfGvl+5vne\/oUhqJq85mVyON4z92Wm3y6rr2sxtTYZsNV2GU1ptN17cN+JdCqPWvSOBsZlwt9X98FaUX8kbwY5TaX7d7n6pLk4hWlDeiI+6+sw+m69i1HL+Fi8FHsjhO0AFB9tWt2XPR4W0eMJyEkSJ4q2gWFDwrmj2+BcOZntd1uNxrdl6N1y7bcZAx\/7a5o8KQHwIqSLU6NRTXCqkjbcm+NYQcGcQsGkTBCmJ0Si3FFALhmsQ9Na3FJkovRjCS5pLHNhjdZdCjLaowAkCSXHDlnvGaxb8tV764w5GUqPd3EH\/mPWs3c6cM6oO9vno9FntwOY2d54G3Xd0Eq+ujGnHjHc9+\/w8uYbbnJW45ewgpyeZlKrEHl3WDMVdmWm8wedrqu\/ZrFfmHHItmXV81Dzs2Rc8acmT4aC7srDGU1JvYkpS8w47HUkD88JPxmjjrns0rfHj9VeHfCxKv9eLqufdTveoIy+QXJYTYI49Q8jNoFbMbFOygVOGnvZR6LiZJty1UzauQ6BgODV5rbv6w3opdWkpfmVi0Y9WJH8PIyVWU1xtN17ShXuL2xzY73kdN17Zj0lZepxOkKJoy2ovR8klzMuZkKhcLdFQamPC6wsg3Z2SVYY5e95XYjTcxl4UQ4vfM\/TfYPLnUlfeM4a+gqyUvDK+z6Mx8Fb88a1YrS8zNl4m25yStKzzMzQ67gm8W1Aa7HSZKLy6IeLJj5SRtAXqaySt+eMzNAXzN0dscS0nyo5LxrABY\/dPy+jSLnEwOJq+ZPT58GT\/\/ZxMPaj\/KtldkpsW5dfGzbNpbqTfj2vXyd+MbkF6Sg5zLwH7wJciYkXMnLVDa22Xz5EZ0kF4t6b\/3Zuz0so16uxjBeF5MNz74Hse8pKEJMFhznUOU\/ShOLxUM+lgVuSZoB1yzDkC5i6Mw19FdWY+RcFibC6f0KAJatmio8+8z8VX+8hE2zUPgXp946Bbo1KK7oqGHhxC1HL7mVfEaNONeNOQ57I7osG74TrfJYB5\/LWFrz4VXyPSnDFbdizPZQS\/LSsB8m+oLMGC+FifEbgmGD+KlCPsxycUTx\/c3zy2qM83aecftnNUa\/EyPtZTWmidKQnqfFVf2B9xKroczi1NiSvDTOhIRbtuUmjzSkMxYwG57z1+jWMyvJS5spE7tt3YuKguL3QcH8tldzLuxYxCQfrig9v7vCIN9aCQBV+nZ0gPCuhx2nONqD82Hs3MLdFQ27Kxpcf8aermtXSYUwdBvdsyYNe0IyqYy4L+MgoqNWUHYJfxe7ppaU1ZjcqhGjqZwrk5epTJKL3zw3gsiwj7+jPUWbk+Ti03UWzsZ\/P2V86FCTj2dHzWZv\/KBgPvN+cR0Ckw3EHgNDsuSFVfOnjyiL3U+FZTlN4vGvz9O3l4kNjO5cHxTMx4UEE6UKc0gIkkihFsbNCrYVvIapcc4fmJkqH8ejn+Faix3DbuyNTCQQ7+8XdizalqseWmJsQk1iVId995dvrcS8OFQgrOmOk2Tzdp7BUzPJHVX69ofSotHJYy4v0xMSAKr0XLcGz4V3K1yjhu5dY5sdO4u7VSP0bt06bdtykz+41OXL1Xu\/+fGnO9zn+OLZ2U+xfaXryAs7Frn+lj9d1353wi2llG+t9HKjL8lLc+2\/zPlmluSluTrWqEnei+uPaCYGk0jlWyvHd64Xv42e7HcrG0lyMfr3XuB8wzlsy032NGXLNyZ\/yM7RYpB8SxNsK4iRId9aiVEs3yP+GAMsqzGiQjy9INbS39Xc6WBCeex2Vqh2zP2d+R\/zJjCyhwdknwKDaY1t9sa2QcXKy1S+vzkZ4y3MqRl5iJ8q5Cx5Ru9nd0VDkjytoOwSEzlkwKIe+EMe+wK7vlP2QmZXn4ntozySEfvhheiFr5zHPJFh78jZKTJwiSkN5VAMTq2jjvqY1ojC\/OY\/35bVWVB2ydPueOk4gU0fwUXcuBjA04oo3yNXSXJx26s5mFbgJQlzpGAQ2O2vB8wbyk6RcVbXZafEevfVmI6dp+va3V5YjDNvKat+buxvwM9MfkEiJiKjC3kz81Jvnbm2u8IgFAqzU2IfX5DGrLJiF3ByVTtGgXASy3UCHJc2M4LB3KfQWmalF54FAJo7He\/VdrFjoZhivuXoJfQwUAA4MFNr7DRuNK+xzb7l6CVGWd1G8H6rqv7ltfUATnz69IJYbROcNXSxF0TjXBFz40uSS7IBAGB3RcPuisFyQXjfxBkdnN86XdeO2RnM\/RS9By\/Lk9F+DF0OXUMZ9qLlFKxi3kVJXpp8a6WXhdhV+na3L5XVmHD9MgDM23kGM1\/cWsU+Gv4E8STVzHsfF01q7nT8+ymTJ6uYeUTMM2KGDTuNhCKHhb7m7TzjNj\/+8QWqgrI71wuV8jG+Bz8z+QWJPXXkMBt4mG5HjDur5isWKx0qlYq9GAsz0\/AexG776wlPA7DMoKdXcUJrW27yT96qffNc+7ZcNfvugOl8e9akbTl6adgsEtcbPd53cF0O28PzQvxU4S\/vG7wOzP2XiQQykcn3LXaYMniKxxekzZSJq\/QWpiQVTkUUlF3CmS08KQozO8UfAJiVA7jIDDM74qfeus+gA8TJfThd13667lZGCc6lsVUHrcW0TDw1Zy4Tf23sWZOG64W35c5nnGBPV4a9SsHLB8poEqdbtCe8LCP7\/Lrdk3umdMKQAAAgAElEQVTEPleV3pKXeSsRBX1KT4fF2ivoauM6NvyMOD\/p0El6szv\/de\/WB5vJL0gAIIybRTpEIK6BuNEdZNgB7\/0k4\/N\/XLv7ztv6SmA6Hy6sGfXZ0VEbRQazl\/feuFmcFCX+LSvggyE+dPgw\/xDDiXgE7HKLy6ixtBKzaIzJzmd46FCTUDiYTdDYxi3CNLT0WI0PACBJLkmSi+VbK3EMa7sYI4eYF8C4AqhG6PIuTp2PXZi9BxWZMNf7m+fj5J8XFwQvOM4Xuq4uYIPOsas7tbuiIWuWtOijG8M6bYtTY12FB6eRPGWrsrUHl7K5PfIvvyP4Z33u69Dn3YDgMskFCd0jUiMiKLA9Awac6sBb8FgOHpj1NOjwYdohk\/CGKsXogVtLUJxWlJ5fNX+6TOSwOm95exjPZAS1cbBvugTLFLFPjcU70Gljr1fDEo4rSs+X5KVhYh67wghTERitTZKLOTX9mCr4MFQoi10V0NN1wB8B6GK6fb84iZiXqeRk7aOvtrvC8FBa9CMZo4n7oVvsdp2WW1Pdbs+a2v50xyGAvFEYEDAmuSARRMCQb630ceoL67uzwzJ8YKZnhSvJS2OKvjOZFJ6KPGHNQ\/ScAODfV91hNBo54dPdFQYmaocpZDg15XsJKHQFsDCx66wJk+DAbImfKhQKTRhRZJZdM\/f3shojZkNg9vy8nWfc1kfw5GLiNcEkF5xmwyVl+CqzWlzUO0yynNsjY+FanB7D3MtRF8p6upMEiR+I4tQA0N9Cc0iEH\/GxiMO4hA3HncXuMiwYGLcDALzMXbHrNWCKvOsYjFsyUTvMjGA3A\/MR9Fo8OQSonWjMlWbLleZ2qTT6rKELazZivgbb5cJGmoyG4fyZ6xld3yx6cviWUd7crrNOkouZkl5DTqHHXwCoQ1j+kclxwPF8awczvkxyQcKQHaoRQfiV7JTY03WW0dUynxDgHJL3plDseg2n69ynw8FQTxPUBqxhMbpiBN4v9VAOofi7iWKjEThemutg1DCsbuCy3svmugsuKrpmGTwLe80co9+PL1DBUC7+leZ2s42bBpKXqcRkS6wUjCMxdwPnzDiZFDxsUTaOTHJBIoiAgTfZxamyFaXcHLBJgy9ODNZryE6JZfce5IC5dhj68\/GwgYERCR\/LsOZlqnBpmuvKpw8K5mPTFtyukgrjpwrnxEdvy5UBAKYgwuCMmoF9dpRnLwagJs3beYad08ge4KVKMs+Z5IKEFb6ZMB1VDyL8B6bnYvG9YNsSTHCqg8n+stvdL+q8sGMRZscNm\/4eSDBF0HeBxETtRg\/dKUvy0hjPD+vpsb00poQ8JoB4vwjM5Bw+\/aBg\/rydZ65Z3OQ0IhiWHGOvtcDDX0HaV2UsOtkIAEXLkzitYzkDls2JeWNNalQEf98LESKgWzCxbgFIUum41TrDhZy+jMTFMfyJcGJ9kJEKpJd1weN4BPZqJCYPnsnm4ExKMUusmKXQAAAQ2a86UuXh+P11Ne1\/3DztX0+EyeJxi63meMeeJwAgfNrMac9\/wmz3KzytZacz9Ryu\/qZiS0bFlozD1d\/oTD2cAZVX2t+qafnfX8\/\/xwt3A8DOk41uj9NPK2GJALItNzk7JdZt\/YXQAR1EXyqTDpVd4Eu2Ia6b5m3PpCS5uKzGiOUYcEEYI5wcScOsmQs7Fl3YsQjDj3mZylXq3oe6K9weub+upu2VFdBrZW\/p\/OOmmC3vKA91S5bkW\/asddqsbvcdX3jqVZzRd6ini9XyiKgIYXbK1DP6jnTlbUsJ9GbbLHlkVERYVIRwSUrMp\/qO7j4HOUlEcFmcGjuKImzji1SzTqpZF0QD8M7oSx8KzqLOoIPSyNvfE9gfEnP5fFRNdj6nTXfVeMJN2nfX8V1d7+2MXPCYQ1\/NbOy9+FFExvckmSsBIHrl9uiV28fpTQwDT+\/g+hu2hJgIRmD0N7gpLikKyVs1Ld19AwCOT\/UdS1Ji3KpR\/T8ux01VNta1x8dGChVqu6lB2H\/Tf2bb+wfsDqet76Yz3I9nIRv4b0CI25AkF2uvtK2cpwiiDWx8tOHuWdK7Z0kBwOaHu8TYr8PKeQpFtCg7NRZGZGFrI7ReBc8z6BEpWTP2muwXP+4aEiSnzdpb+3Fkxn2js3Ms8FSQACBluoR54CpIOXNi46ZGLHu9tr3H8dbaO3PmeIz5NrbZflJ6\/seLE34y4Oy0Ozrbe\/1nc29vb0uXwynpi+wV+O8sZAP\/DQhxG\/asmdvc0dvc3htEG9hMGhuSp0uaR3oH+3Cf4K8ve3k9ImOZ2+0CyVTz1rk3W68Fcg6Jv4LknX1VxrdqWj75WUZcdMT2E\/V\/u9S26+HZrsPiHabsVNn7T86Pj40UfiSQiIXRsZH+s8pucwpsQmVMpFjsx7OQDfw3YMLZYP55qmTJ2uhHXxiX88bHRt49chv8R0jb8OBGyHwAAOy6U5byIt\/366n4A+qQpSTfsmet\/Jn3BBKpv4wcgr+CxHhFru5Rd5\/jU33HU5lxcdERAPBklnLTkSs6Uw9nngkRKQbLLTcCQGujRBTuP5sFN8PFQoFEFCb251nIBv4bMBFtEIaF+eOvY8Jdh8lmgzIZlENZ7OUj2E+yJB+9oujcLW17nnRcvyxKzfSDfbfB0yw7Jl7n9unoEFK9BiIEsGoP1q8KWmCKmAQIJNIweQJ7S5hkavi0BE\/jxxGeCtKilJgqfafO1KMz9VTpOxelxLBfxcy6t2paWrr6AODtahOm5LkeR3XzG0r7JgiCGBHiBY\/YPj00YGkGgK6KPcLEb4X0HFK6csrarBm5e2oBoGh5Esbiuvscm47WrV+ozJkTuzFbpb9h+85vzwMtjCUIghhXMOG75Rd3AIAodZH8mfcCc17+3sQ3Zqs4BRqiIoSH185lnu56eLbbRAY28Q6TMG4WPhYp1P1UOoggCMIFSeZKFKHbthzqDrAZPA3ZjQsqhynYJhAEQRC+MpkFCaE5JIIgiAnB5BckNlj8myAIguAhk1mQ4m\/eFrIjV4kgCILPTGZBQqhdLEEQxISAv1l24wU5RgQxLOPYD4kgRs1k9pBUjm\/YT4Vxs6hjLEEQBG+ZzIIU7zCRe0SEGlLNutnlzmBbQRCjYTILEkEQBDGBIEEiCIIgeMFkFiTVTZNrhW+aRiIIVxo3J1uOFQfbCiLUmcyCFO+gdUgEQRAThsksSAQRglA\/JGLiMskFSUReEUEQxARhMgsSpzsflmzop3J2BEEQvGQyCxJBEAQxgeBv6aB9Vcaik40AULQ8idOpD1vHfnKlg9kSO0X4nxvSsLEsQ7y7fkiUZUcQBMGhv66m\/Y+bp\/3rCU6r8v66mrY9T8q3vC1KzQyAGTwVJJ2p53D1NxVbMgBg05Eri1Ji2GLDaR27\/UQ9AHDUCGHaxQJl2REEQbijv66m7ZUVYVNiONudNmtn2XawdwbMEp6G7M7oO9TTxWp5RLpySnbK1DP6Dk8jK6+0\/73B+i\/3Jbp9lUSIIAjCC13Hd7W+pInI+J7rS\/aLHztar4F4asCM4akg6W\/YEmIioiKEzFO3w7r7HAfOmp7KjIuLjgigdQRBEJOEiJSsGXtN4gWPcLYPWJp7Ptwz9YndgTSGpyE7AEiZLmEeeBKkc4auq229K\/55mqeDVOnbxZHtABAfG6mKiQAAx02nrf+mH+wFALD3D9gdTlvfTWe4v05BNkwIA4Jog+OmEwDwSz4iGxwDA\/740wjlz4IXNrQ2QutV8Dx9HpGxzO32nlOHIjPuE8oS\/GeaK\/wVJF\/426W2e5KlXtyjn39kM2rPA8CPFyc8fW+iYNqstmt10N7rJ3t6e3tbuhxOSV9kb9BWJpINfDAgmDb09AsAmtt7R2ZDsa4foNMPfxoh\/VnwwYYP9wn++vJId+qvq+mrOycrOOy4ftkfRnmCv4LEeEVe4nXXO\/rWL1R6OUhJXhpOI6GHZA4TSMTC6NjI8TZ2ELvNKbAJlTGRYrG\/TkE2TAgDgmiDfYrIAhAfGxlEG26zh2wIrg0PboTMBwDArjtlKS\/ycaeuij2SpfkCidSPhrmDp4LECdMx4Ts2hrY+ww173FRvs0dChXpxauxtW8LCJKLw8bKTg+BmuFgokIjCxH47BdkwIQwIog2S+9bL7lsfXBvYkA1BtkGZDMrkwcflPu0xYGl26Ks7zv2JySVrfUkTs+UdSeZKfxjIhqeCtCgl5nD1NzpTDwBU6TufzHLjBrV09mEm3oiOTOuQCIIgvBAmi1e8OhipC\/A6JJ5m2aUrp6zNmpG7pzZ3T+3arBm4xqi7z7H28OXKK+04Rm92H8pjaBZyZcy1GwVBEATBE3jqIQHAxmwVp0ADZz2s6wCCIEZH4+ZkqWadbHVhsA0hgoMkc6XbiJwoNXPGa\/8ImBk89ZAIgiCIUGMyC5IxfAZni0ih7qc5JGJSQ\/2QiInLZBakD6IeDLYJBEEQhK9MZkH6S1RusE0gCIIgfGUyC5JbHNSgjyAIgpeEliBR8W+CIAjeElqCRBAEQfCWkBOkYFVqoAoRBEEQ3gktQWI3kA0wLSXrKRmXIAjCC6ElSMHCYTbYdVogP4kgCMIz\/C0dNJnop9Q+gt8klTYE2wSCCEkPKfBuiqW8WJyuAQCbThvgUxMEQUwUQkuQgpL2jfE6ybc0s8udUs26wBtAhBRSzbrZ5c5gW0EQoyG0BCkoYLxOnL402IYQBEHwGppD8juSdA39YiUIghiWUPSQKMWAIDg0bk62HCsOthVEqBNagiSijrEEQRB8hb+CtK\/KmLijOnFH9b4qo9sBlVfaccDS175o6eoLsHmjgBrVEAGAvmbEKOivqzFvzxywNOPTAUuzeetcU36UKT+q9aX7nTZrYMzgqSDpTD2Hq7+p2JJRsSXjcPU3OlOP64D\/+yf9W2vvbNqZ9VRm3DN\/ru\/uc\/h4cFqdShAEwdBfV9P2ygroHVQdp81q2bNWsiRfeah7xl4TALTv3xIYS3gqSGf0HerpYrU8Il05JTtl6hl9h+uAh9JlOXNiAWBjturw2rlREcMnaAQ47dthNrB\/q+LZSQ4JguAPXcd3tb6kicj4HrNFIJFOe\/6j6JXb8XFkxn0DbdcD4yTxNMtOf8OWEBPBaIz+ho39anef41N9x5KUmGGPU6W34IP42EhVTAQ+dtx02vpvjqu9g9j7B+wOp63vpjP8JgB0fXwAps26da5pswDAer1eHDvTH2d3a0NQCLoNQTcgiDY4bjoBAL91I7LBMTDgj7+LUP4seGFDayO0XgXPP4UjUrJm7DXZL37cpa8OqGHu4KkgAUDKdAnzgCNIyFSJcOlrX+hv2FOmi8s3psVFR7iO2V1hADAAwI8XJzx9byIACADaevqhvdcfNvf29rZ0OZySvsheAQAIvqyEO+5tZs4VPkMA0HatDhIW+uPsbm0ICkG3IegGBNOGnn4BAH7rfLdBMODstDs6\/fB3EdKfBR9s+HCf4K8ve3k9ImOZl1cHLM22Tw9JluQLJNLxtswN\/BWkYSn5tBl1aPuJ+mf+XP\/GmlTXqF1JXtpMmRhYHpIRYGr39ejYSH+YZLc5BTahMiZSLI60ag\/Z268pfnYIWOcyK9QSv53d1Qb\/nYXnNgTdgCDaYJ8isgDEx0aOyAZzmEAiFvrjmxnKnwUvbHhwI2Q+AAB23SlLedGIdsXJpDBZYlRugOaQ+CtIjFfk1j0CgKcy49ArejJLuenIFUNbX7qS+3ZmysSLU2PZW4QKtTAsTCIK94PJILgZLhYKJKIwYfs1R9VbknSNRJnMHdTa6Kezc2wQ+\/MsPLch6AYE0QZHuAAA8Ds2Ihv89HcRyp8FL2xQJgNzFyofwX5Om7XtlUcAQP7Me4Fxj4C3SQ1MvM7t06gIYULMbQE6ebRIEc0jcbXptI4Wg6LgAGe7JF0TDHMIgiBGAKpRmDxh2vMfBUyNgLeCtCglpkrfqTP16Ew9VfrORS75C99Lk79V04LLj96uNqXNkLidQwoK\/S0Gy7FiT3VU+ynLjiAIfoN53rEb9gT4vDzyKtikK6eszZqRu6cWAIqWJ6UrpwBAd59j09G69QuVOXNiMeH7O789DwDL5sS8sSbV94P7O\/Ha\/pUWAGSrC11fEirUVu1Bv56dIEYB9UMiGAYszQ599c3Wa9\/8VIlbwqfNnPb8J2GyeH+fmqeCBAAbs1Ubs1XsLVERwsNr5zJPc+bENu3MGulhhf6uHmRpsv5xk2uwbujsQeuhThAE4QlJ5kpJ5kp8HCaLV7x6OShm8DRkN3Fx\/s+7QoXaU7yOetUQ\/oa+Y8TEhb8e0gRF8MDPFdkrg20FQRDExCPkPCSRQu3vtAJBih\/XvRIEQUxWQk6QCIJwhfohEXyABIkgCILgBaEoSI6gdoxtLsoxl6wPogHE5Ib6IRETl5ATJL92oLD+cZNz1xLvYwIwiUUQBDERCTlB8juyBO+vCxXq4LpoBEEQ\/CQUBcl\/lRp8cX2EcbOoRx9BEIQrISdIfq+VIE\/0ZRRpEkEQBIeQEyS\/4mgxgGwYQQpwG3WCIIiJAgnSeOKL34MdKGw6rZ9tIQiCmGCEqCD5L2ImGM5DIgiCINwScoLkv4jZoMgNl2UHg4l2V\/1kBkEQxASFiqsGB0pqIHgF9UMi+EDIeUj+o9\/n1UXUyJwgCMIVvwtSS1ff0te+qLzSjk+7+xxrD19ee\/hyd5\/D+477qoyJO6oTd1TvqzK6vorHwQGJO6q3n6j30R5RnBpGIh4jxoe0b0XBAU8d\/AhijFA\/JGIU9NfVmLdnDliamS1dx3eZ8qNM+VFdx3cNu+83P1XhYPYulpL8Yffl4N+Qnc7U88P9l36xNB47jsNQ19ftJ+r\/T6mufGNaXHSEpx0PV39TsSUDADYdubIoJQa7mDN09w102m9WbMngbA8iknRN\/Fs2o9GNfBIEQfCW\/rqatldWhE2JYW\/p1h6c9rwWANr2PBl51\/2i1Ey3+1pK8vtq\/yZ\/5n1mAB6t672d4dNmxjw+MkHyr4f0drXpoXQZpxM5AOx6ePY9ydJ\/+7jJ045n9B3q6WK1PCJdOSU7ZeoZfQdngLnLAQCKaJoDIwiCGD1dx3e1vqSJyPgee2PvxY+E02YKE+aKUjMj7ljYe\/Ejt\/vaao479NWKXZ+z5UqUmil\/5n2BZKowJStMFj8iY\/woSC1dfX9vsH4vTe721e+lyf\/eYG3p6nP7qv6GLSEmIipCyDzlHryzz9IzTNDPLZhlRzkFBMGG+iGFLBEpWTP2msQLHmFv7L9+OUyeIJBImaeuOzpt1p4P90iW5HNUx2mzdpZtd9o6B9quO23WERnDXw8jZbqEeeAqSHqzTX\/D\/p3fngeAlOliT9G\/Kr0FH8THRqpibg1w3HTa+m+Ou832\/gG7w2nru+kMH\/+Dkw0TyICJaINjYID+KCahDa2N0HoVPP8Kj8hY5na7KGEu88C9INmtA5am8IQ0znbH9csDPR3Sx\/+\/noo\/OO1WRtV8wY+CFBURNkseqTfbmAkkNnqzbZY8MipilC6a\/oZt2ZyYN9akRkUIt5+of+bP9fiYM2x3hQHAAAA\/Xpzw9L2D6QYCgLaefmjvHd2pvdDb29vS5XBK+iJ7BQAg2BwFC590rv0P15GCzVHOtf8BC5\/kvnD2bcHhnzhf+gqmzYLWq4Lnv+X8\/rPw\/edGbUNQCLoNQTcgmDbgV6i0e0Q2CAacnXZHp\/\/\/KIJCSNvw4T7BX18O5AlFqZmKXTW2muOj2NevgiRckhLzVk3Lin+axnFfuvscn+o7lqTEuEoIA+MVubpHALDr4dnM4yezlJuOXDG09aUruUcryUubKRPD7R6SEUA+RSSOjRzV2\/KI+cVlgr7eGRuPKGMixeJIR8tVMwCcfTv+ZwfdDFaohQ1Vsgd\/xNne1X3dCiC\/flacMsd64UwXgKSzSTYSU+02p8AmRBvG8G7GRNBtCLoBQbTBPkVkAYiPjRyRDeYwgUQsjB7vP4oR2eA\/QtqGBzdC5gMAYNedspQX+b4f4xW5dY8AQCCWhskSb16\/BJkrXV+9ef3SKOaQ\/Buy25it0t+wLXu99j83pDHpcC1dfav2XZolj8zLVHjakROmY8J3npBHi9wmOMyUiRencv0zoUINrY0SUbivb8M3hOFhEKcWCAUSUZhYFG5rb8Ttjqq3pJp1nMG4FMnVBsvlTwEAzbNUvQUAovCwEZkquBkuHrJhdG9k7ATdhqAbEEQbHOECGPpqjcgGYdjIvmk+EsqfBS9sUCaDMnnwcbmvO3HCdEz4jo1AIp3y4Jausl9PWcqdRhqwNNs+PRSd99uRGuv3OaRdD89+Mqvnh\/svtQ\/lIMROEbL1yS2LUmIOV3+jM\/UAQJW+88ksJfvV7j7HpqN1S1JiNmaruvscu\/\/WmDZD4imD3C3+SGpwtBhEs7OY8LBdd0qoUAvj1HbdKVdBAg\/1VR0tBtmqItnqQofZYNdphQo1lWElCCLARN51f7f2YH9dDQD0fX02OneL22GSzJX2c++Zt9\/tmvYd9eDPJO48J+8EIqkhXTnl4rN3j3SXtVkzcvfUAkDR8iRUL9Sh9QuVOXNi31iTuuloXdHJRgBYNidmx\/Ik3w8eyEIJUk2+uWS96zJYcfpSq\/YgZ6PDbHCYDeL0pQBg02mFCrVUs25EXjZBEMTYEaVmRmnWtb6kAYDoR3Z4WoQEALKCQwOW5taXlt1svYZbwqfNVOz6fKTBOoS\/WXYbs1WcBUy4qNb18Sjwh9vhMBskcepbp\/hKK4xTSzXrzCXrrdqDHCeJyT5nF3tl14+wag8J49R+bydIEAQBIMlcyXFoolduj1653Zd9w2TxilfdzzONlFCsZSdOXzruITs8IFtdHC0Gybc0ACBO19h1pzjjvXRFkqRrMF4nW1VIq6YIgggdQlGQEL\/e5dnBN6km3zU6B+6aUEjSNViFrL\/FIFSoJekav1feIwiC4A2hKEj+6NnK0Qz2UwzWuZ4OPSG3RzMW5Qjj1EB1JQiCCCX4O4fkP\/zXo0+oUANrFTaTPSFUqLu0h1yTKdwn2pkNACAaMpK6+REBgPohEXwgFD0kABAq1K7zOmNhUEWGkhow55t5VapZ5xq1E6cvdXsXcA3QkYdEEEQoEKKCNO6Z3xwnBlPsmKdMJjd7jNvFSQDQpT0EAIyAUTc\/YkRQPyRi4hKiggTjPYckW13IuQtgit3g43QNRu2GPY7DbLBqD3KmjvrJQyIIIgQIUUHyR+Y3Q3+Lwa7TcpYQYdSufpUA\/zUX5XAMsBwrbtycjPE62epCZrtQobYPp502nZbCegRBTHRCVJAQv97EOakTstWFqqJKbF6uKDjgaDFw2s9glA8nn9iJeb6sjTWXrG\/cnExFhohRQ\/2QCD4QooKEEzN+Wt+DOuc69yNJ10g16\/CfJF3jmuYgUqhtX2lRjThpF160E9c8CRVqSzndUAiCmMCEqCD5dX0PFkX1PiZakw8AlmPF9asEzF79ZoNdp8UMCHbKuPdDoawqCg7YdVq3K3CJkAIjw8G2giBGQ0gIksNscA1nje\/6HnbEw6a7LcXOLZjmgIVT0cVhrEIpEirUqC7DLuNF90iSrlEUHDCXrKeyDgRBTFBCQpAsx4pdw1nCOLX\/5pDYKXYexwz5QDadFlXE0WJgcsF9L6vKyKpUs06crrG8+eMRmUoQBMETJr8gYSK1bFUhZ7tIoR7HdGqH2XBLQuqrfdkFQ3MIThcx5e\/g9tUk3p059pqnuIIDjn+cBv3ZkdpPEAQRdCa\/IFmOFTNxMDbi9KXDplP7yG2lvi1NcLvYeEKqWYe72HWnmCO4XQbr3ZljyorjERQFB5zH\/nUk5gMAWLUHeZWkZ9UepPkwggg1JrkgDbpHq7nuEXvAWA5u02m50zZtTcCqIeQdRn76PSTmIV6cOXZZ8cHBC9eApan\/7FFfDEDwXfiybjdgWLWHKAuZIEIN\/grSvipj4o7qxB3V+6qMXobpTD1LXr2Azc5dsQ\/1XcWn5pL1zEtjKbHqMBtw6Y+xKMem0xqLcpiXnPXVQoXax4OjkFi1Bx0tBhhKvXNFqFA7PKQquE9hmJ01okp9OMHGH49ksB2U558RBEGMFwOWZvPWuab8KFN+lK3meHCN4akg6Uw9h6u\/qdiSUbEl43D1N570prvPsftvjW32m25fVTlM0R\/vZtSIEwUaXRMKh9nQXJTTXJjTbzYoCg4klTYklTZgh\/JBr8jSNGyKHQNjG5Mp53aYMG6Wd0+Os6Pgu4\/5ri5490dLeFLuAVXWf0XZCYJAnDarZc9ayZJ85aHumC3vdP5xU39dTRDt4akgndF3qKeL1fKIdOWU7JSpZ\/QdboedM3QZbtjl4nC3r97d+0WSTMz80MYbHFuBRpH5bdNpceYpvqiSmQRCWtD9amsSjeROyiyDdVUjzoISt2rBKSs+yHcfBZ+11qbT4syT77sEAC\/yTBDEeOG0WwcsTeEJaQAQmbogbEqMw3I9iPbwVJD0N2wJMRFREULmqeuYlq6+A2dNxT9QezrIQ90fsm9qrhVOR5r57TAP1vvxdK9s2fkA1FeP6Kc9Ru0cZoOneB06T55255QVv4Us0cc5IetQoyb+eCTj2xmE8IWk0gaKkYYgArE0TJZ48\/olAOitOwcAkakLgmgPfxv0pUyXMA\/cCtL7X7QuSYmJmxrh6Qiqm998MfNhcV07AMTHRqpiIoRzl1i1B6Of3jc4Qp5kM9Xb+t1H\/Fyxf1k5mA6X\/VT9KoHsp\/vFS9YCgN3UANNmSX\/8R8tv7gMAmHOv78cUZj8FJeth2izXvfAla+WhwammoQd4CmaYaO4S9o72\/gG7wxmZes9t79QDjsuf2nVayXMf2\/pvCuPU1i8rhdlP+Wi5F9AGW99NZ7iv14GN7SstTEvy\/RqOuwHjQrBscNx0AgBevVC+DmTDIK2N0HoVPIRYBBLptOc\/spTkm\/KjRKmLpv+mRiCRBtS82+GvIHlHZ+q50NS9+5MpqiIAACAASURBVBG1oa3P05g3p+b\/RRsD2vMA8OPFCU\/fmwjJ2YLPDjfrr8C0WQAAUxMFnx1ubu\/16ZStVwV7N+CObQkLBdNmWS584vz2DwEA7tsm0B5qiVD2\/uS97gsV9unzI308JvKLD6HtqlszBAuftJQXQTkAAPMAAJyl3YMm6bS2u\/M6Wfv29va2dDnivvuEuOZY87mP2NLl5vhlhXDHvW0JC6G9VyBNhK9O+Xo1vII2OCV9kb2jqWEj0Gmd33\/W+H9TnAufgO8\/F3gDxoWg2fDtH0LpD\/FzDOnrQDYgH+4T\/PVlTy8OWJpbX1omWZIvO9TdX1fTsv278i1vi1IzA2kgG\/4KEuMVuXWP3q42PTp\/elSEEMCjIP0lKrckL22mTAxDHhI8+CPzyV3Cv\/1Wtmk\/ANhnploA4mMjvZhhOVaMoQzrhTN2hRqmJUmUs6NjIy3fWgptjTJm3z\/oAcAeeYdpylRlTKRY7O2YXBbc7\/Glnx2EJ14EAPOLyyTpmuhHXxjcHhsJAI6+SDNAnPoOIest2G1OgU2oTL3f+ie18PMjMs8Hd7RcNX\/9meKFT3B3+7xllrNve78aPjJow0ivA2MVQNzd91vOHRF2NslGZc9YDBgvyAaygRc2PLgRMh8AALvuFNYqY4NhuilL8wFAlJoZccfCroo9stSgrQDhqSBxwnRM+A5p6er7e4P1rRozsyV3T+1ba+\/MmRPLOc5MmXhx6m0bJemafrNBIgoHAFAmA4Co\/ZqX6RPj8ZeMx18SKtQOswF7GkWvKZaIwh3fzjGXrB88zhCCm+FioUAiChOL3OdZjAZl8i3jWY8BwNbeiBuFrNMxNjjSNVbtQcnPPH63rF9\/KlSopRlDOes+XA0fGct1wDclzcixp2sAQDKqK+mXD4JsIBsmog3K5Fv3kHKvI3kAT5MaFqXEVOk7daYenamnSt+5KCWG\/WpcdMSpX\/xT086spp1ZFVsyZssjK7ZkuKqRW7BAA7tDhPfUstnlzqTSBqlmnaLgAC4wYqcABCxP2m0aBU7+t7AWV7Fh0iWYLbiKlvnHpDOwTxH0RDtJuoapmUStcgMG9UMKTTCFoefUIQDor6vpq\/2beMEjQbSHp4KUrpyyNmtG7p7a3D21a7NmpCunAEB3n2Pt4cuVV9rHcmTM1bZWDvoNrpnfDrOhcfNtjohQoZatLpSkayzlRczKocDfvl3vzravtOJ0DQC4vZXgO2UsdJgNzYU5jZuTmX+ulZM4TZiCiy+tcgmCGAthsvjYzW91f\/i6KT+q9SXN1B+9IclcGUR7eBqyA4CN2aqN2Sr2lqgI4eG1cznD0pVTPt06b0RHVhQcMBblMEmuHB+ipWS9W3cEV2uyi\/Tg7ZuRKL\/CdKPgIFKoZasLGzcni9OXum0JaNUekmrWWY4VW7UHpZp1jP1d2kM2ndam0zZuTk4qbWDG88cp8b3eOcHGqj1oLlnPeJkE4R1RauaMvd6q4QQSnnpIfoUdFOLcxK2VhxwtBlwlysFSXixO13BiXCgS9asE\/q674\/bujIWRhAr17HInFjHiDGDik1btQUXBAfTz8F+\/2SDVrMNoJGe8H9\/GyOFJ8QiCIAJAKAoSG3H6UkZLLMeKHWZDfHGl67Ch+jr5nH0hUFE71ykrfMx4PEmlDcaiHI4uMlG7pNIGtpRivQnc13U5JE+K2vm1zfxEx6bTNhflkFoTk4xQFyRsamcuWY9BLdnqQrc5Zv0tBnaRVmZfGMos8HeZAyyUx74742OmrLhQoU4qbTCXrLdqD2ILDESSrjG7ZD1gwSHXEB++I6wbG5TsBsuxYmYCL8BpIxMOu04b9AwUghhfQl2QAEC2qhDrrsYXV7rVFazt7XauaHa505fWR2PH9e6MosI2GDWp\/+x\/Ovc+3rI1DTe6LVJn+0rrsZCrQi1O10g164xFOc2sKuaBwWMlJOJ28GcQfzJQCGJcIEECpuabJy8Hc9i8V\/rysQHSWOCY5zAbXO\/dQoVauuENwQM\/j3v1ErNRnK5h17XD8KOn0nmSdA0mSmCmQ+Czgdnd33mV9ccr8KcJfzJQCGJcCHVBQtdhdrlTGKd2DW3hAJtO6zbNAbmtXayfYd+dPd2MRHFqrPbNINXkW7UHGe\/KWnnIW6uLoXQ+oUIdX1QpW11oKS+qXyUIgDKhUrLTN5jWHgQH\/PT5loFCEGMk1AVJkq7BWx4G7jihLYfZYCkvltyeXBcsOP4Qu3O5dzgLkrzE62AonY9RL8zEk60qkmrWudYdGV+oDdKIkK0qotxuYpLB33VIAUaSrpGtKsLeqcz9GrPA44vc5N0xOFquBuYeKrp9KRKnc7l3MLVBqlk32IzV8zuSataZS9bbhlr2wdC6YBguaDl2PKVaEK54\/04SxASFBOkWstWFQu0sY1GOUKEWxqkl39JYyotUw\/3lByxJGvWAidTJVhX5fu9WFBxA\/897a1rEd31F6VIUHOAesK0JIGhFw4hRwCyOJoggQoJ0G1LNOkm6xlp5yPaVFheTDnvTD1hbM6av6+jA1IZ+d6kQHCTpGh8rUCgKDliOFRuLcrDWn8NssOm0Vu0hu04LskR4\/esRWUgpdgQR4pAgccEIlQwKvbdqZQhM6aCxI9XkY9bGsD6fUKG2lBcJFWppTv6wV0C2ulCak99Ssr5xczLjfol+9Ia18fKIzBuMJa4qYm+06bTGopyk0ga2GT5+LiGLVLNuonwnCYIDCZJHJtldDyvagef+6wyy1YXCuFnmkvUoS7LVhd5vcJiPZzlWLIybNbhY2G7vMo6sOpZNp2UmqxiYCraMAVj6VpyuoUkUgph8hHqWXUgRX1zpY9BPqlnH9N2wHCv2pSKANCdfkq7BxhbQ1uRpmKfKC5jON+xZMBOPaSASmmApDQCw6bT1qwShfCmISQZ5SCEEp7KDL+NlqwsdZkPX7Z2T2Nw2b3Q7LXculn77fnR6GjcnY44fFh33fTKM0x8EM\/EAwHKsOGSXKDETga4e5KjBDyhgE6IE4RYSJGIYxOlLzSXr3Vb5sxwrxrCeJF0jLTjADLDb7ZbPPxQ2f2EpL2JWLzEPMC\/RRzkRxqnZHgAmPuB8WMgKErDqWQSyBwpB+BsSJGIYmKgd566HOd+qokpX50lgt7fL75SrVEKrqb\/FYNedwuklh9lgrTxkKS+yag\/2m4dZ4IWIbk9nsA+dEcvIhuaN2K7TMoLkevGpHxIxcSFBIoaHafTHbGF6LA27pIm97GkwRSInH2urNxfliHzIZWdmsLDzEz4O2Rsup+0IpkSGsrNITCb4m9Swr8qYuKM6cUf1vio3+VrYzhwHbD9RH3jzQgqm0R+zBZPiRueg4IIqVVGlo8Vg1R6sXyVg\/rmWyxOnLx3NpH1bk\/PYryZlLyXOm+KUeiKIkeK0WVtfut+UH2XKj+o6viu4xvBUkHSmnsPV31RsyajYknG4+hudqYczYOfJxoSYiKadWf\/76\/l\/b7C6FS1ivMBqeIxaYD+OMU6AS9I1WDuV+SdbVWTVHhxjKyaH2WA5Vtz88zugrcn8y7TJeqdmqsvjbwJqjESMmvb9WwBgxl5T3Gtf2z49ZKs5HkRjeBqyO6PvUE8Xq+URURHC7JSpZ\/Qd6cop7AG7Hp6ND+KiI+5Jlupv2IJhZgiB\/dqZ7kqjdo84cA4iW12IpR9kq4pwWS7TCGrY\/EDUnubCHACQLH7CpjsFkzEZz7UPFg\/B+UUqR8R\/BizNjqavYn9UKpBIBRKp4tWRrWcfd3gqSPobtoSYiKgIIfPU08iWrr6\/N1iL\/s8st69W6S34ID42UhUTMe52crD3D9gdTlvfTWf4TX+fK8A2RD+9z6o9aK2tFCrUVu0h4dwltn6Pxx+LDeJHdiiyn7LsHVyWi4plvV4vjp3pfofWRsflU3bdKav2IEybJb53rWx1od3e224yxbResv7+B+Ila4Vzl4zUjLHjpw\/CMTDgGHCyL75QobZ+WSnMfmpwwE0nAOCAEdngGBjw8pmOiH6zwWE2jMIGPxHSNrQ2QutV8BDX7a07B73W8GkJATXJMzwVJABImS5hHngSpO0n6t+qMS+bE7NAHe12wO4KA4ABAH68OOHpexP9YiiL3t7eli6HU9IX2Svw97kCb4Ng2izz3\/Y7Fz4pMDU415Ta2nv9ZUOEEn52Elqv9p99G5PFLXs3gDwJvv7MWdo9OKb1Knz9meCvL+MfG0yb5fz+s3DHEtuce23tvYMGJN4jvuNe84vLnL\/4EObcOxpLxkBvb2+H7u\/Onrsi4+eM42EFX1aCPKmZdfEFKYsdpoZbW3r6BQD41PcPQjDg7LQ7Oj1\/piMz0tQAAM36KzBt1uT+o5gANny4T\/DXl728HiZLtH74B9uHrwNA9CM7olduD5RlbuCvIPnCrodn73p49vYT9ZuO1r2xJpXxqBhK8tJmysQQMA\/J5hTYhMqYSLE40t\/nCrwN9lWFlr0bRO2Nkoyc6BRvN9nxsSF2DqS8CE+8CK2N9k8PozIJnv+W+N61dp0Wvv5MqFALlcmgTBbNXRL96AtuDRDmFZtfXCZ47UHZcx8Hptn8LRt0Z8XvPCW+d61s0\/7xPG5xZde7L0bHsi7szw7edt4pIgtAfGwkjOSDMIcJJGLhbYcdC3\/QGx8Xyq+fFafMmdx\/FBPAhgc3QuYDAGDXnXLb0qy\/7kxkxn3KQ939dTVtr6wIT0iTZK4MqIUs+CtIjFc07PzQk1nKTUeuGNr60pXctzNTJl6cGusX+9whuBkuFgokojCxKGjNF\/xng+S+9Za9GxyXP41eUyzxevBxtkGZLMrJt5QXDXYa\/EorTUgRf28DRvOwul10Rg47Af2WARk5ds06m05rffNHYh9qt48jluMvgSzR\/tlhyc8ODT96JEjWeGvd6wgXAAB+QCP6IIRhYd4\/1hEhVKihtVEiCp\/cfxQTwAZlMiiTBx+Xu3k9fNrMKUvzAUCUmhmR8T37ufeCKEg8zbJj4nVun3Jo6ewThAkU0fwV10mDbFWRLy05xh3MdY7W5MtWF8YXVSoKDrD7B6qKKo1FORgid+1Dj9WPpJp1xqKcgGWj2XRae3Od4KdHYLiOWQ6zoX6VIOhpckmlDeNeN2iypjhOJoSyBIiUsreIEuYGyxjgrSAtSomp0nfqTD06U0+VvnNRSgxnwPYT9bj8qLvPceCs6Z5kaVy03yNyxLCVv\/2E92ay2O23pWQ9Ltfl3NyFCrVsVZHtKy02wx0Xe4a91UrSNfGvfw2yRJAl2nWnvIxErRVNukZQknRNPwkS7xEmzA2bEtNz6hAA9NfV9H19NvKu+4NoD08FKV05ZW3WjNw9tbl7atdmzcCcb1wMW3mlHQB2LE+63tGXuKP6zhc\/x6dBtpjwG4MV87zespkSruJ0jatuyVYXYgP4cVFTq\/Zgc2GOjz\/\/hXdme\/eQxj2NGyu1j9fRRg0upg62FcQwCCRS+TPv9dZ+bMqPan1JM\/WJ3aLUzCDaw98w18Zs1cZsFXtLVITw8Nq5ro+JyQ0WI2Cqt3kivqjSptN6cjUUBQeiNfnGohwfGwF7wmE2WLWHJOkaHyVEkq6xnv1PL+uobF9pGWNGXTGWV\/XrsC4U9i4Jti3E8Agk0mnPfxRsKwbhqYdEEAy4GsmXHDnvOoG1IXAyiV2vaES1IWw6raPF4LtsDCZieDg+louN1uQDgFV70Ko96N3xshwrxk5IrmcB3tRroFb0xKjhr4dEEIjEXRRudDDVXfHejVNKDrPBWJTj+nPeVXWwLpGXyX9M+eN4Kl4KFrAnkLCquvfSEl7u9UKF2kvbqmEZ335IIn4XkiB4CwkSEXIwBSAk6Rpr5SHbV1pA1+d278S1BRTKGFu6motymCYaDrOhZYQxN84Ekmx14bBRO0\/3+sCnPnrC0WIYNr5KEG6hkB0RuqDDFF9UGV9UmVTaIFtVxH61cXMyOx\/BbUlZu06LKuUwG5oLcyTf0tySq7Ym564l1j\/v9GIAx+PB+J6XJAhHi8e5KHH6Uoz4YQF1Lyf1K9jDHqf9CGKkkCARxCCy1YVJpQ3MP0XBASZN3KbTWo4Vu5aUla0qMpesRzVih7wcZkNL6Xr47qPW937jfQJJtuo2hUMnydN4h9ngaS6NV9NIqJrmkvVuZ7y8QEuXQhwSJIK4BQbQ8N9gXVftQZtOy6TnccbjqlvOBAzqk2hOtuCBn8t+fdLTgly37ZqkmnXidE1zUc7ojPe+5ikAsGfFRtrLqnFzsmtDLCKkIEEiCI9INeswyRsdJs48DeY4oDdgKS\/C+ymuUpJq1slWFwGAJF2DhSTqVwk4d2fMCXSd+4krOICtCznbh11Ciy1CRv4uxx+8Jvi\/720S+TMNRgQLEiSC8Ei0Jh9niVyDdSg8Vu3B+OLK2eVOTCi3lBdhmhx7qkmSrhGna8BdPM1tAh521MWWQuztwy6hxWieo+XqiN7j+IJG4mMUGPtXWh\/3ZabB\/GEYMSEgQSIIj6CWdGlvq47qMBtwSkmqWZdU2sB4A7LVhahMrr\/044sqMau7cXMy88\/LfA\/6VezjWLUHbcPd2QenkXwWAH\/AkZMRVaDg1TQYERRIkAjCG1JNPicOZq08ZC5ZH19cOaJVOxjxc5gNuKxKkq4xFuV4qa3HUTXLsWJHiyG+uNL7WcTpGqkm33erxp1+s4GzUsoXgWEqzPJhGowIIiRIBOENJrUBn2I9hfjiylFUn1MUHBCna\/rNBkXBAUXBgaTShn6zAWeeMIMO\/7ndFxP\/hj0psygqWGAOPfNUkq5x+DCH1N9iwOk0\/kyDEUGBBIkghgFTG2Aoi0FRcGDUtVDxZt1clNNclCNUqAdDeeVF7FCe78lmuOrIXLKeDw0s3CJUqKG+ethhdt0p4VBiHlDydwhDlRoIYhiYqqw4bzTGZLD4osrmohy7TotViLCUETsVDTt72r7SxrGUz2E2MEUlWCO1QoVaGKcWp2uMRTljKa7qpb4RuzLsSCumD66QtTSBSuVlmO0rLRZ3wBYhNp2WCrOGJiRIBDEMmNpgLlk\/XtXesDA5I2yc3DlJukaak48ZELJVRZhDgarA0UIpq1Fh\/SrBePXXYIMemDhdE19UiY9HVFbcF1eSs0BYnK6x606RIIUmJEgEMTxxBQfG92e7dzcLM7+jNfmY9YDFzr3vItWsw\/s4\/hsvO\/GwAIA1F5JKGzDZ3cdTDNosS\/QyhrO+SqrJH3UbDmKiQ3NIBDE8ruuQAgAuyMXm4sPGCf23iIc9Z9bfYsDiRm5rArktoxf\/ls378d2ur6JppNCEv4K0r8qYuKM6cUf1viqj66stXX1LX\/sCB6w9fLm7zxF4CwmCP2BhVjfZEJYm7wVehwXLT2Cau7lkPZ7CrUA6Wq6OIt3DtcLs7HLnOLbQJXzEUpJvKQnmmgHgbchOZ+o5XP1NxZYMANh05MqilBjsYo509zme+XP9U5lxG7NV3X2OTUfrdp5s3PXw7ODZSxDBx7V7Rf\/Zo84jz1stTdb3fuO9zyF2wuVkjWMmBZPmjppn150Sxs3Cwueubs1IW\/MNTSAVjWgvYtyx1RzvPfenyAWPBdcMngrSGX2H+v9v7+6DojjzPID\/gAFmFMSWlzAIijfomQAJV3WoKTGLu6ESclWJOYO3rHdGiJvCl9pNWetVGYjirrqXzZakrhTZKjIEUoZdcSqSKiXGHGIiG2HuqqiCyaUqjgsGGWTElhfpQUa4Px7sG2eGHsCZ7ka+n\/KPeemZ\/g48zo9++unnidEmLwlbGKZZb1j0rXXAtSC5rWX+giHqa+vAvfvOhWEq\/TgAMmBD1MQTPE57p\/3T94K2\/CFm1T84r\/7Fae\/k60qpTuod3JZ3YtXIdQCeuFjiUFM1GwF\/PS9InFRibOb9bOwE0nSWA4bAmRCGhMvVQZKn+uSh0m9w621haVSYWGCst310QwMAuQxtmFyfKWurw7AuNE4fueUgEcXurpI4NzN0qZrNxec6hflUw8G5vIO20o3sIMl1pVrvS\/Px3RT+gBJSPJ\/RpWY\/zmh18It7F46HpawJ0i1SOohaCxIRGWJ04g2JgtQ3fP8Tc9+\/ZcZ5PTxqtvLsRsLicH1UWCByunKMjTucE8L9BxMhDwK9L2RQcwClMmhWv8BXFGpf2DZk+q1m9Qva1w\/c7e19JMPipKleq329hFu1gT\/ys8m5EqKXR7xdKYxNEX7VBs3qF\/pOFNDDxaKIyGFpCl39gttLnLd\/nKj4xZ2EFK74K398xNmYt+2BiKj\/BvV30dTjRMb5ntH2\/+L21Ax8ul\/WYN6otyBNBzuZtHxJeH5mrNcN3r\/QSdRJRL\/MWvr2hoAfkI6OjvYNOyd098NHFVuyExnUEECxDM\/+S1D0ITZYfGL3ubsDM8ywdB2984Xzw5eJaGLbn3rujkptvLXCee4oWZqIiG+sYt96Q03Vgw4nRS+nJcvph6+Drp5ijzv47p5TB+ifiqf7Qfq7gj7Mnfjddz62OXeU+rsmtv2JoqXWqJ2\/7YGIvqgMOndU4vmBT\/cveHlPMJcgWyIJ6i1I4lHRVIdHbDgDEZ38ecpUZ49O5D+dxGlJtiMkYSJI0MRHhWu14YHeFzKoOYCCGZy7qxxf10RsPkCLw2eTYc2LjrxSp70z4uW3fGy5eBX96mP61ce2X2i4vIOa1T+xv2OITN841vlXx7mjxMbK\/7SADGt7F62KMRuHPjuiDQ2Z7pXFi1fx8Suc\/5kbe6Bxqk34L2ud1iuauGT68j+4nUaJN5vP7YFe3kGZOfRwBhC3J8eumSeEQW3az2SNNDWVFiS3bjqx+07EqtHSqDDpwXVJnDYrZXFAInoT9CBEqwnShQZrQ0Nk2ykyqDCAkhnSN0amb3ycDLoZzkYRmb3d+f3X2vgVRMTOKjntnWN9nZPrITkcWpst8p9LIp570Va60d78CRvsFxontbYTEenYHEufHZ6qhtnO\/i4ye\/uYvdPxTU1o\/iGJd5vX7SF+BcU\/vGjMY0jLaMdX99u\/vFUULz7Sf+fmkt98FqSLlCvfI1RakJ43RNW03LL0jhBRs3XwX9fGu21wuOEGEZXkLlMgHAC40Kb+xH6iQFz6nTwmQ2J0qdlcXilfV+o62I\/LK52c786DJjY5bnfVjV0rXGepYBMpOSyX2YkucUpZNuTPv59LEWw4idtqWIETsWl\/xKbJU0fsIiRud7XkKwJLpQUpNX7BtrVPvXS8nYhKc5exMd\/sqKhgXXxqwoK\/\/m3Ietvx97\/9H7a9IUZbt+PpuIiAd8oBgJvJGVGnsTAgt+WgJm45m6OWiITvmjw7kVxpYifnjWXFRqxDmthkLq9ULFT86UN8XemYvXOq1TeEz9+f+KpybHeV9rkXZ\/bZZMc+suvAxXlFpQWJiHas1+9Y\/8gMwa6XH11+5zklQgGAF5rY5NDY5OmsxuQ61R5HUn2DrhOcu65k6LkuFLfloPBdk8PSdD0viF3A69rLN9T0Mf9VZVDOr+2HczQBPvJgC5SM2Tt1z2TPeh5eNqQ+IvtNiajsSNG\/01kpe2zEqLcgAcBcwRbW82+nGVsVnqOD7MvX9XHPjbm8gzZLE5scnfUKipOjDzV9rE3NdvDdkW+ddPuKZ++sS832y0xFk9d+sYO2hxm8XsjFRmBPtVM2u7z0QVLfiQKHpclzco25DgUJAB4XWwM3QG8+nZltdanZ4oFR7O4q8TyT096pTc12Op3036ahi93C5++zt2JzQ9hKN4r5fdYk6VEYTntn34kCXWo2+zmwwzuvW7K5AZ32zliX1UPcsCnPPSdnEvflsDRJvHzuQkECgCeBa0XUpWaHxiUL3zWxCuFwOGw2W0zIqPPqX1jnntt4M9cuQQnifICexy5Dl6qdff9\/Eosd3rm\/nu\/u+2gb3elmU2kMNVW7VhQ2nIHNWxGZvZ0\/fWiqkRp9Jwr8u8iIeqAgAcATiM2S5\/qFHhqXHPmwD9Bt4xu7VsTurnIrM\/zpQxHZb7peviPOB+h54OK0d+p99p5xiTp9CvfrTzSxyYKlyVa60XWdRhZYfMRzqlxGsDQ5+zrF9QyfMChIAPAEclguT3V+xbOcxO6u8lwJlxUDXWo2m9xvqi44ImJj\/2ylGyV6F53OsYnhYeKWur4PX3eIrX9IRGz4hsNy2WG5HLnxTXaQ5LkWIl93SJzi1ste\/HpWTH4oSADwBJrRILfI7O1DTdUSK9V674J7dF\/i\/Ohet3E6nUQkaB75ynVYmpx9nZMb2Ds1scns9BIbEKGJS7afKHCtPYKlyWFp4koveR7kuV6exVYcZi9kbzvlJ1cZFCQAAGIX4UoPtpY2OSxwirrFzmPF6fVarVZ88HpeEBuGx04guVYRsbZ5Ls4rjsXwmmFZ+d8ES5P9REFk9nZ2wmxyLaspLkBWFRQkAIDJowr7iYKpVtwIBLGTcOhStThOnVxqG5uESdxe4hjOYbksXozFHuHrSiOzt3Oll8QBhwH7HH6DggQAQPToRbsyc1vHXeQ2CRNbutfrO+hSs9l4jaFL1Zq45ZrYZL7u0Ji9k51w4rYcvLFrhfprEgoSAICS2HVFvgfpTX0tresGYp+h24VTsburJPr6VCJY6QAAAPMa65Tz+5xGc2gsgwgFCQBASbbSjdp5OZWqJ3TZAQAoye36p\/kMR0gAAKAKKEgAAKAKKEgAAKAKKEgAAKAK6i1Ilc22xJKWxJKWymabxGb7669LbwAAAFMZPvv73jcXsn+C+ayyYVRakCy9IzUtty7sSb+wJ72m5Zald8TrZvvrr39itsucDQDgySCYzwpfV8d9+EN89b2oPacGP9o5ds2sYB6VDvv+1jqQHKNNXhK2MEyz3rDoW+tAavwC1w36hu\/nVf4vt0Dzj8silAoJADCn6TI36TI3sdvhKWuCF0Q5+ZuhlKlUHpUWJOttYWlU2MIwjXjXc5uKn6csWxK+88\/XJN6n2cqzGwmLw\/VRYX7P6cYxNu5wTgj3H0yEPAj03flnmwAACpVJREFUvpBBzQGQARnUkqH\/BvV3EZH6J7Ij1RYkIjLE6MQbngUpLiIsLiLs3n2n9Ju8f6GTqJOIfpm19O0Nif5P+ajR0dG+YeeE7n74aFCg94UMag6ADMiglgxfVAadOzqdDUcuVxNReMqaAAeSot6C5Bcn8p9O4rQk2xGSMBEkaOKjwrXa8EDvCxnUHAAZkEEtGV7eQZk5ROS6FrsnwXx2+LPDUXtOBXMJ8mXzoN6CJB4Vee2vm6YkTpuVsthPiXwLehCi1QTpQoO1oSGy7RQZVBgAGZBBLRniV1D8wyX+6rxvIpjPDhzfGrXnlHg+SSkqHWUn9td5vQsAAH4hmM8OfrQz+r0mxasRqbYgPW+IarYOWnpHLL0jzdbB5w1RSicCAHjSjF0zD360c9FbJ0NTFBtZ50qlXXap8Qu2rX3qpePtRFSau4yN+b5337nzz9cK1sVvXCVfLxwAwJNqtOOrCWFw4PjWgYePRLxeErFpv1J5VFqQiGjHev2O9XrXRxaGaWq2rZZ+BAAApili034Fy48nlXbZAQDAfIOCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqoCCBAAAqjCHC1Jlsy2xpCWxpKWy2aZ0lkm9vb01NTW9vb3IoGwGxQMgAzKoMINX43yPfe\/q3jcX2veuHud7lA0zVwuSpXekpuXWhT3pF\/ak17TcsvSOKJ2IiKi3t7e6ulrxdo8MigdABmRQYQavBj7drzGsja++pzGsHfhU4dVj52pB+tY6kByjTV4Slhq\/YL1h0bfWAd+vAQAAF+N8j9Paol3zOhFFvLTH2f2dsgdJGgX3\/Tist4WlUWELwzTiXa+bNVt5diN45HbwyO1Ap7p58yYRtbS0BHpHyKDyAMiADCrJEB\/ufCrMSUROe6fnsw\/6b46PT2i4pezuuDD4oP9mMJcgZ0JXQffu3VNq349jf\/11Q4xux3o9EVU226y3hd+\/9neuG\/zIj\/7mbGez9S67q\/2+Xvv95woEBQBQzjY9vy3h4ddganZkYXlIzHLx2bFr5rsf7Yr+9\/pgLmGc7+n\/w2uL3yoPTclUKOycPULyKYkL\/+Om5O67o+xu8Ehc8MjrykYCAJDZU2HOJeFOdjskZplrNVKhOVyQxG66qfrrkrjwJC784b1FRCtkyQUAMGeI3XQP+m+OC4PKhpmrgxoMMTqJuwAA4FNI9NJg3SLxbrBuUUj0UgXzzNWC9Lwhqtk6aOkdsfSONFsHnzdEKZ0IAGCOCeYSNInPDF84TkTDF45rEp9RcEQDzd1BDURU2WwrbbhBRKW5y9joBgAAmJFxvqf\/dz990P9jSHRS9HuNKEgAAABztssOAACeMChIs2S1WnNyctLS0vbt2ycIXob5HTt2LC0tLS0tLScnx2q1KpKBEQRh3759JpNJkQw8z+fn57MfRWtrqyIZxA0C97vwiv3kA\/Spp9La2qpgm5QOwAS0QfrMIEOD9JlB\/gYp7jEtLe3YsWMy7HF2UJBmQxCEioqKoqIis9lMROfPn3fbwGQy2Ww2s9nc0dFRVFRUUlLC87zMGUTnz59vaGjw796nmUEQhKNHj2ZmZnZ0dNTX15eVlfn9v5\/PDDzPl5SUHDlyJHC\/i6mCHThwIEA\/+am0trYWFhZ6fUqGNikdQBS4BukzgwwN0mcG+Ruk6x6\/+eYbs9kc0L8GHgcK0mz09PR0d3dnZGTodLq8vLyrV6+6\/R20efPmDz74QKfTEVFGRgYR3blzR+YMDM\/zFy9eTE9P9+\/ep5mhp6dnaGiooKCAiAwGQ21trcFgkDkD+8lHR0dTwH4XnqxW66uvvkpEAfrJe3Xs2LHi4uItW7Z4fVaGNikdgAlog\/SZQYYG6TOD\/A2S47ja2to1a9aw25mZmV1dXQHd46yhIM1Gf38\/ES1ZsoTd7e7udjgc6sxQVVWVn5+fmJioSIa2trbIyEitVhuIvU8zA3uKbdbW1paYmJiQEPBxRDqdrrq6+t133w30jlxlZWVdvHgxNTVVzp3ONEBAG6TPDDI0SJ8ZFGmQcwUK0iwlJiayZh0dHR0VJXUVVH19fYDanM8MVqt1eHj42Wef9fuup59Br9efPHkyoF320hk4jjMajXV1dWlpaV1dXeJRQkAlJCTI\/y3D\/gSejgC1SZ8BZGiQPjPI0CClMyjSIEVWq7WhoSErK0u2Pc4IClJgmUymhoaGoqIiOdscIwjCqVOntm7dGui\/B6UZjcasrKyOjg6j0VhcXCznmAKG9Z7l5eV1dHRkZWXl5+fLcw5JtZRqk2iQjIINkp1Mys3Nnf7fLjJDQZolsWuov79\/YMD7akwmk6mioqKioiIQ\/dQ+M7S3t0dERARo19PMQES5ubnshEF6enpGRkZbW5vMGdra2jIyMsQMiYmJjY2Nfs8wVwS6TUqQp0H6JEODlKZUg+R5fteuXZmZmXv37pVhd7MzhydXVZBb15DYZeTKZDKdOXPm9OnTHMcpkuHKlStGo9FoNLK7DQ0NXV1d\/m2LPjMkJSVdvXrV7RE\/BphOBhAFuk1Kk6FB+iRDg1QnVo3eeOONzZs3K51FCo6QZiMhISEyMrKxsVEQhLq6unXr1rn1frS2tlZUVBw+fDhw\/\/N9Zti7d29HR0dHR4fZbM7NzT106JDf\/\/P7zLBy5cru7u729nYiam9v7+7uXrlypcwZ2F\/BYgb296l\/M8wJMrRJaTI0SJ9kaJA+yd8gxcHuKq9GhII0OzqdrqioqKKiIjMzk4heeeUV9rjJZGIXnV25csVms7322mtpD\/n99KnPDDLwmYHjuPLy8rKysrS0tOLi4kB8G\/rMYDAYjhw5UlhYyDIo0lulIDnbpHQABcnZIH1mkL9B9vT0tLW1GY1G8VcvfeWygjCXHQAAqAKOkAAAQBVQkAAAQBVQkAAAQBVQkAAAQBVQkAAAQBVQkAAAQBVQkABmgy12J05EZnrI8woPtiKc20U\/MixSBzDnoCABzJjVajWbzfX19bW1tRzHCYJgsVjm5wQQAH6EggQwY26LMPX09BARVrUBeEwoSAAzYzKZCgsL29vbN2zYwPrc+vv7IyIi3ObQM5lMaWlpPmfNYR16aS5ycnLkXxMBQA0w2zfAzGzevDkpKamsrKy8vJzNhHblyhW3Fc\/YKg\/19fUGg0F6tRu2vDS7LQjCgQMH9Hr9vJptD0CEggTwWHiet9lsrpNGnzlzpqamxm3SzMLCQs\/Xrlu3zvXuyZMniWjnzp0BCwugaihIAI\/lzp07kZGR4iJMDQ0NDQ0N6enp4hkmxmg0ui7TyQ6GXDcwmUxms7m8vFz+xYUBVALnkAAeS1tbW2pqqlhF9Hp9bW1tYmJiVVXV9N9E8cWKANQABQlg9jwHfGdkZKSkpOTl5RmNxmkuOGS1WouLi48cOYJTRzDPoSABzJ7D4RgaGnLrnSOiNWvWFBYWlpWVSY9oICKe50tKSnJzc1079ADmJxQkgNn74Ycf9Hq91362goICIjp69Kj00pyNjY3t7e2uq3nKtpYrgNpgxVgAAFAFHCEBAIAqoCABAIAq\/B\/9mOxpfnanBwAAAABJRU5ErkJggg==","height":169,"width":280}}
%---
%[output:329653b6]
%   data: {"dataType":"text","outputData":{"text":"thank you for running this skript\n","truncated":false}}
%---
