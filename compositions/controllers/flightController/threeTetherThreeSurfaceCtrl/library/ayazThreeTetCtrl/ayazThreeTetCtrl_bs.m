clear
clc
format compact

% this is the build script for creating controller using class definition
% 'controller' for a three tethered system that is being used by ayaz

% the script saves the variable 'fltCtrl' to a 'ayazThreeTetfltCtrl.mat'

%% Set up controller
FLIGHTCONTROLLER      = 'threeTetherThreeSurfaceCtrl';

% Create
fltCtrl = CTR.controller;
% add filtered PID controllers
% FPID controllers are initialized to zero gains, 1s time const
fltCtrl.add('FPIDNames',{'tetherAlti','tetherPitch','tetherRoll','elevators','ailerons','rudder'},...
    'FPIDErrorUnits',{'m','rad','rad','deg','deg','deg'},...
    'FPIDOutputUnits',{'m/s','m/s','m/s','deg','deg','deg'});

% add control allocation matrix (implemented as a simple gain)
fltCtrl.add('GainNames',{'fltCtrlSurfAllocationMat','thrAllocationMat','ySwitch','rollAmp'},...
    'GainUnits',{'','','m','deg'});

% add output saturation
fltCtrl.add('SaturationNames',{'outputSat'});

% add setpoints
fltCtrl.add('SetpointNames',{'altiSP','pitchSP','yawSP'},...
    'SetpointUnits',{'m','deg','deg'});

% tether controllers
fltCtrl.tetherAlti.kp.setValue(0,'(m/s)/(m)');
fltCtrl.tetherAlti.ki.setValue(0,'(m/s)/(m*s)');
fltCtrl.tetherAlti.kd.setValue(0,'(m/s)/(m/s)');
fltCtrl.tetherAlti.tau.setValue(5,'s');

fltCtrl.tetherPitch.kp.setValue(2*0.1,'(m/s)/(rad)');
fltCtrl.tetherPitch.ki.setValue(0,'(m/s)/(rad*s)');
fltCtrl.tetherPitch.kd.setValue(4*0.1,'(m/s)/(rad/s)');
fltCtrl.tetherPitch.tau.setValue(0.1,'s');

fltCtrl.tetherRoll.kp.setValue(4*1,'(m/s)/(rad)');
fltCtrl.tetherRoll.ki.setValue(0,'(m/s)/(rad*s)');
fltCtrl.tetherRoll.kd.setValue(12*1,'(m/s)/(rad/s)');
fltCtrl.tetherRoll.tau.setValue(0.01,'s');

fltCtrl.thrAllocationMat.setValue([1 .5 -.5; 1 -.5 0; 1 .5 .5],'');

% Set the values of the controller parameters
fltCtrl.ailerons.kp.setValue(0,'(deg)/(deg)');
fltCtrl.ailerons.ki.setValue(0,'(deg)/(deg*s)');
fltCtrl.ailerons.kd.setValue(0,'(deg)/(deg/s)');
fltCtrl.ailerons.tau.setValue(0.5,'s');

fltCtrl.elevators.kp.setValue(0,'(deg)/(deg)'); % do we really want to represent unitless values like this?
fltCtrl.elevators.ki.setValue(0,'(deg)/(deg*s)');
fltCtrl.elevators.kd.setValue(0,'(deg)/(deg/s)'); % Likewise, do we want (deg*s)/(deg) or just s?
fltCtrl.elevators.tau.setValue(0.01,'s');

fltCtrl.rudder.kp.setValue(0,'(deg)/(deg)');
fltCtrl.rudder.ki.setValue(0,'(deg)/(deg*s)');
fltCtrl.rudder.kd.setValue(0,'(deg)/(deg/s)');
fltCtrl.rudder.tau.setValue(0.5,'s');

fltCtrl.fltCtrlSurfAllocationMat.setValue([-1 0 0; 1 0 0; 0 -1 0; 0 0 1],'');

fltCtrl.outputSat.upperLimit.setValue(0,'');
fltCtrl.outputSat.lowerLimit.setValue(0,'');


%% save file in its respective directory
saveBuildFile('fltCtrl',mfilename,'variant','FLIGHTCONTROLLER');



