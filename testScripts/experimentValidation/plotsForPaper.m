
% superimpose plots from simulation and experiment
% datFileName = 'data_24_Jan_2020_15_50_38.mat';
% fullFileName = strcat(cd,'\Jan24DataFiles\',datFileName);

% tscExp = processExpData(fullFileName,...
%     'Ro_c_in_meters',[22;0;-3.9]./100,...
%     'yawOffset',1*2.5);

% define time to observe
timeExp = tscExp.roll_rad.Time;
tStart = 100; %change to 0 if needed.
tEnd = numel(timeExp);
% tEnd = 15001;
tPlot = tStart:tEnd;

locs = getFigLocations(1.5*560,1.25*420);

% resample simulation results
resampleDataRate = 0.01;
signals = fieldnames(tscSim);
timeAnim = 0:resampleDataRate:tscSim.(signals{1}).Time(end);
timeSim2 = timeAnim;

tscSim2.positionVec = resample(tscSim.positionVec,timeAnim);
tscSim2.velocityVec = resample(tscSim.velocityVec,timeAnim);
tscSim2.eulerAngles = resample(tscSim.eulerAngles,timeAnim);
tscSim2.angularVel = resample(tscSim.angularVel,timeAnim);
tscSim2.rollSetpoint = resample(tscSim.rollSetpoint,timeAnim);
tscSim2.pitchSetpoint = resample(tscSim.pitchSetpoint,timeAnim);
tscSim2.thrReleaseSpeeds = resample(tscSim.thrReleaseSpeeds,timeAnim);

sol_Rcm_o = repmat([0;0;0],1,numel(timeSim2))...
    + squeeze(tscSim2.positionVec.Data);
sol_Vcmo = squeeze(tscSim2.velocityVec.Data);
sol_euler = squeeze(tscSim2.eulerAngles.Data);
sol_OwB = squeeze(tscSim2.angularVel.Data);

%%
[objF2,rmseVals,othrVals] = calObjF(tscSim2,tscExp,dataRange);

% % % % shift the time axis
timeSim2 = timeSim2 - 80;
timeExp = timeExp - 80;
lwd = 2.5;


% % % euler angles %%%%%%%%%%%%%%%%%%%%%%%%%
if exist('fn','var') == 0
    fn = 0;
end
fn = fn+1;
figure(fn)
set(gcf,'Position',locs(fn,:))
% % % % simulation
vectorPlotter(timeSim2,sol_euler([1,3],:)*180/pi,...
    'colors','red',...
    'lineSpec',':',...
    'linewidth',lwd,...
    'legends',{'$\phi_{sim}$','$\psi_{sim}$'},...
    'ylabels',{'Roll','Yaw'},...
    'yUnits','(deg)',...
    'figureTitle','Euler angles');
% % % % experiment
vectorPlotter(timeExp(tPlot),(180/pi)*[tscExp.roll_rad.Data(tPlot)';...
    tscExp.yaw_rad.Data(tPlot)'],...
    'colors','blue',...
    'lineSpec','--',...
    'linewidth',lwd,...
    'legends',{'$\phi_{exp}$','$\psi_{exp}$'},...
    'ylabels',{'Roll','Yaw'},...
    'yUnits','(deg)',...
    'figureTitle','Euler angles');
% % % % setpoints
subplot(2,1,1)
hold on
plot(timeSim2,squeeze(tscSim2.rollSetpoint.Data),'k-','linewidth',0.5,...
    'DisplayName','$\phi_{sp}$');

% subplot(3,1,1)
% plot(timeExp(tPlot),(180/pi)*tscExp.RollSetpoint.Data(tPlot),'k--','linewidth',0.75)
% legend('$\phi$','SP')


% % % % CM positions  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fn = fn+1;
figure(fn);
set(gcf,'Position',locs(fn,:))
% % % % simulation
vectorPlotter(timeSim2,sol_Rcm_o(2:3,:).*100,...
    'colors','red',...
    'lineSpec',':',...
    'linewidth',lwd,...
    'legends',{'$y_{cm,sim}$','$z_{cm,sim}$'},...
    'ylabels',{'y-pos','z-pos'},...
    'yUnits','(cm)',...
    'figureTitle','CM position');
% % % % experiment
vectorPlotter(timeExp(tPlot),squeeze(tscExp.CoMPosVec_cm.Data(2:3,tPlot)).*100,...
    'colors','blue',...
    'lineSpec','--',...
    'linewidth',lwd,...
    'legends',{'$y_{cm,exp}$','$z_{cm,exp}$'},...
    'ylabels',{'y-pos','z-pos'},...
    'yUnits','(cm)',...
    'figureTitle','CM position');

subplot(2,1,2)
ylim([32 38])
subplot(2,1,1)
ylim(7.5*[-1 1])
% yticks(-5:2.5:5)
title('CM position');

% % % cm velocity
fn = fn+1;
figure(fn)
set(gcf,'Position',locs(fn,:))
vectorPlotter(timeSim2,sol_Vcmo(2:3,:),...
    'colors','red',...
    'lineSpec',':',...
    'linewidth',lwd,...
    'legends',{'$\dot{y}_{cm,sim}$','$\dot{z}_{cm,sim}$'},...
    'ylabels',{'y-vel','z-vel'},...
    'yUnits','(m/s)',...
    'figureTitle','CM velocity');

vectorPlotter(timeExp(tPlot(1:end-2)),tscExp.CoMVelVec_cm.Data(2:3,tPlot(1:end-2)),...
    'colors','blue',...
    'lineSpec','--',...
    'linewidth',lwd,...
    'legends',{'$\dot{y}_{cm,exp}$','$\dot{z}_{cm,exp}$'},...
    'ylabels',{'y-vel','z-vel'},...
    'yUnits','(m/s)',...
    'figureTitle','CM velocity');
subplot(2,1,1)
title('CM velocity')

% % % %
set(findobj('Type','axes'),'XLim',[0 timeSim2(end)]);
set(findobj('Type','axes'),'XLim',[0 60]);

set(findobj('Type','legend'),'Visible','on');
set(findobj('-property','FontSize'),'FontSize',18)

yLabLocs = findall(figure(fn-1),'Type','text');
yLabLocs(2).Position(1) = yLabLocs(5).Position(1);

