function plotFlightResults(obj,vhcl,env,thr,fltCtrl,varargin)
%%  Parse Inputs
p = inputParser;
addOptional(p,'plot1Lap',false,@islogical);
addOptional(p,'lapNum',1,@isnumeric);
addOptional(p,'plotS',false,@islogical);
addOptional(p,'cross',false,@islogical);
addOptional(p,'AoASP',true,@islogical);
addOptional(p,'maxTension',true,@islogical);
addOptional(p,'plotBeta',false,@islogical);
addOptional(p,'LiftDrag',false,@islogical);
addOptional(p,'dragChar',false,@islogical);
parse(p,varargin{:})

R = 3;  C = 2;
data = squeeze(obj.currentPathVar.Data);
time = obj.lapNumS.Time;
lap = p.Results.plot1Lap;
con = p.Results.plotS;
AoA = p.Results.AoASP;
turb = isprop(obj,'turbPow');
%%  Determine Single Lap Indices
if lap
    [Idx1,Idx2] = getLapIdxs(obj,p.Results.lapNum-1);
    ran = Idx1:Idx2-1;
    lim = [time(Idx1) time(Idx2)];
else
    lim = [time(1) time(end)];
end
%%  Compute Plotting Variables
if turb
    N = vhcl.numTurbines.Value;
    if N == 1
        if isfield(obj,'netPower')
            power = squeeze(obj.netPower.Data(1,1,:));
        else 
            power = squeeze(obj.turbPow.Data(1,1,:));
        end
        energy = cumtrapz(time,power)/1000/3600;
    else
        if isfield(obj,'netPower')
            power = squeeze(obj.netPower.Data(1,1,:));
        else 
            power = squeeze(obj.turbPow.Data(1,1,:));
        end
        energy = cumtrapz(time,power)/1000/3600;
        try
            speed = (squeeze(obj.turbVelP.Data(1,1,:))+squeeze(obj.turbVelS.Data(1,1,:)))/2;
        catch
            speed = squeeze(sqrt(sum(obj.vAppTurb.Data.^2,1)))';
        end
    end
else
    power = squeeze(obj.winchPower.Data(:,1));
    energy = cumtrapz(time,power)/1000/3600;
end
vKite = -squeeze(obj.velCMvec.Data(1,:,:));
%   Tether tension
airNode = squeeze(sqrt(sum(obj.airTenVecs.Data.^2,1)))*1e-3;
gndNode = squeeze(sqrt(sum(obj.gndNodeTenVecs.Data.^2,1)))*1e-3;
%   Hydrocharacteristics
[CLsurf,CDtot] = getCLCD(obj,vhcl,thr);
FLiftBdyP1 = squeeze(sqrt(sum(obj.portWingLift.Data(:,1,:).^2,1)));
FLiftBdyP2 = squeeze(sqrt(sum(obj.stbdWingLift.Data(:,1,:).^2,1)));
FLiftBdyP3 = squeeze(sqrt(sum(obj.hStabLift.Data(:,1,:).^2,1)));
FLiftBdy   = FLiftBdyP1 + FLiftBdyP2 + FLiftBdyP3;
FDragBdyP1 = squeeze(sqrt(sum(obj.portWingDrag.Data(:,1,:).^2,1)));
FDragBdyP2 = squeeze(sqrt(sum(obj.stbdWingDrag.Data(:,1,:).^2,1)));
FDragBdyP3 = squeeze(sqrt(sum(obj.hStabDrag.Data(:,1,:).^2,1)));
FDragBdyP4 = squeeze(sqrt(sum(obj.vStabDrag.Data(:,1,:).^2,1)));
FDragBdy = FDragBdyP1 + FDragBdyP2 + FDragBdyP3 + FDragBdyP4;
FDragFuse = squeeze(sqrt(sum(obj.FFuseBdy.Data.^2,1)));
FDragThr = squeeze(sqrt(sum(obj.thrDragVecs.Data.^2,1)));
if turb
    FTurbBdy = squeeze(sqrt(sum(obj.FTurbBdy.Data.^2,1)));
    totDrag = (FDragBdy + FTurbBdy + FDragFuse + FDragThr);
    LiftDrag = FLiftBdy./(FDragBdy + FTurbBdy + FDragFuse );
else
    totDrag = (FDragBdy + FDragFuse + FDragThr);
    LiftDrag = FLiftBdy./(FDragBdy + FDragFuse);
end
try
    C1 = cosd(squeeze(obj.elevationAngle.Data));  C2 = cosd(squeeze(obj.azimuthAngle.Data));
catch
    C1 = cosd(squeeze(obj.elevationAngle.Data));  C2 = cosd(squeeze(obj.azimuthAngle.Data));
end
if turb
    PLoyd = 2/27*env.water.density.Value*env.water.speed.Value^3*vhcl.fluidRefArea.Value*CLsurf.^3./CDtot.^2.*(C1.*C2).^3/vhcl.turb1.axialInductionFactor.Value;
    vLoyd = LiftDrag.*env.water.speed.Value.*(C1.*C2);
else
    PLoyd = 2/27*env.water.density.Value*env.water.speed.Value^3*vhcl.fluidRefArea.Value*CLsurf.^3./CDtot.^2.*(C1.*C2).^3;
    vLoyd = LiftDrag.*env.water.speed.Value.*(C1.*C2)*2/3;
end

%%Being Plotting
figure('Position',[100 100 800 800]);
tL = tiledlayout(R,C);
%%  Plot Power Output
nexttile
hold on; grid on
yyaxis left
if lap
    if con
        plot(data(ran),power(ran)*1e-3,'b-');  ylabel('Power [kW]');  set(gca,'YColor',[0 0 1])
%         plot(data(ran),PLoyd(ran)*1e-3,'b--');  ylabel('Power [kW]');  legend('Kite','Loyd','location','southeast','AutoUpdate','off');  ylim([0 inf]);
%         text(0.04,310,sprintf('P = %.3f kW',mean(powAvg)*1e-3))
    else
        plot(time(ran),power(ran)*1e-3,'b-');  ylabel('Power [kW]');  set(gca,'YColor',[0 0 1]);  xlim(lim);  ylim([0 inf]);
%         plot(time(ran),PLoyd(ran)*1e-3,'b--');  ylabel('Power [kW]');  legend('Kite','Loyd','location','southeast','AutoUpdate','off');  ylim([0 inf]);
    end
else
    plot(time,power*1e-3,'b-');  ylabel('Power [kW]');  set(gca,'YColor',[0 0 1]);  xlim(lim);  ylim([0 inf]);
%     plot(time,PLoyd*1e-3,'b--');  ylabel('Power [kW]');  legend('Kite','Loyd','location','southeast','AutoUpdate','off');  ylim([0 inf]);
end
yyaxis right
if lap
    if con
        plot(data(ran),energy(ran)-energy(Idx1),'r-');  ylabel('Energy [kWh]');  set(gca,'YColor',[1 0 0]);
    else
        plot(time(ran),energy(ran)-energy(Idx1),'r-');  ylabel('Energy [kWh]');  set(gca,'YColor',[1 0 0]);  xlim(lim);
    end
else
    plot(time,energy,'r-');  ylabel('Energy [kWh]');  set(gca,'YColor',[1 0 0]);  xlim(lim);
end
%%  Plot Tether Tension
nexttile
hold on; grid on;
if p.Results.maxTension
    Tmax = (fltCtrl.Tmax.Value/0.92)*ones(numel(time),1)*1e3;
else
    Tmax = (0*ones(numel(time),1));
end
if lap
    if con
        plot(data(ran),Tmax(ran),'r--');    plot(data(ran),airNode(ran)*1000,'b-');  
        plot(data(ran),gndNode(ran)*1000,'g-');  ylabel('Thr Tension [kN]');  legend('Limit','Kite','Glider')
    else
        plot(time(ran),Tmax(ran),'r--');    plot(time(ran),airNode(ran)*1000,'b-');  
        plot(time(ran),gndNode(ran)*1000,'g-');  ylabel('Thr Tension [kN]');  legend('Limit','Kite','Glider');  xlim(lim)
    end
else
    plot(time,Tmax,'r--');  plot(time,airNode,'b-');  plot(time,gndNode,'g-');  
    ylabel('Thr Tension [kN]');  legend('Limit','Kite','Glider');  xlim(lim)

end
%%  Plot Speed
nexttile; hold on; grid on;
if lap
    if con
        if turb
            plot(data(ran),speed(ran),'g-');  ylabel('Speed [m/s]');  ylim([0,inf]);
            plot(data(ran),vKite(ran),'b-');  ylabel('Speed [m/s]');  legend('Turb','Kite','location','southeast');
%             plot(data(ran),vLoyd(ran),'r--');  ylabel('Speed [m/s]');  legend('Turb','Kite','Loyd','location','southeast');
%             text(0.05,1,sprintf('V = %.3f m/s',mean(speed(ran))))
%             text(0.05,3,['$\mathrm{V_f}$',sprintf(' = %.3f m/s',env.water.speed.Value)])
        else
            plot(data(ran),vKite(ran),'b-');  ylabel('Speed [m/s]');  ylim([0,inf]);
%             plot(data(ran),vLoyd(ran),'r--');  ylabel('Speed [m/s]');  legend('Kite','Loyd','location','southeast');
        end
    else
        if turb
            plot(time(ran),speed(ran),'g-');  ylabel('Speed [m/s]');  xlim(lim);  ylim([0,inf]);
            plot(time(ran),vKite(ran),'b-');  ylabel('Speed [m/s]');  legend('Turb','Kite','location','southeast');
%             plot(time(ran),vLoyd(ran),'r--');  ylabel('Speed [m/s]');  legend('Turb','Kite','Loyd','location','southeast');
        else
            plot(time(ran),vKite(ran),'b-');  ylabel('Speed [m/s]');  ylim([0,inf]);
%             plot(time(ran),vLoyd(ran),'r--');  ylabel('Speed [m/s]');  legend('Kite','Loyd','location','southeast');
        end
    end
else
    if turb
        plot(time,speed,'g-');  ylabel('Speed [m/s]');  xlim(lim);
        plot(time,vKite,'b-');  ylabel('Speed [m/s]');  ylim([0,inf]);  legend('Turb','Kite','location','southeast');
%         plot(time,vLoyd,'r--');  ylabel('Speed [m/s]');  legend('Turb','Kite','Loyd','location','southeast');
    else
        plot(time,vKite,'b-');  ylabel('Speed [m/s]');
%         plot(time,vLoyd,'r--');  ylabel('Speed [m/s]');  legend('Kite','Loyd','location','southeast');
    end
end
%%  Plot Angle of attack
nexttile; hold on; grid on
if lap
    if con
        if p.Results.AoASP
            plot(data(ran),obj.AoASP.Data(ran)*180/pi,'r-','DisplayName','Setpoint');
        end
        plot(data(ran),squeeze(obj.vhclAngleOfAttack.Data(ran)),'b-','DisplayName','AoA');
%         plot(data(ran),squeeze(obj.hStabAoA.Data(ran)),'k--','DisplayName','Stabilizer AoA');
        ylabel('Angle [deg]');
        if p.Results.plotBeta
            plot(data(ran),squeeze(obj.betaBdy.Data(1,1,ran))*180/pi,'g-','DisplayName','Beta');  ylabel('Angle [deg]');
        end
        legend;
    else
        plot(time(ran),obj.AoASP.Data(ran)*180/pi,'r-','DisplayName','Setpoint');
        plot(time(ran),squeeze(obj.vhclAngleOfAttack.Data(ran)),'b-','DisplayName','AoA');
%         plot(data(ran),squeeze(obj.hStabAoA.Data(ran)),'k--','DisplayName','Stabilizer AoA');
        ylabel('Angle [deg]');  xlim(lim);
        if p.Results.plotBeta
            plot(time(ran),squeeze(obj.betaBdy.Data(1,1,ran))*180/pi,'g-','DisplayName','Beta');  ylabel('Angle [deg]');   xlim(lim)
        end
        legend; 
    end
else
    plot(time,obj.AoASP.Data*180/pi,'r-');  
    plot(time,squeeze(obj.vhclAngleOfAttack.Data),'b-'); %ylim([0 20]);
%     plot(time,squeeze(obj.hStabAoA.Data),'k--','DisplayName','Stabilizer AoA');
    ylabel('Angle [deg]');  xlim(lim);  legend('Setpoint','AoA');
    if p.Results.plotBeta
        plot(time,squeeze(obj.betaBdy.Data(1,1,:))*180/pi,'g-');  ylabel('Angle [deg]');  legend('Port AoA','Stbd AoA','Beta');  xlim(lim)
    end
end

%%  Plot Ctrl Surface Deflection 
nexttile(6); hold on; grid on
if lap
    if con
        plot(data(ran),squeeze(obj.ctrlSurfDefl.Data(ran,1)),'b-');  xlabel('Path Position');  ylabel('Deflection [deg]');
        plot(data(ran),squeeze(obj.ctrlSurfDefl.Data(ran,3)),'r-');  xlabel('Path Position');  ylabel('Deflection [deg]');
        plot(data(ran),squeeze(obj.ctrlSurfDefl.Data(ran,4)),'g-');  xlabel('Path Position');  ylabel('Deflection [deg]');
    else
        plot(time(ran),squeeze(obj.ctrlSurfDefl.Data(ran,1)),'b-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
        plot(time(ran),squeeze(obj.ctrlSurfDefl.Data(ran,3)),'r-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
        plot(time(ran),squeeze(obj.ctrlSurfDefl.Data(ran,4)),'g-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
    end
else
    plot(time,squeeze(obj.ctrlSurfDefl.Data(:,1)),'b-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
    plot(time,squeeze(obj.ctrlSurfDefl.Data(:,3)),'r-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
    plot(time,squeeze(obj.ctrlSurfDefl.Data(:,4)),'g-');  xlabel('Time [s]');  ylabel('Deflection [deg]');  xlim(lim)
end
legend('P-Aileron','Elevator','Rudder')
%%  Plot Lift-Drag ratio
nexttile(5); hold on; grid on
yyaxis left
if lap
    if con
        plot(data(ran),totDrag(ran)*1e-3,'r-');    xlabel('Path Position');  ylabel('Force [kN]');  set(gca,'YColor',[0 0 0])
        plot(data(ran),FLiftBdy(ran)*1e-3,'b-');   xlabel('Path Position');  ylabel('Force [kN]');  legend('Drag','Lift')
    else
        plot(time(ran),totDrag(ran)*1e-3,'r-');    xlabel('Time [s]');  ylabel('Force [kN]');  set(gca,'YColor',[0 0 0])
        plot(time(ran),FLiftBdy(ran)*1e-3,'b-');   xlabel('Time [s]');  ylabel('Force [kN]');  legend('Drag','Lift') ;  xlim(lim);
    end
else
    plot(time,totDrag*1e-3,'r-');    xlabel('Time [s]');  ylabel('Force [kN]');  set(gca,'YColor',[0 0 0])
    plot(time,FLiftBdy*1e-3,'b-');   xlabel('Time [s]');  ylabel('Force [kN]');  legend('Drag','Lift') ;  xlim(lim);
end
yyaxis right
if lap
    if con
        plot(data(ran),CLsurf(ran),'b--');    xlabel('Path Position');  set(gca,'YColor',[0 0 0])
        plot(data(ran),CDtot(ran),'r--');   xlabel('Path Position');  ylabel('CD and CL');  legend('Drag','Lift','CL','CD')
    else
        plot(time(ran),CLsurf(ran),'b--');    xlabel('Time [s]');  set(gca,'YColor',[0 0 0])
        plot(time(ran),CDtot(ran),'r--');   xlabel('Time [s]');  ylabel('CD and CL');  legend('Drag','Lift','CL','CD') ;  xlim(lim);
    end
else
    plot(time,CLsurf,'b--');    xlabel('Time [s]');  set(gca,'YColor',[0 0 0])
    plot(time,CDtot,'r--');   xlabel('Time [s]');  ylabel('CD and CL');  legend('Drag','Lift','CL','CD') ;  xlim(lim);
end
% figure; hold on; grid on
% plot(data(ran),CDtot(ran),'r-');  xlabel('Path Position');  ylabel('');
% plot(data(ran),CLsurf(ran),'b-');  xlabel('Path Position');  ylabel('');
% linkaxes([ax1 ax2 ax3 ax4 ax5 ax6],'x');
% legend('CD','CL')
%%  Plot Drag Characteristics 
if turb && p.Results.dragChar && con
    figure(); subplot(2,1,2); hold on; grid on
    plot(time,FTurbBdy./(totDrag-FTurbBdy),'b-');  
    plot(time,.5*ones(length(time),1),'r-');
    xlabel('Path Position');  ylabel('$\mathrm{D_t/D_k}$');  ylim([0 1]);
    subplot(2,1,1); hold on; grid on
    plot(time,FDragBdy,'b-');
    plot(time,FDragFuse,'r-');
    plot(time,FDragThr,'g-');
    plot(time,FTurbBdy,'c-');
    plot(time,totDrag,'k-');
    xlabel('Path Position');  ylabel('Drag [N]');  legend('Surf','Fuse','Thr','Turb','Tot');
end
%%  Assess cross-current flight performance 
if p.Results.cross
    figure;
    subplot(3,1,1); hold on; grid on
    if lap
        if con
            plot(data(ran),squeeze(obj.velAngleError.Data(1,1,ran))*180/pi,'r-');    xlabel('Path Position');  ylabel('Angle Error [deg]');
            plot(data(ran),squeeze(obj.tanRollError.Data(ran))*180/pi,'b-');   xlabel('Path Position');  ylabel('Angle Error [deg]');  legend('Velocity','Tan Roll');
        else
            plot(time(ran),squeeze(obj.velAngleError.Data(1,1,ran))*180/pi,'r-');    xlabel('Time [s]');  ylabel('Angle Error [deg]');
            plot(time(ran),squeeze(obj.tanRollError.Data(ran))*180/pi,'b-');   xlabel('Time [s]');  ylabel('Angle Error [deg]');  legend('Velocity','Tan Roll');  xlim(lim);
        end
    else
        plot(time,squeeze(obj.velAngleError.Data(1,1,:))*180/pi,'r-');    xlabel('Time [s]');  ylabel('Angle Error [deg]');
        plot(time,squeeze(obj.tanRollError.Data(:))*180/pi,'b-');   xlabel('Time [s]');  ylabel('Angle Error [deg]');  legend('Velocity','Tan Roll');  xlim(lim);
    end
    subplot(3,1,2); hold on; grid on
    if lap
        if con
            plot(data(ran),squeeze(obj.ctrlSurfDefl.Data(ran,1)),'r-');    xlabel('Path Position');  ylabel('Angle [deg]');
            plot(data(ran),squeeze(obj.ctrlSurfDefl.Data(ran,2)),'b-');    xlabel('Path Position');  ylabel('Angle [deg]');  legend('Port','Stbd');
        else
            plot(time(ran),squeeze(obj.ctrlSurfDefl.Data(ran,1)),'r-');    xlabel('Time [s]');  ylabel('Angle [deg]');
            plot(time(ran),squeeze(obj.ctrlSurfDefl.Data(ran,2)),'b-');    xlabel('Time [s]');  ylabel('Angle [deg]');  legend('Port','Stbd');  xlim(lim);
        end
    else
        plot(time,squeeze(obj.ctrlSurfDefl.Data(:,1)),'r-');    xlabel('Time [s]');  ylabel('Angle [deg]');
        plot(time,squeeze(obj.ctrlSurfDefl.Data(:,2)),'b-');    xlabel('Time [s]');  ylabel('Angle [deg]');  legend('Port','Stbd');  xlim(lim);
    end
    subplot(3,1,3); hold on; grid on
    if lap
        if con
            plot(data(ran),squeeze(obj.desiredMoment.Data(ran,1)),'r-');    xlabel('Path Position');  ylabel('Roll Moment [N]');
            plot(data(ran),squeeze(obj.MFluidBdy.Data(1,1,ran)),'b-');   xlabel('Path Position');  ylabel('Roll Moment [N]');  legend('Desired','Actual');
        else
            plot(time(ran),squeeze(obj.desiredMoment.Data(ran,1)),'r-');    xlabel('Time [s]');  ylabel('Roll Moment [N]');
            plot(time(ran),squeeze(obj.MFluidBdy.Data(1,1,ran)),'b-');   xlabel('Time [s]');  ylabel('Roll Moment [N]');  legend('Desired','Actual');  xlim(lim);
        end
    else
        plot(time,squeeze(obj.desiredMoment.Data(:,1)),'r-');    xlabel('Time [s]');  ylabel('Roll Moment [N]');
        plot(time,squeeze(obj.MFluidBdy.Data(1,1,:)),'b-');   xlabel('Time [s]');  ylabel('Roll Moment [N]');  legend('Desired','Actual');  xlim(lim);
    end
end
tL.Padding = 'compact';
tL.TileSpacing = 'compact';