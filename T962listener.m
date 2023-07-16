% COM-Port-Einstellungen
comPort = 'COM12'; % COM-Port-Nummer oder Name
baudRate = 115200; % Baudrate
try delete(sp);
end
% Serial Port öffnen
sp = serialport(comPort, baudRate);

% Empfangsschleife
i=1;

while true
    % Daten empfangen
    data = readline(sp);
    
    % Überprüfen auf leere Zeile (Ende der Übertragung)
    if isempty(data)
        break;
    end
        values = strrep(strsplit(data,','),' ','');
        if size(values,2) == 11
        time(i) = str2double(values(1));
        tempL(i) = str2double(values(2));
        tempR(i) = str2double(values(3));
        cold(i) = str2double(10);
        i=i+1;
        % Daten anzeigen
        disp(data);
        end
    
    
     
end

% Serial Port schließen
delete(sp);
