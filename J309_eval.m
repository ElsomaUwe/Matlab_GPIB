for j = 1:numCurves
    label(j) = sprintf("UGS=%4.2fV",UGS(j));
    
end

figure;
hold on;
grid on;
for j = 1:numCurves
    plot(UDS,ID(j,:)*1000,'DisplayName',label(j))
end
title('J309 Kennlinie');
xlabel('U_D_S/V');
ylabel('I_D/mA');

legend('Location','SOUTHEAST');