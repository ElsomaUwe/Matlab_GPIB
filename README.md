# Matlab-Gpib
Sammlung diverser Dateien für die Ansteuerung von Labor-Geräten
mit der NI GPIB-USB HS2 Schnittstelle (und auch USB/virtual Comport).

Achtung! gpib class lin iwrd in Matlab irgendwann nicht mehr unterstützt.
Deswegen schrittweise portierung auf visa lib.

Bisher getestet:
GPIB /IEE488:
----------------
1) HP4192A Impedanz-Analyzer 5Hz - 13MHz
2) Keithley 2700 Multimeter
3) H&H IL800 elektronische Last bis 800W
4) Philips PM2534 Multimeter
5) Advantest R6144 programmierbare Spannungs- und Stromquelle
6) HP66309D Netzgerät 15V/3A 12V/1.5A

Ansteuerung über COM / virtual Comport:
----------------------------------------
1) KA3000P Netzteil (Reichelt)
2) T962 Reflow-Ofen mit SW Update

Noch offen:
----------------------------------------
1) Philips PM6624 Frequenzzähler - benötigt Adapter auf D-SUB25
2) Elsometer C10 Flussdichtemessgerät - benötigt noch SCPI-Erweiterung in der Firmware
3) Fluke 5100B Calibrator

   
Desweiteren denkbar:
-----------------------------
Einbindung des GPIB-USB-Adapters von Patrik Schäfer und Uwe Rother


