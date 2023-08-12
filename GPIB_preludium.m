% GPIB-Adresse des Messgeräts (je nach Konfiguration ändern)
gpibAddrHP4192A = 1;        %Impedanz-Analyzer
gpibAddrHP66309D = 6;
gpibAddrKeithley2700 = 8;   %Multimeter
gpibAddrIL800 = 16;         %elektronische Last
KAPort = 'COM3';            %Netzteil

%instrreset();

% init GPIB Controller
myGpib = gpibClass;

% reset interface
myGpib.init();

