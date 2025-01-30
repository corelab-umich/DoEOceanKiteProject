clear; clc
close all

% generate a plot showing electric power, 
% generator speed (for each of the kite s 4 generators), and generator efficiency (for each of the
% kite’s 4 generators) vs time for flow speeds of 0.75, 1, and 1.25 m/s using the new generator
% design.

sim1Data = load('PathFollow_V-1.25_Alt-200_thr-400.mat');
sim2Data = load('PathFollow_V-1.00_Alt-200_thr-400.mat');
sim3Data = load('PathFollow_V-0.75_Alt-200_thr-400.mat');

figure(1) % plot showing electric power
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

figure(2)
sim1Data.tsc.rotorSpeed.plot
title('Rotor Speeds for 1.25m/s flow speed')
savefig('rotor_speed_1_25')

figure(3)
sim2Data.tsc.rotorSpeed.plot
title('Rotor Speeds for 1.00m/s flow speed')
savefig('rotor_speed_1_00')

figure(4)
sim3Data.tsc.rotorSpeed.plot
title('Rotor Speeds for 0.75m/s flow speed')
savefig('rotor_speed_0_75')

figure(5)
sim1Data.tsc.genEff.plot
title('Generator Efficiency for 1.25m/s flow speed')
savefig('genEff_1_25')

figure(6)
sim2Data.tsc.genEff.plot
title('Generator Efficiency for 1.00m/s flow speed')
savefig('genEff_1_00')

figure(7)
sim3Data.tsc.genEff.plot
title('Generator Efficiency for 0.75m/s flow speed')
savefig('genEff_0_75')
