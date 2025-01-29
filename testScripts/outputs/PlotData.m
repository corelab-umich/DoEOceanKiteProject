clear; clc
close all

sim1Data = load('PathFollow_V-1.25_Alt-200_thr-400.mat');
sim2Data = load('PathFollow_V-1.00_Alt-200_thr-400.mat');
sim3Data = load('PathFollow_V-0.75_Alt-200_thr-400.mat');

figure(1)
hold on
sim1Data.tsc.turbPow.plot
sim2Data.tsc.turbPow.plot
sim3Data.tsc.turbPow.plot

xlabel('Time (s)')
ylabel('Power (W)')
title('Mechanical Power')
legend('1.25m/s flow speed', '1.00m/s flow speed', '0.75m/s flow speed')
savefig('mechanical_power')
hold off

figure(2)
hold on
sim1Data.tsc.elecPow.plot
sim2Data.tsc.elecPow.plot
sim3Data.tsc.elecPow.plot

xlabel('Time (s)')
ylabel('Power (W)')
title('Electrical Power')
legend('1.25m/s flow speed', '1.00m/s flow speed', '0.75m/s flow speed')
savefig('electrical_power')
hold off

figure(3)
hold on
sim1Data.tsc.vhclAngleOfAttack.plot
sim2Data.tsc.vhclAngleOfAttack.plot
sim3Data.tsc.vhclAngleOfAttack.plot

xlabel('Time (s)')
ylabel('Angle of Attack (deg)')
title('Vehicle Angle of Attack')
legend('1.25m/s flow speed', '1.00m/s flow speed', '0.75m/s flow speed')
savefig('angle_of_attack')
hold off

sa