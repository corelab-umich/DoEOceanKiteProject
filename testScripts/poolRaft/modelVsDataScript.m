%% Test script for pool test simulation of the kite model
% clear;clc;close all;

clc
close all
clear all
load expCompData.mat
Simulink.sdi.clear
clear tsc1
distFreq = 0;distAmp = 0;pertVec = [0 1 0];
%%  Set Test Parameters
saveSim = 0;               %   Flag to save results
runLin = 0;                %   Flag to run linearization
inc =-5.5;
elevArray = 20*pi/180;%[40 15]*pi/180;
towArray = 0.78;
rCM = 1;
thrLength = 2.63;
flwSpd = -1e-9;

for q = 2
    for i = 1:length(inc)
        i
        for j = 1:3
            j
            for k = 1:numel(rCM)
                tic
                Simulink.sdi.clear
                h = 30*pi/180;  w = 90*pi/180;                             %   rad - Path width/height
                [a,b] = boothParamConversion(w,h);                          %   Path basis parameters
                %%  Load components
                el = elevArray;
                if q ~= 3
                    %             loadComponent('exp_slCtrl');
                    loadComponent('periodicCtrlExp');
                    %             fltCtrl.ctrlOff.setValue(0,'')
                    if j == 3
                        FLIGHTCONTROLLER = 'periodicCtrlExpAllocate';
                    end
                else%
                    loadComponent('pathFollowCtrlExp');                         %   Path-following controller with AoA control
                    FLIGHTCONTROLLER = 'pathFollowingControllerExp';
                end
                loadComponent('oneDoFGSCtrlBasic');                         %   Ground station controller                           %   Ground station
                loadComponent('raftGroundStation');
                loadComponent('oneDOFWnch');                                %   Winches
                loadComponent('poolTether');                               %   Manta Ray tether
                loadComponent('lasPosEst');                             %   Sensors
                loadComponent('lineAngleSensor');
                loadComponent('idealSensorProcessing');                      %   Sensor processing
                loadComponent('poolScaleKiteAbney');                %   AR = 8; 8m span
                SIXDOFDYNAMICS        = "sixDoFDynamicsCoupledFossen12int";
                %%  Environment Properties
                loadComponent('ConstXYZT');                                 %   Environment
                %                 loadComponent('CNAPsTurbJames');
                env.water.setflowVec([flwSpd 0 0],'m/s');                   %   m/s - Flow speed vector
                ENVIRONMENT = 'env2turbLinearize';            %   Two turbines
                %%  Set basis parameters for high level controller
                
                loadComponent('constBoothLem');        %   High level controller
                % PATHGEOMETRY = 'lemOfBoothInv'
                hiLvlCtrl.basisParams.setValue([a,b,-el,180*pi/180,thrLength-.1],'[rad rad rad rad m]') % Lemniscate of Booth
                las.setThrInitAng([-el 0],'rad');
                las.setInitAngVel([-0 0],'rad/s');
                %             las.tetherLoadDisable;
                %             las.dragDisable;
                %%  Ground Station Properties
                %% Set up pool raft parameters
                theta = 30*pi/180;
                T_tether = 100; %N
                phi_max = 30*pi/180;
                omega_kite = 2*pi/5; %rad/s
                m_raft = 50; %kg
                J_raft = 30;
                tow_length = 16;
                tow_speed = towArray;
                end_time = tow_length/tow_speed;
                x_init = 4;
                y_init = 0;
                y_dot_init = 0;
                psi_init = 0;
                psi_dot_init = 0;
                initGndStnPos = [x_init;y_init;0];
                thrAttachInit = initGndStnPos;
                %%  Vehicle Properties
                vhcl.stbdWing.setGainCL(vhcl.stbdWing.gainCL.Value/8,'1/deg');
                vhcl.portWing.setGainCL(vhcl.portWing.gainCL.Value/8,'1/deg');
                vhcl.stbdWing.setGainCD(vhcl.stbdWing.gainCD.Value/8,'1/deg');
                vhcl.portWing.setGainCD(vhcl.portWing.gainCD.Value/8,'1/deg');
                vhcl.vStab.setGainCL(vhcl.vStab.gainCL.Value/2,'1/deg');
                vhcl.vStab.setGainCD(vhcl.vStab.gainCD.Value/2,'1/deg');
                if q == 3
                    vhcl.setICsOnPath(.05,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,initGndStnPos,6.5*abs(flwSpd)*norm([1;0;0]))
                else
                    vhcl.setICsOnPath(0.0,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,initGndStnPos,0);
                    vhcl.setInitEulAng([180 0 180]*pi/180,'rad');
                    %             vhcl.setInitEulAng([180 0 0]*pi/180,'rad');
                    vhcl.setInitVelVecBdy([0 0 0],'m/s');
                end
                
                %%  Tethers Properties
                load([fileparts(which('OCTProject.prj')),'\vehicleDesign\Tether\tetherDataNew.mat']);
                thr.tether1.initGndNodePos.setValue(thrAttachInit,'m');
                thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
                    +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');
                x = thr.tether1.initGndNodePos.Value(1)-thr.tether1.initAirNodePos.Value(1);
                y = thr.tether1.initGndNodePos.Value(2)-thr.tether1.initAirNodePos.Value(2);
                z = thr.tether1.initGndNodePos.Value(3)-thr.tether1.initAirNodePos.Value(3);
                initThrAng = atan2(z,sqrt(x^2+y^2));
                
                las.setThrInitAng([-initThrAng 0],'rad');
                thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
                thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
                thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
                thr.tether1.youngsMod.setValue(50e9,'Pa');
                thr.tether1.density.setValue(1000,'kg/m^3');
                thr.tether1.setDiameter(.0076,'m');
                thr.setNumNodes(4,'');
                thr.tether1.setDragCoeff(1.8,'');
                %%  Winches Properties
                wnch.setTetherInitLength(vhcl,thrAttachInit,env,thr,env.water.flowVec.Value);
%                 wnch.winch1.LaRspeed.setValue(1,'m/s');
                %%  Controller User Def. Parameters and dependant properties
                fltCtrl.setFcnName(PATHGEOMETRY,'');
                fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,hiLvlCtrl.basisParams.Value,thrAttachInit);
                fltCtrl.setPerpErrorVal(.4,'rad')
                fltCtrl.rudderGain.setValue(0,'')
                fltCtrl.rollMoment.kp.setValue(45/3,'(N*m)/(rad)')
                fltCtrl.rollMoment.ki.setValue(0,'(N*m)/(rad*s)');
                fltCtrl.rollMoment.kd.setValue(25/3,'(N*m)/(rad/s)')
                fltCtrl.tanRoll.kp.setValue(.25,'(rad)/(rad)')
                thr.tether1.dragEnable.setValue(1,'')
                vhcl.hStab.setIncidence(0,'deg');
                if q == 3
                    vhcl.hStab.setIncidence(-3,'deg');
                end
                if q ~= 3
                    %                     693
                    if j == 1
                        fltCtrl.rollAmp.setValue(30,'deg')
                        fltCtrl.yawAmp.setValue(0,'deg');
                        fltCtrl.period.setValue(7.5,'s');
                        fltCtrl.rollPhase.setValue(0,'rad');
                    elseif j == 2
                        fltCtrl.rollAmp.setValue(60,'deg');
                        fltCtrl.yawAmp.setValue(80,'deg');
                        fltCtrl.period.setValue(7.5,'s');
                        fltCtrl.rollPhase.setValue(-pi/2,'rad');
                        fltCtrl.yawPhase.setValue(.693+pi/2,'rad');
                    elseif j == 3
                        fltCtrl.rollAmp.setValue(60,'deg');
                        fltCtrl.yawAmp.setValue(80,'deg');
                        fltCtrl.period.setValue(7.5,'s');
                        fltCtrl.rollPhase.setValue(-pi/2,'rad');
                        fltCtrl.yawPhase.setValue(.693+pi/2,'rad');
                    end
                    if q == 1
                        fltCtrl.startCtrl.setValue(42,'s')
                    else
                        fltCtrl.startCtrl.setValue(1,'s')
                        %                         launchTime = 3.5;
                    end
                    if q == 2
                        if j == 3
                            fltCtrl.rollCtrl.kp.setValue(.2143,'(deg)/(deg)');
                            fltCtrl.rollCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.rollCtrl.kd.setValue(.05555,'(deg)/(deg/s)');
                            fltCtrl.rollCtrl.tau.setValue(0.02,'s');
                            
                            fltCtrl.yawCtrl.kp.setValue(.143,'(deg)/(deg)');
                            fltCtrl.yawCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.yawCtrl.kd.setValue(.1,'(deg)/(deg/s)');
                            fltCtrl.yawCtrl.tau.setValue(0.02,'s');
                            
                            fltCtrl.rollCtrl.kp.setValue(.3/.7,'(deg)/(deg)');
                            fltCtrl.rollCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.rollCtrl.kd.setValue(.1/.9,'(deg)/(deg/s)');
                            fltCtrl.rollCtrl.tau.setValue(0.02,'s');
                            
                            fltCtrl.yawCtrl.kp.setValue(.1/.7,'(deg)/(deg)');
                            fltCtrl.yawCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.yawCtrl.kd.setValue(.07/.7 ,'(deg)/(deg/s)');
                            fltCtrl.yawCtrl.tau.setValue(0.02,'s')
                        elseif j == 1
                            fltCtrl.rollCtrl.kp.setValue(3,'(deg)/(deg)');
                            fltCtrl.rollCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.rollCtrl.kd.setValue(1,'(deg)/(deg/s)');
                            fltCtrl.rollCtrl.tau.setValue(0.02,'s');
                            
                            fltCtrl.yawCtrl.kp.setValue(0,'(deg)/(deg)');
                            fltCtrl.yawCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.yawCtrl.kd.setValue(0,'(deg)/(deg/s)');
                            fltCtrl.yawCtrl.tau.setValue(0.02,'s');
                        else
                            fltCtrl.rollCtrl.kp.setValue(3,'(deg)/(deg)');
                            fltCtrl.rollCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.rollCtrl.kd.setValue(1,'(deg)/(deg/s)');
                            fltCtrl.rollCtrl.tau.setValue(0.02,'s');
                            
                            fltCtrl.yawCtrl.kp.setValue(2,'(deg)/(deg)');
                            fltCtrl.yawCtrl.ki.setValue(0,'(deg)/(deg*s)');
                            fltCtrl.yawCtrl.kd.setValue(1.4,'(deg)/(deg/s)');
                            fltCtrl.yawCtrl.tau.setValue(0.02,'s');
                        end
                    end
                    fltCtrl.ccElevator.setValue(-3.5,'deg');
                    fltCtrl.trimElevator.setValue(inc(i),'deg');
                    
                end
                %                  FLIGHTCONTROLLER = 'periodicCtrlExpTran1';
                
                fluidDensity  = 1000;
                endTime = 25;
                towPer = .1*.33;
                towAmp = 0*.0098;%%  Set up critical system parameters and run simulation
                simParams = SIM.simParams;  simParams.setDuration(end_time,'s');  dynamicCalc = '';
                %                     open_system('OCTModel')
                
                set_param('OCTModel','SimulationMode','accelerator');
                simWithMonitor('OCTModel')
                tscSim{j} = signalcontainer(logsout);
                tsc = tscSim{j}
                
            end
            toc
        end
    end
end
vhcl.animateSim(tscSim{1},0.2)

vhcl.animateSim(tscSim{2},0.2)
vhcl.animateSim(tsc,0.2)

tsc = tscSim{1}
%
bMat = tsc.scaledB
figure;
hold on;
legEnt = {'$\delta M/(\delta_{a}v_{app}^2)$',...
    '$\delta M/(\delta_{r}v_{app}^2)$';...
    '$\delta L/(\delta_{a}v_{app}^2)$',...
    '$\delta L/(\delta_{r}v_{app}^2)$'}
color = {'k','r'}
lineSpec = {'-','--'}
for i = 1:2
    for j = 1:2
        plotsq(bMat.Time,bMat.Data(i,j,:),'DisplayName',legEnt{i,j},...
            'Color',color{j},'LineStyle',lineSpec{i},'LineWidth',1.5)
    end
end
legend('FontSize',15)
xlabel 'Time [s]'
ylabel 'Control Effectiveness [$\frac{Ns^2}{(deg)m}$]'
xlim([5 inf])
ylim([-.2 .1])
set(gca,'FontSize',12)

bMat = tsc.bMatrix
figure;
hold on;
legEnt = {'$\delta M/(\delta_{a})$',...
    '$\delta M/(\delta_{r})$';...
    '$\delta L/(\delta_{a})$',...
    '$\delta L/(\delta_{r})$'}
color = {'k','r'}
lineSpec = {'-','--'}
for i = 1:2
    for j = 1:2
        plotsq(bMat.Time,bMat.Data(i,j,:),'DisplayName',legEnt{i,j},...
            'Color',color{j},'LineStyle',lineSpec{i},'LineWidth',1.5)
    end
end
legend('FontSize',15)
xlabel 'Time [s]'
ylabel 'Control Effectiveness [$\frac{Nm}{(deg)}$]'
% ylim([-.2 .1])
xlim([5 inf])
set(gca,'FontSize',12)

%%
for i = 1:3
    tscSim{i} = tscSim{i}.resample(0:.01:tscSim{i}.airTenVecs.Time(end));
    tscSim{i} = reSampleDataUsingTime(tscSim{i},1,25.25);
end
%%
close all
subTitle = {'Roll Tracking','Roll and Yaw Tracking','Allocated Roll and Yaw Tracking'};
figure('Position',[50 50 800 600])
for i = 1:3
    subplot(4,3,i); grid on; hold on;
    plot(runData{i}.kite_elev,'LineWidth',1.5,'Color','k')
    plot(tscSim{i}.theta*-180/pi,'LineWidth',1.5,'LineStyle',':','Color','r')
    if i == 1
        legend('Experiment','Simulation')
        %         xlabel ''
        %     elseif i == 2
        %         xlabel ''
        %     elseif i == 3
        %         xlabel 'Time [s]'
        %     end
    end
    grid on;
    if i == 1
        ylabel '$\theta_o$ [deg]'
    end
    xlim([0 20])
    ylim([0 90])
    %     yticks([0 30 60 90])
    title('')
    set(gca,'FontSize',12)
end

% figure('Position',[100 100 800 500])
for i = 1:3
    subplot(4,3,3+i); grid on; hold on;
    plot(runData{i}.kite_azi*-1,'LineWidth',1.5,'Color','k')
    plot(tscSim{i}.phi*180/pi,'LineWidth',1.5,'LineStyle',':','Color','r')
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    if i == 1
        ylabel '$\phi_o$ [deg]'
    end
    xlim([0 20])
    ylim([-90 90])
    %     yticks([0 30 690 90])
    title('')
    set(gca,'FontSize',12)
end

% figure('Position',[100 100 800 500])
for i = 1:3
    [~,velAug{i}] = estExpVelMag(runData{i},1);
    powAug{i} = velAug{i}.^3;
    
    vels=tscSim{i}.velocityVecEst.Data(:,:,:);
    velmags{i} = squeeze(sqrt(sum((vels).^2,1)))/0.78;
    
    t = runData{i}.kite_azi.Time(1:end-1);
    subplot(4,3,9+i); grid on; hold on;
    plot(t,powAug{i},'LineWidth',1.5,'Color','k')
    plot(tscSim{i}.phi.Time,velmags{i}.^3,'LineWidth',1.5,'LineStyle',':','Color','r')
    xlabel 'Time [s]'
    grid on;
    if i == 1
        ylabel('$||\frac{v_{app}}{v_{tow}}||^3$')
    end
    xlim([0 20])
    
    %     if i == 1
    %         ylim([0 10])
    %     elseif i ==2
    %         ylim([0 20])
    %     elseif i == 3
    ylim([0 20])
    %     end
    %     yticks([0 30 690 90])
    title('')
    set(gca,'FontSize',12)
end

% figure('Position',[100 100 800 500])
for i = 1:3
    subplot(4,3,6+i); grid on; hold on;
    plot(t,velAug{i},'LineWidth',1.5,'Color','k')
    plot(tscSim{i}.phi.Time,velmags{i},'LineWidth',1.5,'LineStyle',':','Color','r')
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    if i == 1
        ylabel('$||\frac{v_{app}}{v_{tow}}||$')
    end
    xlim([0 20])
    ylim([0 3])
    title('')
    set(gca,'FontSize',12)
end
%%
t1 = t
xbound = [2 20];
figure('Position',[100 100 800 400])
t = tiledlayout(2,1)
for i = 2
    nexttile
    grid on; hold on;
    if i == 1
        plot(runData{i}.kiteRoll,'LineWidth',1.5)
    else
        plot(runData{i}.kiteRoll*180/pi,'LineWidth',1.5)
        %          plotsq(tscSim{i}.eulerAngles.Time,tscSim{i}.eulerAngles.Data(1,:,:)*180/pi-180,'LineWidth',1.5')
        plot(runData{i}.rollSP,'--k')
    end
    
    %     if i == 1
    legend('Experiment','Set Point','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %     xlabel 'Time [s]'
    %     end
    grid on;
    ylabel('Roll [deg]')
    xlim(xbound)
    %     ylim([0 5])
    %     yticks([0 1 2 3 4 5])
    title('')
    set(gca,'FontSize',12)
end

% figure('Position',[100 100 800 500])
for i = 2
    nexttile; grid on; hold on;
    if i == 1
        plot(runData{i}.kiteYaw,'LineWidth',1.5)
    else
        plot(runData{i}.yawDeadRec,'LineWidth',1.5)
        
        %     plotsq(tscSim{i}.eulerAngles.Time,tscSim{i}.eulerAngles.Data(3,:,:)*-180/pi+180,'LineWidth',1.5')
        plot(runData{i}.yawSP,'--k')
    end
    
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    ylabel('Yaw [deg]')
    xlim(xbound)
    %     ylim([0 5])
    %     yticks([0 1 2 3 4 5])
    title('')
    set(gca,'FontSize',12)
    xlabel 'Time [s]'
end
%%
xbound = [2 20];
figure('Position',[100 100 800 600])
t = tiledlayout(3,1)
for i = 2
    nexttile; grid on; hold on;
    if i == 1
        plot(runData{i}.kiteYaw,'LineWidth',1.5)
    else
        plot(runData{i}.kite_azi,'LineWidth',1.5)
    end
    
    plotsq(tscSim{i}.phi*-180/pi,'LineWidth',1.5')
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    ylabel('Azimuth [deg]')
    xlim(xbound)
    legend('Experiment','Simulation')
    set(gca,'FontSize',12)
end

for i = 2
    nexttile; grid on; hold on;
    if i == 1
        plot(runData{i}.kiteYaw,'LineWidth',1.5)
    else
        plot(runData{i}.kite_elev,'LineWidth',1.5)
    end
    
    plotsq(tscSim{i}.theta*-180/pi,'LineWidth',1.5')
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    ylabel('Elevation [deg]')
    xlim(xbound)
    set(gca,'FontSize',12)
end
for i = 2
    nexttile; grid on; hold on;
    if i == 1
        plot(runData{i}.kiteYaw,'LineWidth',1.5)
    else
        plot(t1,velAug{i},'LineWidth',1.5)
    end
    
    plotsq(tscSim{i}.phi.Time,velmags{i},'LineWidth',1.5')
    %     if i == 1
    %         legend('Experiment','Simulation')
    %         xlabel ''
    %     elseif i == 2
    %         xlabel ''
    %     elseif i == 3
    %         xlabel 'Time [s]'
    %     end
    grid on;
    ylabel('$\frac{||v_{app}||}{||v_{tow}||}$')
    xlim(xbound)
    
    set(gca,'FontSize',12)
    xlabel 'Time [s]'
end
% t.TileSpacing = 'compact';
% t.Padding = 'compact';

%% Plot Roll and Yaw Tracking per Control Type
i = 3
figure('Position',[100 100 800 200])
hold on
plot(runData{i}.kiteRoll*180/pi,'k','LineWidth',1.5)
plot(runData{i}.rollSP,'--k','LineWidth',1.5)
plot(runData{i}.yawDeadRec,'r','LineWidth',1.5)
plot(runData{i}.yawSP,'--r','LineWidth',1.5)
grid on;
ylabel('Angle [deg]')
xlabel('Time [s]')
legend('Roll','Roll SP','Yaw','Yaw SP')
xlim([0 30])
title('')
set(gca,'FontSize',15)

%% Plot Az and El per Control Type, vs Time and vs Each Other
%% Plot Roll and Yaw Tracking per Control Type
fpath = fullfile(fileparts(which('OCTProject.prj')),'output\');
nameCell = {'azElRoll','azElRollYaw','azElRollYawAllocated'}
for i = 1:3
    fName = nameCell{i}
    figure('Position',[100 100 800 200])
    hold on
    plot(runData{i}.kite_azi,'k','LineWidth',1.5)
    % plot(runData{i}.rollSP,'--k','LineWidth',1.5)
    plot(runData{i}.kite_elev,'r','LineWidth',1.5)
    % plot(runData{i}.yawSP,'--r','LineWidth',1.5)
    grid on;
    ylabel('Angle [deg]')
    xlabel('Time [s]')
    legend('Azimuth','Elevation')
    xlim([0 25])
    % ylim([-50 50])
    title('')
    set(gca,'FontSize',15)
    saveas(gcf,[fpath fName],'fig')
    saveas(gcf,[fpath fName],'png')
end
%%
for i = 1:3
    tscSimRMS{i} = reSampleDataUsingTime(tscSim{i},7.5,19.5);
    runDataRMS{i} = reSampleDataUsingTime(runData{i},7.5,19.5);
    rmsAz(i) = rms(tscSimRMS{i}.phi.Data*180/pi-runDataRMS{i}.kite_azi.Data*-1)
    rmsEL(i) = rms(tscSimRMS{i}.theta.Data*-180/pi-runDataRMS{i}.kite_elev.Data)
    rmsVelAug(i) = rms(squeeze(velmags{i}(750:1950))'-squeeze(velAug{i}(750:1950)))
    rmsPowAug(i) = rms(squeeze(velmags{i}(750:1950))'.^3 - powAug{i}(750:1950))
    
    if isfield(runDataRMS{i},'yawDeadRec')
        rmsRoll(i) = rms(squeeze(tscSimRMS{i}.rollDeg.Data)-180-squeeze(runDataRMS{i}.kiteRoll.Data)*180/pi)
        rmsYaw(i) = rms(squeeze(tscSimRMS{i}.yawDeg.Data)*-1+180-runDataRMS{i}.yawDeadRec.Data)
    else
        rmsRoll(i) = rms(squeeze(tscSimRMS{i}.rollDeg.Data)-180-squeeze(runDataRMS{i}.kiteRoll.Data))
        rmsYaw(i) = rms(squeeze(tscSimRMS{i}.yawDeg.Data)*-1+180-squeeze(runDataRMS{i}.kiteYaw.Data))
    end
    prom = 2
    thresh = 20
    
    azSimP{i} = [findpeaks(tscSimRMS{i}.phi.Data*180/pi,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-tscSimRMS{i}.phi.Data*180/pi,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    azExpP{i} = [findpeaks(runDataRMS{i}.kite_azi.Data*-1,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-runDataRMS{i}.kite_azi.Data*-1,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    A_phi{i} = (sqrt(sum(azSimP{i}.^2/length(azExpP{i})))-sqrt(sum(azExpP{i}.^2/length(azExpP{i}))))/...
        (max(runDataRMS{i}.kite_azi.Data*-1)-min(runDataRMS{i}.kite_azi.Data*-1))
    
    elSimP{i} = [findpeaks(tscSimRMS{i}.theta.Data*-180/pi,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-tscSimRMS{i}.theta.Data*-180/pi,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    elExpP{i} = [findpeaks(runDataRMS{i}.kite_elev.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-runDataRMS{i}.kite_elev.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    A_theta{i} = (sqrt(sum(elSimP{i}.^2/length(elExpP{i})))-sqrt(sum(elExpP{i}.^2/length(elExpP{i}))))/...
        (max(runDataRMS{i}.kite_elev.Data)-min(runDataRMS{i}.kite_elev.Data))
    
    rollSimP{i} = [findpeaks(squeeze(tscSimRMS{i}.rollDeg.Data-180),'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-squeeze(tscSimRMS{i}.rollDeg.Data-180),'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    yawSimP{i} = [findpeaks(squeeze(tscSimRMS{i}.yawDeg.Data*-1+180),'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
        findpeaks(-squeeze(tscSimRMS{i}.yawDeg.Data*-1+180),'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    if isfield(runDataRMS{i},'yawDeadRec')
        rollExpP{i} = [findpeaks(squeeze(runDataRMS{i}.kiteRoll.Data*180/pi),'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
            findpeaks(-squeeze(runDataRMS{i}.kiteRoll.Data*180/pi),'MinPeakProminence',prom,'MinPeakDistance',thresh)']
        yawExpP{i} = [findpeaks(runDataRMS{i}.yawDeadRec.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
            findpeaks(-runDataRMS{i}.yawDeadRec.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
        A_roll{i} = (sqrt(sum(rollSimP{i}.^2/length(rollSimP{i})))-sqrt(sum(rollExpP{i}.^2/length(rollExpP{i}))))/...
            (max(squeeze(runDataRMS{i}.kiteRoll.Data)*180/pi)-min(squeeze(runDataRMS{i}.kiteRoll.Data)*180/pi))
        A_yaw{i} = (sqrt(sum(yawSimP{i}.^2/length(yawSimP{i})))-sqrt(sum(yawExpP{i}.^2/length(yawExpP{i}))))/...
            (max(squeeze(runDataRMS{i}.yawDeadRec.Data))-min(squeeze(runDataRMS{i}.yawDeadRec.Data)))
    else
        rollExpP{i} = [findpeaks(squeeze(runDataRMS{i}.kiteRoll.Data),'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
            findpeaks(-squeeze(runDataRMS{i}.kiteRoll.Data),'MinPeakProminence',prom,'MinPeakDistance',thresh)']
        yawExpP{i} = [findpeaks(squeeze(runDataRMS{i}.kiteYaw.Data),'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
            findpeaks(-squeeze(runDataRMS{i}.kiteYaw.Data),'MinPeakProminence',prom,'MinPeakDistance',thresh)']
        A_roll{i} = (sqrt(sum(rollSimP{i}.^2/length(rollSimP{i})))-sqrt(sum(rollExpP{i}.^2/length(rollExpP{i}))))/...
            (max(runDataRMS{i}.kiteRoll.Data)-min(runDataRMS{i}.kiteRoll.Data))
        A_yaw{i} = (sqrt(sum(yawSimP{i}.^2/length(yawSimP{i})))-sqrt(sum(yawExpP{i}.^2/length(yawExpP{i}))))/...
            (max(squeeze(runDataRMS{i}.kiteYaw.Data))-min(squeeze(runDataRMS{i}.kiteYaw.Data)))
    end
    
    
    % elExpP{i} = [findpeaks(runDataRMS{i}.kite_elev.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)'...
    %     findpeaks(-runDataRMS{i}.kite_elev.Data,'MinPeakProminence',prom,'MinPeakDistance',thresh)']
    % A_theta{i} = (sqrt(sum(elSimP{i}.^2/length(elExpP{i})))-sqrt(sum(elExpP{i}.^2/length(elExpP{i}))))/...
    %     (max(runDataRMS{i}.kite_elev.Data)-min(runDataRMS{i}.kite_elev.Data))
end