clear;
close all;
clc;

load("DP25data20.mat");
load("DP25data50.mat");
load("DP25data200.mat");

Uin = DP25data20(1,:);
Uout20 = DP25data20(2,:);
coeff20 = polyfit(Uout20,Uin,1);
Uout50 = DP25data50(2,:);
coeff50 = polyfit(Uout50,Uin,1);
Uout200 = DP25data200(2,:);
coeff200 = polyfit(Uout200,Uin,1);