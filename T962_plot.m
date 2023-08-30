figure;
hold on;
grid on;
yyaxis left;

% Regl0 = Regler - 248;
plot(time,tempL,'b-','DisplayName','Temp Left');
plot(time,tempR,'c-','DisplayName','Temp Right');
plot(time,tempIst,'m-','DisplayName','Temp Ist');

plot(time,tempSoll,'k-','DisplayName','Temp Soll');

yyaxis right;
plot(time,Heat,'r-','DisplayName','HeatPwr');
plot(time,Regler,'b-','DisplayName','Regler');
plot(time,Fan,'y-','DisplayName','Fan');


legend

% Dateiformat auswählen und Plot speichern
fileFormat = 'png';  % Du kannst hier auch andere Formate wie 'jpeg', 'pdf', etc. wählen
fileName = 'T962_Elsoma_V3_1';  % Der Name der Ausgabedatei (ohne Dateierweiterung)
saveas(gcf, fileName, fileFormat);
