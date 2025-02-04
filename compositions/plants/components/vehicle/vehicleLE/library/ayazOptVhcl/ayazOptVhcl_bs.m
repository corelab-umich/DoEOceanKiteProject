% clear
% clc
% format compact

VEHICLE               = "vehicleLE";
PLANT                 = "plantDOE";
SIXDOFDYNAMICS        = "sixDoFDynamicsCoupled";

%% Essential Values
vhcl = OCT.vehicle;

vhcl.setFluidDensity(1000,'kg/m^3')
vhcl.setNumTethers(1,'');
vhcl.setBuoyFactor(1.0,''); %Should this be slightly positively buoyant?
vhcl.setFluidCoeffsFileName('senEff_1','');

%% Volumes and Inertia
% vhcl.setVolume(2.85698,'m^3') %From CAD
% Ixx=1.094057613168724e+04;
% Iyy=1.247604938271605e+04;
% Izz=2.467555555555556e+04;
% Ixy=0;
% Ixz=5.293827160493829e+02;
% Iyz=0;
% 
% vhcl.setInertia_CM([Ixx -Ixy -Ixz;...
%                     -Ixy Iyy -Iyz;...
%                     -Ixz -Iyz Izz],'kg*m^2')
%                 
                
%% Volumes and Inertia
vhcl.setVolume(2.3,'m^3') %From CAD


Lxx = 5430.46;	Lxy = 0.00;	Lxz = 214.56;
Lyx = 0.00;	Lyy = 5160.29;	Lyz = 0.00;
Lzx = 214.56;	Lzy = 0.00;	Lzz = 10377.06;

vhcl.setInertia_CM([Lxx -Lxy -Lxz;...
                    -Lxy Lyy -Lyz;...In
                    -Lxz -Lyz Lzz],'kg*m^2')                
 
                
%% Important Points
vhcl.setRCM_LE([0 0 0],'m')
% vhcl.setRCM_LE([.47064 0 0],'m');
vhcl.setRB_LE(vhcl.rCM_LE.Value,'m');
vhcl.setRBridle_LE(vhcl.rCM_LE.Value + [0;0;0],'m');
vhcl.setRCentOfBuoy_LE(vhcl.rCM_LE.Value + [0;0;0],'m');

%% Added Mass/Damping (defaults to zeros)
% vhcl.setMa6x6_LE([134         0           0           0          14           0;...
%                    0      1591           0        -986           0        5166;...
%                    0         0        9265           0       -8202           0;...
%                    0      -986           0       67412           0       -4608;...
%                   14         0       -8202           0       20209           0;...
%                    0      5166           0       -4608           0       23320;],'');
% % vhcl.setD6x6_B([],'');

%% Control Surfaces
vhcl.setAllMaxCtrlDef(30,'deg');
vhcl.setAllMinCtrlDef(-30,'deg');
vhcl.setAllMaxCtrlDefSpeed(60,'deg/s');
%% Setting for analysis 
vhcl.setWingRootChord(1.159,'m');
AR = 7.4;
vhcl.fuse.setRNose_LE([-2.75;0;0],'m');
vhcl.hStab.setRSurfLE_WingLEBdy([4.25;0;0],'m');
vhcl.vStab.setRSurfLE_WingLEBdy([vhcl.hStab.rSurfLE_WingLEBdy.Value(1)-0.15;0;0],'m');

%% Wing
% vhcl.setWingRootChord(1,'m');
vhcl.setWingAR(AR,''); %Span 10, hspan 5
vhcl.setWingTR(1,'');
vhcl.setWingSweep(1,'deg');
vhcl.setWingDihedral(1,'deg');
vhcl.setWingIncidence(0,'deg');
vhcl.setWingAirfoil('NACA2412','');
vhcl.setWingClMin(-1.7,'');
vhcl.setWingClMax(1.7,'');

%% H-stab and V-stab
% vhcl.hStab.setRSurfLE_WingLEBdy([5.5;0;0],'m');
vhcl.hStab.setNumTraps(2,'');
vhcl.hStab.setRootChord(.5,'m');
vhcl.hStab.setTR(.8,'');
vhcl.hStab.setHalfSpanGivenAR(4/.45,''); %Span 4, hspan 2
vhcl.hStab.setSweep(2.8624,'deg');
vhcl.hStab.setIncidence(-13.5,'deg');
vhcl.hStab.setAirfoil('NACA0015','');
vhcl.hStab.setClMin(-1.7,'');
vhcl.hStab.setClMax(1.7,'');

% vhcl.vStab.setRSurfLE_WingLEBdy([5.35;0;0],'m');
vhcl.vStab.setRootChord(.65,'m');
vhcl.vStab.setHalfSpan(2.4375,'m');
vhcl.vStab.setTR(.8,'');
vhcl.vStab.setSweep(3.44,'deg');
vhcl.vStab.setAirfoil('NACA0015','');
vhcl.vStab.setClMin(-1.7,'');
vhcl.vStab.setClMax(1.7,'');


%% Fuselage (could use more realistic numbers)
vhcl.fuse.setDiameter(0.25/2,'m');
vhcl.fuse.setEndDragCoeff(.1,'');
vhcl.fuse.setSideDragCoeff(1,'');
% vhcl.fuse.setRNose_LE([-2;0;0],'m');
vhcl.fuse.setREnd_LE([max(vhcl.hStab.rSurfLE_WingLEBdy.Value(1)+vhcl.hStab.rootChord.Value,...
    vhcl.vStab.rSurfLE_WingLEBdy.Value(1)+vhcl.vStab.rootChord.Value);0;0],'m');

%% Added Mass/Damping 
Input.wing.Thickness = 12;
Input.wing.Sections = 20; 
Input.hStab.Thickness = 12; 
Input.hStab.Sections = 20; 
Input.vStab.Thickness = 12; 
Input.vStab.Sections = 10; 
Input.fuse.Sections = 10; 

[MA] = getAddedMass(Input,vhcl); 
vhcl.setMa6x6_LE([MA],'');
    
%% load/generate fluid dynamic datan
vhcl.hydroCharacterization.setValue(3,'')
vhcl.calcFluidDynamicCoefffs

%% Turbines
totalCD = vhcl.portWing.CD.Value + vhcl.stbdWing.CD.Value + ...
    vhcl.hStab.CD.Value + vhcl.vStab.CD.Value;
opAoA = 11;
[~,aIdx] = min(abs(opAoA - vhcl.portWing.alpha.Value));

idealTurbCD = 0.5*totalCD(aIdx);
idealArea   = idealTurbCD*vhcl.fluidRefArea.Value;
ideaTurbDia = sqrt(4*idealArea/pi);


vhcl.setNumTurbines(2,'');
vhcl.build('TurbClass','turb');
% port rotor
vhcl.turb1.setMass(6,'kg');
vhcl.turb1.setDiameter(ideaTurbDia/2,'m');
vhcl.turb1.setAxisUnitVec([1;0;0],'');
vhcl.turb1.setAttachPtVec(vhcl.portWing.outlinePtsBdy.Value(:,2)*1/3,'m');
vhcl.turb1.setPowerCoeff(.4,'');
vhcl.turb1.setDragCoef(.9,'');
vhcl.turb1.setAxalInductionFactor(1.5,'');
vhcl.turb1.setTipSpeedRatio(6,'');
vhcl.turb1.setStaticArea(0.08,'m^2');
vhcl.turb1.setStaticCD(1.5,'');
% starboard rotor
vhcl.turb2.setMass(6,'kg');
vhcl.turb2.setDiameter(ideaTurbDia/2,'m');
vhcl.turb2.setAxisUnitVec([1;0;0],'');
vhcl.turb2.setAttachPtVec(vhcl.stbdWing.outlinePtsBdy.Value(:,2)*1/3,'m');
vhcl.turb2.setPowerCoeff(.4,'');
vhcl.turb2.setDragCoef(.9,'');
vhcl.turb2.setAxalInductionFactor(1.5,'');
vhcl.turb2.setTipSpeedRatio(6,'');
vhcl.turb2.setStaticArea(0.08,'m^2');
vhcl.turb2.setStaticCD(1.5,'');

powerPot = 0.5*0.25*pi*vhcl.turb1.diameter.Value*vhcl.turb1.powerCoeff.Value*...
    1000*6.37^3;

%% save file in its respective directory
saveBuildFile('vhcl',mfilename,'variant',["VEHICLE","PLANT","SIXDOFDYNAMICS"]);


