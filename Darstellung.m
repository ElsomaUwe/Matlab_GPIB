%clear;
%clc;
%close all;
try
    close(f1);
end
load('measurementData');
f = f*1000;


f1 = figure;

C_ = C/1000;  %jetzt in µF
%[ax, h1, h2] = plotyy(f, Z, f, C_);

% Linke Achse (doppelt logarithmisch)
yyaxis left;
h1 = loglog(f,Z);
ylabel('Z / Ohm');
yticks([10e-3, 50e-3, 100e-3, 500e-3, 1,10,100]);
ylim([10e-3 100]);
set(h1,'Color', 'b'); % Blaue Linie mit Kreisen
grid on;

yyaxis right;
h2 = loglog(f,C_);
ylabel('C / uF');
%ylim([0 0.2]);
set(h2, 'Color', 'r'); % Rote Linie mit Sternchen

