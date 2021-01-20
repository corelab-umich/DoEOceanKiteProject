clear
close all

%% KFGP parameters
kfgptimeStep  = 10;
timeScale     = 22*60;
altScale      = 220;
covAmp        = 5.1;
xMeasure      = 100:100:1000;
noiseVar      = 0.01;
tempKern      = 'squaredexponential';
powLawParams  = [3.77 0.14];

a = kfgp_init(xMeasure,covAmp,...
    altScale,noiseVar,tempKern,kfgptimeStep,timeScale);

%% MPC parameters
mpctimeStep = 2*60;
nPred       = 6;
maxAlt      = 1000;
minAlt      = 100;
zStepMax    = 1000;
tradeOffCon = 20;

%% balloon parameters
rhoEnv  = 1.225;
rhoBall = 1.2;
rBall   = 10;
cdBall  = 0.5;
kThr    = 5e6;
iniAlt  = 600;
altKp   = 1;
altKi   = 0.1;
altTau  = 1;

%% synthetic flow
finalTime      = 9*60*60;
sampleTimeStep = 1*60;
stdDev         = 1;
minFlowValue   = 5;
rngSeed        = 8;

%% simulate
simTime = 3*60*60;
tsc = sim('altOptMPC_th');

%% plot
% extract values from time series container
plotTimeStep = sampleTimeStep/10;
for ii = 1:numel(tsc.logsout.getElementNames)
    outVal.(tsc.logsout.getElementNames{ii}) =  resample(...
        tsc.logsout.getElement(tsc.logsout.getElementNames{ii}).Values,...
        0:plotTimeStep:tsc.tout(end));
end
% animated plot
for ii = 1:numel(outVal.synFlowSpeeds.Time)
    if ii == 1
        % plot flow
        hFlow = plot(outVal.synFlowSpeeds.Data(:,1,ii),...
            outVal.synFlowAlts.Data(:,1,1));
        grid on;
        hold on;
        xlabel('Flow speed [m/s]');
        ylabel('Altitude [m]');
        xlim([min(outVal.synFlowSpeeds.Data(:)) ...
            max(outVal.synFlowSpeeds.Data(:))]);
        ylim([min(outVal.synFlowAlts.Data(:)) ...
            max([outVal.synFlowAlts.Data(:);outVal.desAltitude.Data(:)])])
        
        % plot setpoint altitude
        hSP = yline(outVal.desAltitude.Data(ii),'r--','linewidth',1);
        % plot altitude
        hAlt = yline(outVal.ballPosition.Data(ii,2),'k:','linewidth',1);
        legend([hSP,hAlt],{'$z_{des}$','$z$'});
    end
    % update plots
    hFlow.XData = outVal.synFlowSpeeds.Data(:,1,ii);
    hSP.Value   = outVal.desAltitude.Data(ii);
    hAlt.Value   = outVal.ballPosition.Data(ii,2);
    
    title(sprintf('Time = %0.1f min',outVal.synFlowSpeeds.Time(ii)/60));
    waitforbuttonpress;
end


