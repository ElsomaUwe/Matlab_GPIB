% Laden Sie die erforderliche Instrument Control Toolbox, falls noch nicht installiert
% instrreset; % Uncomment this line to reset the instrument connections

% Konfigurieren Sie die Verbindungseinstellungen
adapterIndex = 0; % Index des GPIB-USB-Adapters
deviceAddress = 8; % GPIB-Adresse des Keithley 2700 Multimeters

% Öffnen Sie die Verbindung zum Gerät
device = gpib('ni', adapterIndex, deviceAddress);
fopen(device);
fprintf(device, ':FORM:ELEM READ'); % Nur den Messwert zurückgeben


% Konfigurieren Sie das Gerät für die Spannungsmessung
fprintf(device, ':SENS:FUNC "VOLT:DC"'); % Messfunktion auf DC-Spannung setzen

% Messung durchführen und das Ergebnis anzeigen
fprintf(device, ':MEAS?');
response = fscanf(device);
values = strsplit(response,',');
[value, unit] = sscanf(values{1}, '%f%s');

fvalue = str2double(value);

fprintf('Gemessene Spannung: %f V\n', fvalue);
% Schließen Sie die Verbindung zum Gerät
fclose(device);
