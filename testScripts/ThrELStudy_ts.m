%% Test script for John to control the kite model
Simulink.sdi.clear
clear;clc;%close all
%%  Select sim scenario
simScenario = 1.3;
%%  Set Test Parameters
saveSim = 1;                                                %   Flag to save results
Tmax = 1e10;
flwSpd = .25:0.25:2.5;                                     %   m/s - Flow speed
thrLength = 200:100:2000;
elev = (10:5:40)*pi/180;
h = 8*pi/180;  w = 40*pi/180;                              %   rad - Path width/height
[a,b] = boothParamConversion(w,h);                          %   Path basis parameters
%%
tic
for ii = 1:numel(flwSpd)
    for jj = 1:numel(elev)
        for kk = 1:numel(thrLength)
            eff = .95;   TDiam = 0.0125;   young = 37e9;
            fpath = fullfile(fileparts(which('OCTProject.prj')),'vehicleDesign\Tether\Tension\');
            maxT = load([fpath,sprintf('TmaxStudy_%dkN.mat',20)]);
            altitude(ii,jj,kk) = thrLength(kk)*sin(elev(jj));   sw = thrLength(kk)*sind(5);
            if altitude(ii,jj,kk) - sw <= 0 || altitude(ii,jj,kk) > 650
                el = NaN;
            else
                el = elev(jj);
            end
            Simulink.sdi.clear
            %%  Load components
            loadComponent('pathFollowWithAoACtrl');                 %   Path-following controller with AoA control
            loadComponent('oneDoFGSCtrlBasic');                         %   Ground station controller
            loadComponent('MantaGndStn');                               %   Ground station
            loadComponent('winchManta');                                %   Winches
            loadComponent('MantaTether');                           %   Manta Ray tether
            loadComponent('idealSensors')                               %   Sensors
            loadComponent('idealSensorProcessing')                      %   Sensor processing
            if simScenario == 0
                loadComponent('Manta2RotXFoil_AR8_b8');                             %   AR = 8; 8m span
            elseif simScenario == 2
                loadComponent('fullScale1thr');                                     %   DOE kite
            elseif simScenario == 1 || simScenario == 3 || simScenario == 4
                loadComponent('Manta2RotXFoil_AR8_b8');                             %   AR = 8; 8m span
            elseif simScenario == 1.1 || simScenario == 3.1 || simScenario == 4.1
                loadComponent('Manta2RotXFoil_AR9_b9');                             %   AR = 9; 9m span
            elseif simScenario == 1.2 || simScenario == 3.2 || simScenario == 4.2
                loadComponent('Manta2RotXFoil_AR9_b10');                            %   AR = 9; 10m span
            elseif simScenario == 1.3 || simScenario == 3.3 || simScenario == 4.3
                loadComponent('Manta2RotXFoil_AR8_b8');                             %   AR = 8; 8m span
            elseif simScenario == 1.4 || simScenario == 3.4 || simScenario == 4.4
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            elseif simScenario == 1.5 || simScenario == 3.5 || simScenario == 4.5
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            elseif simScenario == 1.6 || simScenario == 3.6 || simScenario == 4.6
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            elseif simScenario == 1.7 || simScenario == 3.7 || simScenario == 4.7
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            elseif simScenario == 1.8 || simScenario == 3.8 || simScenario == 4.8
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            elseif simScenario == 1.9 || simScenario == 3.9 || simScenario == 4.9
                error('Kite doesn''t exist for simScenario %.1f\n',simScenario)
            end
            %%  Environment Properties
            loadComponent('ConstXYZT');                                 %   Environment
            env.water.setflowVec([flwSpd(ii) 0 0],'m/s');               %   m/s - Flow speed vector
            if simScenario == 0
                ENVIRONMENT = 'environmentManta';                       %   Single turbine
            elseif simScenario == 2
                ENVIRONMENT = 'environmentDOE';                         %   No turbines
            else
                ENVIRONMENT = 'environmentManta2Rot';                   %   Two turbines
            end
            %%  Set basis parameters for high level controller
            if simScenario >= 1 && simScenario < 2
                loadComponent('varAltitudeBooth');                          %   High level controller
                hiLvlCtrl.elevationLookup.setValue(maxT.R.EL,'deg');
                if simScenario == 1.3
                    hiLvlCtrl.ELctrl.setValue(1,'');
                else
                    hiLvlCtrl.ELctrl.setValue(1,'');
                end
                hiLvlCtrl.ELslew.setValue(0.25,'deg/s');
                hiLvlCtrl.ThrCtrl.setValue(1,'');
            else
                loadComponent('constBoothLem');                             %   High level controller
            end
            hiLvlCtrl.basisParams.setValue([a,b,el,0*pi/180,thrLength(kk)],'[rad rad rad rad m]') % Lemniscate of Booth
            %%  Ground Station Properties
            %%  Vehicle Properties
            vhcl.setICsOnPath(.05,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value,6.5*flwSpd(ii)*norm([1;0;0]))
            if simScenario >= 3
                vhcl.setICsOnPath(0,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value,0)
                vhcl.setInitEulAng([0,0,0]*pi/180,'rad')
            end
            %%  Tethers Properties
            thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:)+gndStn.posVec.Value(:),'m');
            thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
                +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');
            thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
            thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
            thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
            thr.tether1.density.setValue(2226,'kg/m^3');
            thr.tether1.setDiameter(TDiam,thr.tether1.diameter.Unit);
            thr.tether1.setYoungsMod(young,thr.tether1.youngsMod.Unit);
            thr.tether1.dragCoeff.setValue(1,'');
            %%  Winches Properties
            wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);
            %%  Controller User Def. Parameters and dependant properties
            fltCtrl.setFcnName(PATHGEOMETRY,'');
            fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value);
            fltCtrl.firstSpoolLap.setValue(10,'');                  fltCtrl.winchSpeedIn.setValue(.1,'m/s');
            fltCtrl.AoASP.setValue(0,'');                           fltCtrl.AoAConst.setValue(vhcl.optAlpha.Value*pi/180,'deg');
            fltCtrl.AoACtrl.setValue(0,'');                         fltCtrl.elevatorConst.setValue(2,'deg');        
            fltCtrl.alphaCtrl.kp.setValue(.3,'(kN)/(rad)');         fltCtrl.Tmax.setValue(Tmax,'kN');
            fltCtrl.tanRoll.kp.setValue(0.2,'(rad)/(rad)');         fltCtrl.tanRoll.ki.setValue(.1,'(rad)/(rad*s)');
            fltCtrl.pitchMoment.kp.setValue(0,'(N*m)/(rad)');       fltCtrl.pitchMoment.ki.setValue(0,'(N*m)/(rad*s)');
            fltCtrl.rollMoment.kp.setValue(3e5,'(N*m)/(rad)');      fltCtrl.rollMoment.ki.setValue(00,'(N*m)/(rad*s)');
            fltCtrl.rollMoment.kd.setValue(2.2e5,'(N*m)/(rad/s)');  fltCtrl.rollMoment.tau.setValue(0.001,'s');
            fltCtrl.yawMoment.kp.setValue(00,'(N*m)/(rad)');        fltCtrl.rudderGain.setValue(0,'');
            fltCtrl.elevCtrlMax.upperLimit.setValue(1e4,'');        fltCtrl.elevCtrlMax.lowerLimit.setValue(-1e4,'');
            fprintf('\nFlow Speed = %.3f m/s;\tElevation = %.2f deg;\t ThrLength = %d m\n',flwSpd(ii),elev(jj)*180/pi,thrLength(kk));
            vhcl.setBuoyFactor(getBuoyancyFactor(vhcl,env,thr),'');
            %%  Simulate 
            if ~isnan(el)
                simParams = SIM.simParams;  simParams.setDuration(10000,'s');  dynamicCalc = '';
                simWithMonitor('OCTModel')
                %%  Log Results
                tsc = signalcontainer(logsout);
                dt = datestr(now,'mm-dd_HH-MM');
                [Idx1,Idx2] = tsc.getLapIdxs(max(tsc.lapNumS.Data)-1);  ran = Idx1:Idx2;
                [CLtot,CDtot] = tsc.getCLCD(vhcl);
                [Lift,Drag,Fuse,Thr] = tsc.getLiftDrag;
                Turb = squeeze(sqrt(sum(tsc.FTurbBdy.Data.^2,1)));
                Pow = tsc.rotPowerSummary(vhcl,env);
                Pavg(ii,jj,kk) = Pow.avg;    Pnet(ii,jj,kk) = Pow.avg*eff;
                V = squeeze(sqrt(sum(tsc.velCMvec.Data.^2,1)));
                Vavg(ii,jj,kk) = mean(V(ran));
                AoA(ii,jj,kk) = mean(squeeze(tsc.vhclAngleOfAttack.Data(:,:,ran)));
                airNode = squeeze(sqrt(sum(tsc.airTenVecs.Data.^2,1)))*1e-3;
                gndNode = squeeze(sqrt(sum(tsc.gndNodeTenVecs.Data.^2,1)))*1e-3;
                ten(ii,jj,kk) = max([max(airNode(ran)) max(gndNode(ran))]);
                fprintf('Average AoA = %.3f;\t Max Tension = %.1f kN;\t Elevation = %.1f\n',AoA(ii,jj,kk),ten(ii,jj,kk),el*180/pi);
                CL(ii,jj,kk) = mean(CLtot(ran));   CD(ii,jj,kk) = mean(CDtot(ran));
                Fdrag(ii,jj,kk) = mean(Drag(ran)); Flift(ii,jj,kk) = mean(Lift(ran));
                Ffuse(ii,jj,kk) = mean(Fuse(ran)); Fthr(ii,jj,kk) = mean(Thr(ran));   Fturb(ii,jj,kk) = mean(Turb(ran));
                elevation(ii,jj,kk) = el*180/pi;
                filename = sprintf(strcat('Turb%.1f_V-%.3f_EL-%.2f_Thr-%d.mat'),simScenario,flwSpd(ii),elev(jj)*180/pi,thrLength(kk));
                fpath = 'D:\Thr-L EL Study\';
                save(strcat(fpath,filename),'tsc','vhcl','thr','fltCtrl','env','simParams','LIBRARY','gndStn')
            else
                Pavg(ii,jj,kk) = NaN;  AoA(ii,jj,kk) = NaN;   ten(ii,jj,kk) = NaN;  Pnet = NaN;
                CL(ii,jj,kk) = NaN;    CD(ii,jj,kk) = NaN;    Fdrag(ii,jj,kk) = NaN;
                Flift(ii,jj,kk) = NaN; Ffuse(ii,jj,kk) = NaN; Fthr(ii,jj,kk) = NaN;
                Fturb(ii,jj,kk) = NaN; elevation(ii,jj,kk) = NaN;
            end
        end
    end
end
toc
%%
filename1 = sprintf('ThrEL_Study_Underwater.mat');
fpath1 = fullfile(fileparts(which('OCTProject.prj')),'output\');
save([fpath1,filename1],'Pavg','Pnet','AoA','CL','CD','Fdrag','Flift','Ffuse','Fthr',...
    'Fturb','thrLength','elevation','flwSpd','ten','Tmax','altitude','elev')

