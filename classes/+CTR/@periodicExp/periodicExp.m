classdef periodicExp < handle
    %PTHFLWCTRL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        % FPID controllers
        tanRoll
        yawMoment
        pitchMoment
        rollMoment
        rollCtrl
        alphaCtrl
        RPMCtrl
        yawCtrl
        % Saturations
        maxBank
        controlSigMax
        elevCtrlMax
        % SIM.parameters
        winchSpeedIn
        winchSpeedOut
        ctrlAllocMat
        searchSize
        traditionalBool
        minR
        perpErrorVal
        startControl
        outRanges
        elevatorConst
        maxR
        fcnName
        initPathVar
        firstSpoolLap
        rudderGain
        % Setpoint 
        AoACtrl
        AoASP
        RCtrl
        AoAConst
        AoAmin
        RPMConst
        RPMmax
        Tmax
        TmaxCtrl
        optAltitude
        startCtrl
        period
        
        rollAmp
        yawAmp
        trimElevator
        ccElevator
        rollPhase
        yawPhase
        
    end
    properties (Dependent)
        frequency
    end
    
    methods
        function obj = periodicExp
            %PTHFLWCTRL 
            obj.tanRoll             = CTR.FPID('rad','rad');
            obj.yawMoment           = CTR.FPID('rad','N*m');
            obj.pitchMoment         = CTR.FPID('rad','N*m');
            obj.rollMoment          = CTR.FPID('rad','N*m');
            obj.rollCtrl            = CTR.FPID('deg','deg');
            obj.alphaCtrl           = CTR.FPID('kN','rad');
            obj.RPMCtrl             = CTR.FPID('kN','');
            obj.yawCtrl             = CTR.FPID('deg','deg');
            
            obj.maxBank             = CTR.sat;
            obj.controlSigMax       = CTR.sat;
            obj.elevCtrlMax         = CTR.sat;
            
            obj.winchSpeedIn        = SIM.parameter('Unit','m/s','Description','Max tether spool in speed.');
            obj.winchSpeedOut       = SIM.parameter('Unit','m/s','Description','Max tether spool out speed.');
            obj.ctrlAllocMat        = SIM.parameter('Unit','(deg)/(m^3)','Description','Control allocation matrix for control surfaces');
            obj.searchSize          = SIM.parameter('Unit','','Description','Range of normalized path variable to search','NoScale',true);
            obj.traditionalBool     = SIM.parameter('Unit','','Description','Switch for inter vs intra cycle spooling.  Should be phased out in favor of variant subsystem','NoScale',true);
            obj.minR                = SIM.parameter('Unit','m','Description','Minimum radius for spooling switching');
            obj.perpErrorVal        = SIM.parameter('Unit','rad','Description','Central angle at which we saturate the desired velocity to the tangent vector');
            obj.startControl        = SIM.parameter('Unit','s','Description','Time at which we switch the roll controller on');
            obj.outRanges           = SIM.parameter('Unit','','Description','Upper/lower limits of path variable for spooling');
            obj.elevatorConst       = SIM.parameter('Unit','deg','Description','Deflection angle of elevator used during spool in');
            obj.maxR                = SIM.parameter('Unit','m','Description','Maximum radius for spooling switching');
            obj.fcnName             = SIM.parameter('Unit','','Description','Name of the path shape function you want to use.','NoScale',true);
            obj.initPathVar         = SIM.parameter('Unit','','Description','Initial path variable');
            obj.firstSpoolLap       = SIM.parameter('Unit','','Description','First Lap to begin spooling');
            obj.rudderGain          = SIM.parameter('Value',1,'Unit','','Description','0 Turns off rudder');
            
            obj.RCtrl               = SIM.parameter('Value',1,'Unit','','Description','Flag to decide roll control. 0 = direct; 1 = ctrl allocation matrix');
            obj.AoACtrl             = SIM.parameter('Unit','','Description','Flag to decide AoA control. 0 = none; 1 = On');
            obj.AoASP               = SIM.parameter('Unit','','Description','Flag to decide AoA control. 0 = constant; 1 = time-lookup');
            obj.AoAConst            = SIM.parameter('Unit','deg','Description','Constant AoA setpoint');
            obj.AoAmin              = SIM.parameter('Unit','deg','Description','Minimum AoA setpoint');
            obj.RPMConst            = SIM.parameter('Unit','','Description','Constant RPM setpoint');
            obj.RPMmax              = SIM.parameter('Unit','','Description','Maximum RPM setpoint');
            obj.Tmax                = SIM.parameter('Unit','kN','Description','Maximum tether tension limit');
            obj.TmaxCtrl            = SIM.parameter('Unit','','Description','Tether tension limit selector');
            obj.optAltitude         = SIM.parameter('Unit','m','Description','Mean operating altitude');
            obj.startCtrl           = SIM.parameter('Unit','s','Description','Time to start periodic SP control');
            obj.period              = SIM.parameter('Unit','s','Description','Set Point Period');
            obj.rollAmp             = SIM.parameter('Unit','deg','Description','Roll Amplitude');
            obj.yawAmp              = SIM.parameter('Unit','deg','Description','Yaw Amplitdue');
            obj.trimElevator        = SIM.parameter('Unit','deg','Description','Elevator SP for trim flight');
            obj.ccElevator          = SIM.parameter('Unit','deg','Description','Elevator SP during CC flight');
            obj.rollPhase           = SIM.parameter('Unit','rad','Description','Roll Sinusoid Phase Offest');
            obj.yawPhase           = SIM.parameter('Unit','rad','Description','Yaw Sinusoid Phase Offest');
        end
        
        function setWinchSpeedIn(obj,val,unit)
            obj.winchSpeedIn.setValue(val,unit);
        end
        function setWinchSpeedOut(obj,val,unit)
            obj.winchSpeedOut.setValue(val,unit);
        end
        function setCtrlAllocMat(obj,val,unit)
            obj.ctrlAllocMat.setValue(val,unit);
        end
        function setSearchSize(obj,val,unit)
            obj.searchSize.setValue(val,unit);
        end
        function setFirstSpoolLap(obj,val,units)
            obj.firstSpoolLap.setValue(val,units)
        end
        function setTraditionalBool(obj,val,unit)
            obj.traditionalBool.setValue(val,unit);
        end
        function setMinR(obj,val,unit)
            obj.minR.setValue(val,unit);
        end
        function setPerpErrorVal(obj,val,unit)
            obj.perpErrorVal.setValue(val,unit);
        end
        function setStartControl(obj,val,unit)
            obj.startControl.setValue(val,unit);
        end
        function setOutRanges(obj,val,unit)
            obj.outRanges.setValue(val,unit);
        end
        function setElevatorConst(obj,val,unit)
            obj.elevatorConst.setValue(val,unit);
        end
        function setMaxR(obj,val,unit)
            obj.maxR.setValue(val,unit) ;
        end
        function setFcnName(obj,val,unit)
            obj.fcnName.setValue(val,unit);
        end
        
        function setInitPathVar(obj,initPosVecGnd,geomParams,pathCntPosVec)
            pathVars = linspace(0,1,1000);
            posVecs = eval(sprintf('%s(pathVars,geomParams,pathCntPosVec)',obj.fcnName.Value));
            initPosVecGnd = repmat(initPosVecGnd(:),[1 numel(pathVars)]);
            dist = sqrt(sum((initPosVecGnd- posVecs).^2,1));
            [~,idx] = min(dist);
            obj.initPathVar.setValue(pathVars(idx),'');
        end
        
        function obj = scale(obj,lengthScaleFactor,densityScaleFactor)

            props = getPropsByClass(obj,'CTR.sat');
            for ii = 1:numel(props)
                obj.(props{ii}).scale(lengthScaleFactor,densityScaleFactor);
            end
            props = getPropsByClass(obj,'SIM.parameter');
            for ii = 1:numel(props)
                obj.(props{ii}).scale(lengthScaleFactor,densityScaleFactor);
            end
            props = getPropsByClass(obj,'CTR.FPID');
            for ii = 1:numel(props)
                obj.(props{ii}).scale(lengthScaleFactor,densityScaleFactor);
            end
            props = getPropsByClass(obj,'CTR.PID');
            for ii = 1:numel(props)
                obj.(props{ii}).scale(lengthScaleFactor,densityScaleFactor);
            end
        end % end scale
       
        function val = get.frequency(obj)
            val = SIM.parameter('Value',1/obj.period.Value*2*pi,...
                'Unit','rad/s','Description','SP Oscillation Frequency');
        end
        
        val = getPropsByClass(obj,className)
        
        
    end
end

