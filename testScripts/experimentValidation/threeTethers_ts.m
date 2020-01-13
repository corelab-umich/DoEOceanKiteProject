clear
clc
format compact
close all

cd(fileparts(mfilename('fullpath')));

lengthScaleFactor = 1;
densityScaleFactor = 1/1;

simTime = 60;
sim = SIM.sim;
sim.setDuration(simTime*sqrt(lengthScaleFactor),'s');

%% Set up simulation
GNDSTNCONTROLLER      = 'oneDoF';

%% common parameters
numTurbines = 2;

load('constXYZT.mat')
% Set Values
vfdValue = 20;
flowSpeed = vfdInputToFlowSpeed(vfdValue);
env.water.flowVec.setValue([flowSpeed 0 0]','m/s');

%% lifiting body
load('ayazThreeTetVhcl.mat')

altiSP = 34.5e-2;
iniX = 0.0477;
pitchSP = 11;

% % % initial conditions
vhcl.setInitPosVecGnd([iniX;0;altiSP],'m');
vhcl.setInitVelVecBdy([0;0;0],'m/s');
vhcl.setInitEulAng([0;pitchSP;0]*pi/180,'rad');
vhcl.setInitAngVelVec([0;0;0],'rad/s');

% % % plot
% vhcl.plot
% vhcl.plotCoeffPolars

% High Level controller
loadComponent('constBoothLem.mat')


%% Ground Station
load('ayazThreeTetGndStn.mat')

gndStn.initAngPos.setValue(0,'rad');
gndStn.initAngVel.setValue(0,'rad/s');

%% Tethers
load('ayazThreeTetTethers.mat')

% set initial conditions
for ii = 1:3
    
    thr.(strcat('tether',num2str(ii))).initGndNodePos.setValue...
        (gndStn.posVec.Value + ...
        gndStn.(strcat('thrAttch',num2str(ii))).posVec.Value(:),'m');
    thr.(strcat('tether',num2str(ii))).initAirNodePos.setValue...
        (vhcl.initPosVecGnd.Value(:)+rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts(ii).posVec.Value,'m');
    thr.(strcat('tether',num2str(ii))).initGndNodeVel.setValue([0 0 0]','m/s');
    thr.(strcat('tether',num2str(ii))).initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
    thr.(strcat('tether',num2str(ii))).vehicleMass.setValue(vhcl.mass.Value,'kg');
    
end
% thr.designTetherDiameter(vhcl,env);

%% winches
load('ayazThreeTetWnch.mat');
% set initial conditions
% wnch.setTetherInitLength(vhcl,env,thr);
% wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);
wnch.winch1.initLength.setValue(0.3530,'m');
wnch.winch2.initLength.setValue(0.3499,'m');
wnch.winch3.initLength.setValue(0.3530,'m');


dynamicCalc = '';

%% Set up controller
load('ayazThreeTetCtrl.mat');

altitudeCtrlShutOffDelay = 0*800;
% expOffset = 7.7+2.5;
expOffset = 0;
expDelay = 20.61;
initialDelay = altitudeCtrlShutOffDelay + expDelay;
expOffset = altitudeCtrlShutOffDelay + expOffset;

% switching values
fltCtrl.ySwitch.setValue(0,'m'); % set to 0 to execute simple square wave tracking
fltCtrl.rollAmp.setValue(12,'deg');
fltCtrl.rollPeriod.setValue(5,'s');

% set setpoints
timeVec = 0:0.005*sqrt(lengthScaleFactor):simTime;
fltCtrl.altiSP.setValue(altiSP*ones(size(timeVec)),'m',timeVec);
fltCtrl.pitchSP.setValue(pitchSP*ones(size(timeVec)),'deg',timeVec);
fltCtrl.yawSP.setValue(0*ones(size(timeVec)),'deg',timeVec);

%% scale 
% scale environment
% env.scale(lengthScaleFactor,densityScaleFactor);
% scale vehicle
% vhcl.scale(lengthScaleFactor,densityScaleFactor);
% scale ground station
% gndStn.scale(lengthScaleFactor,densityScaleFactor);
% scale tethers
% thr.scale(lengthScaleFactor,densityScaleFactor);
% scale winches
% wnch.scale(lengthScaleFactor,densityScaleFactor);
% scale controller
% fltCtrl.scale(lengthScaleFactor,densityScaleFactor);

%% process experimental data
% load file
load 'data_19_Nov_2019_19_08_19.mat' 

% extract values
tscExp = tsc;
timeExp = tscExp.roll_rad.Time;

% filter bad data
badData = find(tscExp.yaw_rad.Data>100);
tscExp.yaw_rad.Data(badData) = 0.5*(tscExp.yaw_rad.Data(badData-1) + tscExp.yaw_rad.Data(badData+1));
windowSize = 20; 
b = (1/windowSize)*ones(1,windowSize);
tscExp.roll_rad.Data = filter(b,1,tscExp.roll_rad.Data);
tscExp.pitch_rad.Data = filter(b,1,tscExp.pitch_rad.Data);
tscExp.yaw_rad.Data = filter(b,1,tscExp.yaw_rad.Data);

tscExp.CoMPosVec_cm.Data = tscExp.CoMPosVec_cm.Data./100;

%% adjust parameters
initVals.CLWing = vhcl.portWing.CL.Value;
initVals.CDWing = vhcl.portWing.CD.Value;

initVals.CLhStab = vhcl.hStab.CL.Value;
initVals.CDhStab = vhcl.hStab.CD.Value;

initVals.CLvStab = vhcl.vStab.CL.Value;
initVals.CDvStab = vhcl.vStab.CD.Value;

initVals.fuseEndDrag = vhcl.fuseEndDragCoeff.Value;
initVals.fuseSideDrag = vhcl.fuseSideDragCoeff.Value;

initVals.addedMass = vhcl.addedMass.Value;
initVals.buoyFactor = vhcl.buoyFactor.Value;

initVals.wnchMaxReleaseSpeed = wnch.winch1.maxSpeed.Value;

initVals.thrDragCoeff = thr.tether1.dragCoeff.Value;


%% run optimization
% initCoeffs = ones(9,1);
% initCoeffs = [0.8836    1.1571    0.6642    1.4724    0.2740    1.4610    0.9725...
%     0.5495    0.9937 1 1 1]';

initCoeffs = ones(9,1);

% lowLims = [repmat([0.25;1],3,1); 0.9; 0.5; 0.7; 0.9; 0.9; 0.9];
% hiLims = [repmat([1;1.75],3,1); 1.1; 1.5; 1.3; 1.1; 1.1; 1.1];

lowLims = [repmat([0.01;1],3,1); 0.1; 0.1; 0.5];
hiLims = [repmat([1;5],3,1); 5; 5; 1.1];
    
dataRange = [30 60];

options = optimoptions(@fmincon,'MaxIterations',40,'MaxFunctionEvaluations',2000);

% [optDsgn,maxF] = fmincon(@(coeffs) simOptFunction(vhcl,thr,wnch,fltCtrl,...
%     initVals,coeffs,tscExp,dataRange),...
%     initCoeffs,[],[],[],[],lowLims,hiLims,[],options);

[optDsgn,minF] = particleSwarmMinimization(...
    @(coeffs) simOptFunction(vhcl,thr,wnch,fltCtrl,...
    initVals,coeffs,tscExp,dataRange),initCoeffs,lowLims,hiLims,...
    'swarmSize',20,'maxIter',15);


%%
% optDsgn = [1.0000 1.0000 1.0000 1.3868 0.2500 1.7500 0.9000 0.5000 1.3000 0.9877 1.0210 1.1000 ]';
objF = simOptFunction(vhcl,thr,wnch,fltCtrl,...
    initVals,optDsgn,tscExp,dataRange);


%% Run the simulation
% simWithMonitor('OCTModel')
% parseLogsout

plotAyaz
compPlots

% fullKitePlot


% % % % % % % tscSim.tetherLengths.Data(:,end)
% % % % % % % sol_Rcm_o(:,end)
% % % % % % % sol_euler(:,end)*180/pi

