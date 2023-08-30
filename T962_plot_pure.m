figure;
hold on;
grid on;

x = max(time);
yyaxis left;
xlim([0 x]);
ylim([0 300]);
% plot(time,tempL,'b-','DisplayName','Temp Left');
% plot(time,tempR,'c-','DisplayName','Temp Right');
plot(time,tempSoll,'k-','DisplayName','Temp Soll');
plot(time,tempIst,'m-','DisplayName','Temp Ist');

yyaxis right;
hold on;
ylim([0 600]);

plot(time,Heat,'r-','DisplayName','HeatPwr');
% plot(time,Regler,'b-','DisplayName','Regler');
plot(time,Fan,'b-','DisplayName','Fan');


legend

% Dateiformat auswählen und Plot speichern
fileFormat = 'png';  % Du kannst hier auch andere Formate wie 'jpeg', 'pdf', etc. wählen
fileName = 'T962_Elsoma_V3_5';  % Der Name der Ausgabedatei (ohne Dateierweiterung)
saveas(gcf, fileName, fileFormat);
