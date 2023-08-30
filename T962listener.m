% COM-Port-Einstellungen
comPort = 'COM19'; % COM-Port-Nummer oder Name
baudRate = 115200; % Baudrate
try delete(sp);
end
close all;

time = [0];
tempL = [0];
tempR = [0];
tempSoll = [0];
tempIst = [0];
Heat = [0];
Fan  = [0];
Regler = [0];

% Serial Port öffnen
sp = serialport(comPort, baudRate);

f1 = figure;
hold on;
grid on;

yyaxis left;
hold on;
title('T962 Temperatur');
xlabel('t / s');
ylabel('Temperatur / °C');
xlim([0 470]);
ylim([0 300]);

pL = plot(time,tempIst);
pL.XDataSource = 'time';
pL.YDataSource = 'tempIst';
pSoll = plot(time,tempSoll);
pSoll.XDataSource = 'time';
pSoll.YDataSource = 'tempSoll';

yyaxis right;
hold on;
pHeat = plot(time,Heat);
pFan = plot(time,Fan);
ylim([0 600]);

set(pHeat,'Color', 'r'); % Blaue Linie mit Kreisen
pHeat.XDataSource = 'time';
pHeat.YDataSource = 'Heat';
set(pFan,'Color', 'm'); % Blaue Linie mit Kreisen
pFan.XDataSource = 'time';
pFan.YDataSource = 'Fan';

% Empfangsschleife
i=1;

while true
    % Daten empfangen
    try
        data = readline(sp);
    catch exception
        fprintf('Es kommen keine Daten mehr %s\n', exception.message);
    end
    
    % Überprüfen auf leere Zeile (Ende der Übertragung)
    if isempty(data)
        break;
    end
        values = strrep(strsplit(data,','),' ','');
        if size(values,2) == 11
        time(i) = str2double(values(1));
        tempL(i) = str2double(values(2));
        tempR(i) = str2double(values(3));
        tempSoll(i) = str2double(values(6));
        tempIst(i) = str2double(values(7));
        Heat(i) = str2double(values(8));
        Fan(i)  = str2double(values(9));
        % cold(i) = str2double(10);
        Regler(i) = str2double(values(10));
        i=i+1;
        % Daten anzeigen
        disp(data);
        refreshdata(f1);
        end
end

% Serial Port schließen
delete(sp);
T962_plot_pure;
