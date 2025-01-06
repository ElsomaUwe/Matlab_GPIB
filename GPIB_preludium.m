% GPIB-Adresse des Messgeräts (je nach Konfiguration ändern)
gpibAddrHP4192A         = 1;        %Impedanz-Analyzer
gpibAddrHP66309D        = 6;
gpibAddrKeithley2700    = 8;   %Multimeter
gpibAddrIL800           = 16;
gpibAddrR6144           = 17;         %Programmable Voltage/Current source

KAComPort = 'COM3';            %Netzteil
IL800ComPort = 'COM5';

% init GPIB Controller
myGpib = gpibClass;

% reset interface
myGpib.init();

% connect with some instruments
hHP4192A = myGpib.connect(gpibAddrHP4192A);
hIL800 = myGpib.connect(gpibAddrIL800);
hKeithley2700 = myGpib.connect(gpibAddrKeithley2700);
hR6144 = myGpib.connect(gpibAddrR6144);
hHP66309D = myGpib.connect(gpibAddrHP66309D);

