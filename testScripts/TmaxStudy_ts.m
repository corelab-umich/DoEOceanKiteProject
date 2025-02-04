%% Test script for John to control the kite model
Simulink.sdi.clear
clear;clc;%close all
%%  Select sim scenario
simScenario = 1.3;
%%  Set Test Parameters
fpath2 = fullfile(fileparts(which('OCTProject.prj')),'vehicleDesign','Tether\');
saveSim = 1;                                                %   Flag to save results
Tmax = 20;
thrLength = 200:50:600;                                     %   m - Initial tether length
flwSpd = 0.3:0.05:0.5;                                      %   m/s - Flow speed
altitude = [50 100 150 200 250 300];
h = 10*pi/180;  w = 40*pi/180;                              %   rad - Path width/height
[a,b] = boothParamConversion(w,h);                          %   Path basis parameters
tic
for kk = 1:numel(flwSpd)
    for ii = 1:numel(thrLength)
        for jj = 1:numel(altitude)
            load([fpath2 'tetherDataNew.mat']);
            fpathT = fullfile(fileparts(which('OCTProject.prj')),...
                'vehicleDesign\Tether\Tension\');
            maxT = load([fpathT,sprintf('TmaxStudy_%dkN.mat',Tmax)]);
            eff = 0.95;
            if altitude(jj) >= 0.7071*thrLength(ii) || altitude(jj) <= 0.1736*thrLength(ii)
                el = NaN;
            else
                el = asin(altitude(jj)/thrLength(ii));
            end
            Simulink.sdi.clear
            %%  Load components
            loadComponent('pathFollowWithAoACtrl');                 %   Path-following controller with AoA control
            loadComponent('oneDoFGSCtrlBasic');                         %   Ground station controller
            loadComponent('MantaGndStn');                               %   Ground station
            loadComponent('winchManta');                                %   Winches
            loadComponent('MantaTether');                          %   Single link tether
            loadComponent('idealSensors')                               %   Sensors
            loadComponent('idealSensorProcessing')                      %   Sensor processing
            if simScenario == 0
                loadComponent('Manta2RotXFoil_AR8_b8');                       %   AR = 8; 8m span; 4pct buoyant
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
                loadComponent('Manta2RotXFoil_PDR');                                %   AR = 8; 8m span
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
            env.water.setflowVec([flwSpd(kk) 0 0],'m/s');               %   m/s - Flow speed vector
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
            hiLvlCtrl.basisParams.setValue([a,b,el,0*pi/180,thrLength(ii)],'[rad rad rad rad m]') % Lemniscate of Booth
            %%  Ground Station Properties
            %%  Vehicle Properties
            vhcl.setICsOnPath(.05,PATHGEOMETRY,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value,6.5*flwSpd(kk)*norm([1;0;0]))
            %%  Tethers Properties
            load([fileparts(which('OCTProject.prj')),'\vehicleDesign\Tether\tetherDataNew.mat']);
            thr.tether1.initGndNodePos.setValue(gndStn.thrAttch1.posVec.Value(:)+gndStn.posVec.Value(:),'m');
            thr.tether1.initAirNodePos.setValue(vhcl.initPosVecGnd.Value(:)...
                +rotation_sequence(vhcl.initEulAng.Value)*vhcl.thrAttchPts_B.posVec.Value,'m');
            thr.tether1.initGndNodeVel.setValue([0 0 0]','m/s');
            thr.tether1.initAirNodeVel.setValue(vhcl.initVelVecBdy.Value(:),'m/s');
            thr.tether1.vehicleMass.setValue(vhcl.mass.Value,'kg');
            thr.tether1.youngsMod.setValue(eval(sprintf('AR8b8.length600.tensionValues%d.youngsMod',Tmax)),'Pa');
            thr.tether1.density.setValue(eval(sprintf('AR8b8.length600.tensionValues%d.density',Tmax)),'kg/m^3');
            % thr.tether1.setDiameter(eval(sprintf('AR8b8.length600.tensionValues%d.outerDiam',Tmax)),'m');
            thr.tether1.setDiameter(0.0125,'m');
            %%  Winches Properties
            wnch.setTetherInitLength(vhcl,gndStn.posVec.Value,env,thr,env.water.flowVec.Value);
            %%  Controller User Def. Parameters and dependant properties
            fltCtrl.setFcnName(PATHGEOMETRY,'');
            fltCtrl.setInitPathVar(vhcl.initPosVecGnd.Value,hiLvlCtrl.basisParams.Value,gndStn.posVec.Value);
            fltCtrl.rudderGain.setValue(0,'')
            if simScenario >= 4
                fltCtrl.LaRelevationSP.setValue(26,'deg');          fltCtrl.setNomSpoolSpeed(.25,'m/s');
            end
            if simScenario >= 3 && simScenario < 4
                fltCtrl.elevCmd.kp.setValue(0,'(deg)/(rad)');       fltCtrl.elevCmd.ki.setValue(0,'(deg)/(rad*s)');
                fltCtrl.pitchCtrl.setValue(0,'');                   fltCtrl.pitchConst.setValue(-10,'deg');
                fltCtrl.pitchTime.setValue(0:500:2000,'s');         fltCtrl.pitchLookup.setValue(-10:5:10,'deg');
            elseif simScenario >= 1 && simScenario < 2
                fltCtrl.elevatorReelInDef.setValue(3,'deg');
                fltCtrl.AoACtrl.setValue(1,'');                     fltCtrl.RCtrl.setValue(0,'');
                fltCtrl.AoASP.setValue(1,'');                       fltCtrl.AoAConst.setValue(vhcl.optAlpha.Value*pi/180,'deg');
                fltCtrl.alphaCtrl.kp.setValue(.3,'(kN)/(rad)');     fltCtrl.Tmax.setValue(Tmax,'kN');
                fltCtrl.elevCtrl.kp.setValue(100,'(deg)/(rad)');    fltCtrl.elevCtrl.ki.setValue(1,'(deg)/(rad*s)');
                fltCtrl.rollCtrl.kp.setValue(200,'(deg)/(rad)');    fltCtrl.rollCtrl.ki.setValue(1,'(deg)/(rad*s)');
                fltCtrl.yawCtrl.kp.setValue(50,'(deg)/(rad)');      fltCtrl.rudderGain.setValue(0,'');
                fltCtrl.firstSpoolLap.setValue(10,'');              fltCtrl.winchSpeedIn.setValue(.1,'m/s');
                fltCtrl.elevCtrlMax.upperLimit.setValue(30,'');     fltCtrl.elevCtrlMax.lowerLimit.setValue(-30,'');
            elseif simScenario == 0
                vhcl.turb1.setDiameter(.0,'m');     vhcl.turb2.setDiameter(.0,'m')
            end
            vhcl.setBuoyFactor(getBuoyancyFactor(vhcl,env,thr),'');
            % vhcl.turb1.setDiameter(.7,'m');     vhcl.turb2.setDiameter(.7,'m')
            fprintf('\nFlow Speed = %.3f m/s;\tTether Length = %.1f m;\t Altitude = %d m;\t ThrD = %.1f mm\n',flwSpd(kk),thrLength(ii),altitude(jj),thr.tether1.diameter.Value*1e3);
            simParams = SIM.simParams;  simParams.setDuration(20000,'s');  dynamicCalc = '';
            vhcl.setBuoyFactor(getBuoyancyFactor(vhcl,env,thr),'');
            if ~isnan(el)
                simWithMonitor('OCTModel')
                %%  Log Results
                tsc = signalcontainer(logsout);
                dt = datestr(now,'mm-dd_HH-MM');
                [Idx1,Idx2] = tsc.getLapIdxs(max(tsc.lapNumS.Data)-1);  ran = Idx1:Idx2;
                [CLtot,CDtot] = tsc.getCLCD(vhcl);
                [Lift,Drag,Fuse,Thr] = tsc.getLiftDrag;
                Turb = squeeze(sqrt(sum(tsc.FTurbBdy.Data.^2,1)));
                Pow = tsc.rotPowerSummary(vhcl,env);
                Pavg(kk,ii,jj) = Pow.avg;    Pnet(kk,ii,jj) = Pow.avg*eff;
                V = squeeze(sqrt(sum(tsc.velCMvec.Data.^2,1)));
                Vavg(kk,ii,jj) = mean(V(ran));
                AoA(kk,ii,jj) = mean(squeeze(tsc.vhclAngleOfAttack.Data(:,:,ran)));
                airNode = squeeze(sqrt(sum(tsc.airTenVecs.Data.^2,1)))*1e-3;
                gndNode = squeeze(sqrt(sum(tsc.gndNodeTenVecs.Data.^2,1)))*1e-3;
                ten(kk,ii,jj) = max([max(airNode(ran)) max(gndNode(ran))]);
                fprintf('Average AoA = %.3f;\t Max Tension = %.1f kN;\t Elevation = %.1f\n',AoA(kk,ii,jj),ten(kk,ii,jj),el*180/pi);
                CL(kk,ii,jj) = mean(CLtot(ran));   CD(kk,ii,jj) = mean(CDtot(ran));
                Fdrag(kk,ii,jj) = mean(Drag(ran)); Flift(kk,ii,jj) = mean(Lift(ran));
                Ffuse(kk,ii,jj) = mean(Fuse(ran)); Fthr(kk,ii,jj) = mean(Thr(ran));   Fturb(kk,ii,jj) = mean(Turb(ran));
                elevation(kk,ii,jj) = el*180/pi;
                filename = sprintf(strcat('Turb%.1f_V-%.3f_Alt-%.d_ThrL-%d_Tmax-%d.mat'),simScenario,flwSpd(kk),altitude(jj),thrLength(ii),Tmax);
                fpath = 'D:\Altitude Thr-L Study\';
                save(strcat(fpath,filename),'tsc','vhcl','thr','fltCtrl','env','simParams','LIBRARY','gndStn')
            else
                Pavg(kk,ii,jj) = NaN;  AoA(kk,ii,jj) = NaN;   ten(kk,ii,jj) = NaN;
                CL(kk,ii,jj) = NaN;    CD(kk,ii,jj) = NaN;    Fdrag(kk,ii,jj) = NaN;
                Flift(kk,ii,jj) = NaN; Ffuse(kk,ii,jj) = NaN; Fthr(kk,ii,jj) = NaN;
                Fturb(kk,ii,jj) = NaN; elevation(kk,ii,jj) = el*180/pi;
                Pnet(kk,ii,jj) = NaN;  Vavg(kk,ii,jj) = NaN;
            end
        end
    end
end
filename1 = sprintf('Tmax_Study_PDR_Tmax-%d_ThrD-%.1f.mat',Tmax,TDiam*1e3);
fpath1 = fullfile(fileparts(which('OCTProject.prj')),'output\Tmax Study\');
save([fpath1,filename1],'Pavg','Pnet','AoA','CL','CD','Fdrag','Flift','Ffuse','Fthr',...
    'Fturb','thrLength','elevation','flwSpd','ten','Tmax','altitude')
toc
%%
% filename1 = sprintf('Tmax_Study_AR8b8.mat');
% fpath1 = fullfile(fileparts(which('OCTProject.prj')),'output','Tmax Study\');
% save([fpath1,filename1],'Pavg','AoA','CL','CD','Fdrag','Flift','Ffuse','Fthr',...
%     'Fturb','thrLength','elevation','flwSpd','ten','Tmax','altitude','ii','jj','ll','kk')
