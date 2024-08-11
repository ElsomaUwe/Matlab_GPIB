x0 = -4.0;

fun = @(x, u) IDSS * (1 - (u.^2 ./ x^2));  

Upinchoff = lsqcurvefit(fun, x0, UGS, ID);


In = 0:-0.005:-6;
Out = fun(Upinchoff,In);

figure;
plot(In,Out);