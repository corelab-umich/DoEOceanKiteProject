classdef KalmanFilteredGaussianProcess < GP.GaussianProcess
    % constructor properties
    properties (SetAccess = immutable)
        xMeasure
        kfgpTimeStep
    end
    
    % initialization properties
    properties
        initVals
        spatialCovMat
        spatialCovMatRoot
    end
    
    % application specific properties
    properties
        tetherLength
    end
    
    % MPC properties
    properties
        exploitationConstant
        explorationConstant
        predictionHorizon
        
    end
    
    %% constructor
    methods
        % constructor
        function obj = KalmanFilteredGaussianProcess(spatialKernel,...
                temporalKernel,meanFn,xMeasure,kfgpTimeStep)
            % call superclass constructor
            obj@GP.GaussianProcess(spatialKernel,temporalKernel,meanFn);
            % set class properties
            obj.xMeasure     = xMeasure;
            obj.kfgpTimeStep = kfgpTimeStep;
        end
    end
    
    %% initialization related methods
    methods
        % get set of initialization matrices required to run GPKF
        function val = initializeKFGP(obj)
            % switch cases
            if isequal(@ExponentialKernel,obj.temporalKernel)
                tempKernel = 'exponential';
            elseif isequal(@SquaredExponentialKernel,obj.temporalKernel)
                tempKernel = 'squaredExponential';
            end
            
            switch tempKernel
                case 'exponential'
                    val = initializeKFGPForExponentialKernel(obj);
                    
                case 'squaredExponential'
                    val = initializeKFGPForSquaredExponentialKernel(obj);
            end
            val.meanFnVec = obj.meanFunction(obj.xMeasure,...
                obj.meanFnProps(1),obj.meanFnProps(2));
            
        end
        
        % calculate square root of spatial covariance matrix
        function val = calcSpatialCovMatRoot(obj)
            val = sqrtm(obj.spatialCovMat);
        end
        
    end
    
    %% other methods
    methods
        function val = calcIndicatorMatrix(obj,xLoc)
            % local variables
            xM = obj.xMeasure;
            % preallocate
            val = zeros(1,size(xM,2));
            % find the first point below xLoc
            firstBelow = find(xLoc>=xM,1,'last');
            % find the first point above xLoc
            firstAbove = find(xLoc<=xM,1,'first');
            % distance between the two locations
            distBetween = norm(xM(firstBelow) - xM(firstAbove));
            if firstBelow ~= firstAbove
                % weighted average
                val(firstBelow) = norm(xM(firstAbove) - xLoc)/distBetween;
                val(firstAbove) = norm(xM(firstBelow) - xLoc)/distBetween;
            else
                val(firstBelow) = 1;
            end
            
        end
    end
    
    %% regression related methods
    methods
        % Kalman estimation as per jp Algorithm 1
        function [F_t,sigF_t,skp1_kp1,ckp1_kp1,varargout] = ...
                calcKalmanStateEstimates(obj,sk_k,ck_k,Mk,yk)
            % local variables
            xM    = obj.xMeasure;
            Ks_12 = obj.spatialCovMatRoot;
            Amat  = obj.initVals.Amat;
            Qmat  = obj.initVals.Qmat;
            Hmat  = obj.initVals.Hmat;
            % number of measurable points which is subset of xDomain
            xMeasureNP = size(xM,2);
            % number of points visited at each step which is a subset of xMeasure
            MkNP = size(Mk,2);
            % R matrix as per Carron conf. paper Eqn. (12)
            Rmat = eye(MkNP)*obj.noiseVariance;
            % indicator matrix to find which points are visited at each iteration
            Ik = zeros(MkNP,xMeasureNP);
            % populate the Ik matrix
            for ii = 1:MkNP
                Ik(ii,:) = obj.calcIndicatorMatrix(Mk(ii));
            end
            % C matrix as per Carron conf. paper Eqn. (12)
            Cmat = Ik*Ks_12*Hmat;
            % Kalman filter equations as per Carron conf. paper Eqn. (6)
            skp1_k = Amat*sk_k; % Eqn. (6a)
            ckp1_k = Amat*ck_k*Amat' + Qmat; % Eqn. (6b)
            Lkp1 = ckp1_k*Cmat'/(Cmat*ckp1_k*Cmat' + Rmat); % Eqn (6e)
            % set kalman gain to zero if yk is empty
            if isempty(yk)
                skp1_kp1 = skp1_k;
            else
                skp1_kp1 = skp1_k + Lkp1*(yk - Cmat*skp1_k); % Eqn (6c)
            end
            ckp1_kp1 = ckp1_k - Lkp1*Cmat*ckp1_k; % Eqn (6d)
            % process estimate and covariance as per Todescato algortihm 1
            F_t = Ks_12*Hmat*skp1_kp1; % Eqn. (13)
            sigF_t = Ks_12*Hmat*ckp1_kp1*Hmat'*Ks_12;
            % varibale outputs
            varargout{1} = Ik;
        end
        
        % Regression as per jp section 5
        function [predMean,postVar] = ...
                calcPredMeanAndPostVar(obj,xPredict,F_t,sigF_t)
            % number of points in the discretized domain
            noXM = size(obj.xMeasure,2);
            % number of points over which we want to acquire predictions
            noXP = size(xPredict,2);
            % Regression as per section 5 of Todescato journal paper
            % preallocate matrices
            mXstar   = NaN(noXP,1);
            % pre-allocate matrices
            kx_xstar     = NaN(noXM,noXP);
            kxstar_xstar = NaN(noXP,1);
            % perform regression on each point in the domain
            for ii = 1:noXP
                for jj = 1:noXM
                    kx_xstar(jj,ii) = obj.calcSpatialCovariance(...
                        xPredict(:,ii),obj.xMeasure(:,jj));
                end
                kxstar_xstar(ii) = obj.calcSpatialCovariance(...
                    xPredict(:,ii),xPredict(:,ii));
                mXstar(ii) = obj.meanFunction(xPredict(:,ii),...
                    obj.meanFnProps(1),obj.meanFnProps(2));
                
            end
            % local variables to minimie matrix inverse
            Ky = obj.spatialCovMat;
            kInvK = kx_xstar'/Ky;
            predMean = kInvK*F_t;
            postVar  = kxstar_xstar - ...
                diag(kInvK*(eye(noXM)*kx_xstar - sigF_t*kInvK'));
        end
        
        
    end
    
    %% optimization related methods
    methods
        % calculate aquistion function
        function [val,varargout] = calcAquisitionFunction(obj,meanElevation,F_t,sigF_t)
            % convert elevation angle to altitude
            xPredict = obj.convertMeanElevToAlt(meanElevation);
            % calculate prediction mean and posterior variance
            [flowPred,flowVar] = obj.calcPredMeanAndPostVar(xPredict,F_t,sigF_t);
            flowPred = obj.meanFunction(xPredict,obj.meanFnProps(1),...
                obj.meanFnProps(2)) - flowPred;
            % exploitation incentive
            jExploit = obj.exploitationConstant*...
                cosineFlowCubed(flowPred,cosd(meanElevation));
            % exploration incentive
            jExplore = obj.explorationConstant*flowVar.^(3/2);
            % sum
            val = jExploit + jExplore;
            % other outputs
            varargout{1} = jExploit;
            varargout{2} = jExplore;
        end
        
        % calculate MPC objective function
        function [val,varargout] = ...
                calcMpcObjectiveFn(obj,F_t,sigF_t,skp1_kp1,ckp1_kp1,meanElevTraject)
            % local variables
            predHorz = obj.predictionHorizon;
            Mk       = nan(1,predHorz);
            aqVal    = nan(1,predHorz);
            jExploit = nan(1,predHorz);
            jExplore = nan(1,predHorz);
            % calculate acquisition function at each mean elevation angle
            for ii = 1:predHorz
                % calculate acquistion function
                [aqVal(ii),jExploit(ii),jExplore(ii)] = ...
                    obj.calcAquisitionFunction(meanElevTraject(ii),F_t,sigF_t);
                % update kalman states
                sk_k = skp1_kp1;
                ck_k = ckp1_kp1;
                % update current altitude
                Mk(ii) = obj.convertMeanElevToAlt(meanElevTraject(ii));
                % perform kalman state estimation
                [F_t,sigF_t,skp1_kp1,ckp1_kp1] = ...
                    obj.calcKalmanStateEstimates(sk_k,ck_k,Mk(ii),...
                    []);
                
            end
            % mpc objective function val
            val = sum(aqVal);
            varargout{1} = jExploit;
            varargout{2} = jExplore;
            
        end
        
        % convert mean elevation angle to altitude
        function val = convertMeanElevToAlt(obj,meanElevation)
            val = obj.tetherLength*sind(meanElevation);
        end
        
        % calculate dMeanElev given trajectory
        function val = calcDelevTraj(~,e0,eTraj)
            eTraj = eTraj(:);
            val = eTraj - [e0;eTraj(1:end-1)];
        end
        
    end
    %% altitude optimization methods
    methods
        % calculate aquistion function for altitude optimization
        function [val,varargout] = calcAquisitionFunctionForAltOpt(obj,...
                altitude,F_t,sigF_t,hiLvlCtrl)
            % calculate prediction mean and posterior variance
            [flowPred,flowVar] = obj.calcPredMeanAndPostVar(altitude,F_t,sigF_t);
            flowPred = obj.meanFunction(altitude,obj.meanFnProps(1),...
                obj.meanFnProps(2)) - flowPred;
            % extract constants from power function
            c0 =  hiLvlCtrl.powerFunc.c0;
            c1 =  hiLvlCtrl.powerFunc.c1;
            % calculate standard deviation
            sig = real(sqrt(flowVar));
            % estimate power statistics
            expP = hiLvlCtrl.expectedPow(c0,c1,flowPred,sig,altitude);
            varP = hiLvlCtrl.VariancePow(c0,c1,flowPred,sig,altitude);
            % exploitation incentive
            jExploit = obj.exploitationConstant*expP;
            % exploration incentive
            jExplore = obj.explorationConstant*varP.^(1/2);
            % imaginary line beyond which kite doesn't fly
            imagLine = @(x) -750 + (700/4)*x;
            % penalty for crossing said line
            penalty = -0.0*(max(0,imagLine(flowPred)-altitude));
            % sum
            val = jExploit + jExplore + penalty;
            % other outputs
            varargout{1} = jExploit;
            varargout{2} = jExplore;
            varargout{3} = flowPred;
            
        end
        
        % calculate MPC objective function for altitude optimization
        function [val,varargout] = ...
                calcMpcObjectiveFnForAltOpt(obj,F_t,sigF_t,skp1_kp1,...
                ckp1_kp1,altTraj,hiLvlCtrl)
            % local variables
            predHorz = obj.predictionHorizon;
            aqVal    = nan(1,predHorz);
            jExploit = nan(1,predHorz);
            jExplore = nan(1,predHorz);
            flowPred = nan(1,predHorz);
            % calculate acquisition function at each mean elevation angle
            for ii = 1:predHorz
                % calculate acquistion function
                [aqVal(ii),jExploit(ii),jExplore(ii),flowPred(ii)] = ...
                    obj.calcAquisitionFunctionForAltOpt(altTraj(ii),F_t,sigF_t,...
                    hiLvlCtrl);
                % update kalman states
                sk_k = skp1_kp1;
                ck_k = ckp1_kp1;
                % perform kalman state estimation
                [F_t,sigF_t,skp1_kp1,ckp1_kp1] = ...
                    obj.calcKalmanStateEstimates(sk_k,ck_k,altTraj(ii),[]);
                
            end
            % mpc objective function val
            val = sum(aqVal);
            varargout{1} = jExploit;
            varargout{2} = jExplore;
            varargout{3} = flowPred;
        end        
    end
    
    %% tether length and elevation angle optimization methods
    methods
        
        % calculate MPC objective function for altitude optimization
        function [val,varargout] = ...
                calcMpcObjectiveFnThrLengthAndElvOpt(obj,F_t,sigF_t,skp1_kp1,...
                ckp1_kp1,LthrSP,elevSP,Lthr,elev,dLdT,hiLvlCtrl)
            % prediction horizon
            predHorz = obj.predictionHorizon;
            % imaginary line beyond which kite doesn't fly
            imagLine = @(x) -750 + (700/4)*x;
            % separate spooling and elevation rates
            dL = dLdT(1:predHorz);
            dT = dLdT(predHorz+1:end);
            % local variables
            LthrTraj = nan(predHorz,1);
            elevTraj = nan(predHorz,1);
            % changes in tether length and elevation angle
            LthrChanged = dL*obj.kfgpTimeStep*60;
            elevChanged = dT*obj.kfgpTimeStep*60;
            % dynamics
            LthrTraj(1) = Lthr + LthrChanged(1);
            elevTraj(1) = elev + elevChanged(1);
            for ii = 2:predHorz
                LthrTraj(ii) = LthrTraj(ii-1) + LthrChanged(ii);
                elevTraj(ii) = elevTraj(ii-1) + elevChanged(ii);                
            end
            % altitude trajectory
            zTraj = LthrTraj.*sind(elevTraj);
            % preallocate
            powTraj   = nan(predHorz,1);
            flowPred  = nan(predHorz,1);
            % calculate acquisition function at each mean elevation angle
            for ii = 1:predHorz
                % calculate flow predictions
                [flowPred(ii),~] = ...
                calcPredMeanAndPostVar(obj,zTraj(ii),F_t,sigF_t);
                % correct flow prediction
                flowPred(ii) = obj.meanFunction(zTraj(ii),obj.meanFnProps(1),...
                    obj.meanFnProps(2)) - flowPred(ii);
                % calculate power estimate
                powTraj(ii) = 0*hiLvlCtrl.midLvlCtrl.pFunc(LthrTraj(ii),...
                    flowPred(ii),elevTraj(ii)*pi/180);
                if isnan(powTraj(ii))
                    powTraj(ii) = -norm(imagLine(zTraj(ii))-zTraj(ii));
                end
                % update kalman states
                sk_k = skp1_kp1;
                ck_k = ckp1_kp1;
                % perform kalman state estimation
                [F_t,sigF_t,skp1_kp1,ckp1_kp1] = ...
                    obj.calcKalmanStateEstimates(sk_k,ck_k,zTraj(ii),[]);
                
            end
            % calculate terminal penalties
            LthrPen = -hiLvlCtrl.midLvlCtrl.LthrPenaltyWeight*norm(LthrSP - LthrTraj(end));
            elevPen = -hiLvlCtrl.midLvlCtrl.TPenaltyWeight*norm(elevSP - elevTraj(end));
            % mpc objective function val
            val = sum(powTraj) + LthrPen + elevPen;
            varargout{1} = powTraj;
            varargout{2} = LthrTraj;
            varargout{3} = elevTraj;
        end
        
    end
    
       
    %% brute force trajectory optizimation
    methods
        % optimize mean elevation angle trajectory using brute force
        function [val,varargout] = ...
                bruteForceTrajectoryOpt(obj,F_t,sigF_t,skp1_kp1,ckp1_kp1,...
                meanElev,uAllowable,lb,ub)
            % local variables
            predHorz = obj.predictionHorizon;
            % create all allowable state and control trajectories
            [meanElevTraj,uTraj] = ...
                makeBruteForceStateTrajectories(uAllowable,predHorz,...
                meanElev,lb,ub);
            % number of allowable trajectories
            nAllowed = size(meanElevTraj,1);
            % calculate acquistion function for each trajectory
            mpcAqFunc = nan(nAllowed,1);
            for ii = 1:nAllowed
                mpcAqFunc(ii) = ...
                    obj.calcMpcObjectiveFn(F_t,sigF_t,skp1_kp1,ckp1_kp1,...
                    meanElevTraj(ii,:));
            end
            [~,maxIdx] = max(mpcAqFunc);
            val = meanElevTraj(maxIdx,:);
            varargout{1} = uTraj(maxIdx,:);
            
        end
        
    end
    
end