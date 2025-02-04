clear
clc
format compact

% this is the build script for creating a vechile using class definition
% 'vehicle_v2' for a three tethered system that is being used by ayaz

% the script saves the variable 'vhcl' to a 'pathFollowingVhcl.mat'

VEHICLE               = "vehicle000";
SIXDOFDYNAMICS        = "sixDoFDynamicsEuler";

%% lifiting body
vhcl = OCT.vehicle;

vhcl.setFluidDensity(1000,'kg/m^3')
vhcl.setNumTethers(1,'');
vhcl.setNumTurbines(2,'');
vhcl.setBuoyFactor(1.0,'');

%Control Surfaces (Defaults are saved)
% vhcl.setMaxCtrlDef(30,'deg');
% vhcl.setMinCtrlDef(-30,'deg');
% vhcl.setMaxCtrlDefSpeed(60,'deg/s');

% % % volume and inertias
% vhcl.setVolume(2.85698,'m^3')
vhcl.setVolume(945352023.474*1e-9,'m^3');
vhcl.setIxx(6.303080401918E+09*1e-6,'kg*m^2');
vhcl.setIyy(2080666338.077*1e-6,'kg*m^2');
vhcl.setIzz(8.320369733598E+09*1e-6,'kg*m^2');
vhcl.setIxy(0,'kg*m^2');
vhcl.setIxz(81875397.942*1e-6,'kg*m^2');
vhcl.setIyz(0,'kg*m^2');
vhcl.setCentOfBuoy([0;0;0],'m');
vhcl.setRbridle_cm([0;0;0],'m');

% % % wing
% vhcl.setRwingLE_cm([-.47064 0 0],'m');
vhcl.setRwingLE_cm([0;0;0],'m');
vhcl.setWingChord(1,'m');
vhcl.setWingAR(10,'');
vhcl.setWingTR(0.8,'');
vhcl.setWingSweep(5,'deg');
vhcl.setWingDihedral(2,'deg');
vhcl.setWingIncidence(0,'deg');
vhcl.setWingNACA('2412','');
vhcl.setWingClMax(1.7,'');
vhcl.setWingClMin(-1.7,'');

% % % H-stab
vhcl.setRhsLE_wingLE([6;0;0],'m');
vhcl.setHsChord(0.5,'m');
vhcl.setHsAR(8,'');
vhcl.setHsTR(0.8,'');
vhcl.setHsSweep(10,'deg');
vhcl.setHsDihedral(0,'deg');
vhcl.setHsIncidence(-13.5,'deg');
vhcl.setHsNACA('0015','');
vhcl.setHsClMaxl(1.7,'');
vhcl.setHsClMin(-1.7,'');

% % % V-stab
vhcl.setRvs_wingLE([6;0;0],'m');
vhcl.setVsChord(0.6,'m');
vhcl.setVsSpan(2.0,'m');
vhcl.setVsTR(0.8,'');
vhcl.setVsSweep(15,'deg');
vhcl.setVsNACA('0015','');
vhcl.setVsClMax(1.7,'');
vhcl.setVsClMin(-1.7,'');

% % % Fuselage (could use more realistic numbers)
vhcl.setFuseDiameter(0.15,'m')
vhcl.setFuseEndDragCoeff(0,'')
vhcl.setFuseSideDragCoeff(0,'')
vhcl.setFuseRNose_LE([-2;0;0],'m')

% % % data file name
vhcl.setFluidCoeffsFileName('someFile2','');

% % % load/generate fluid dynamic datan
vhcl.calcFluidDynamicCoefffs
% vhcl.calcAddedMass
vhcl.addedMass.setValue(zeros(3,3),'kg')
%% save file in its respective directory
saveBuildFile('vhcl',mfilename,'variant',["VEHICLE","SIXDOFDYNAMICS"]);



