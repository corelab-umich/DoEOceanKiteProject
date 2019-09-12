function animateSim(obj,tsc,timeStep,varargin)
%ANIMATESIM Method to animate a simulation using the provided timeseries

%% Input parsing
p = inputParser;


% ---Fundamental Animation Requirements---
% Timeseries collection structure with results from the simulation
addRequired(p,'tsc',@isstruct);
% Time step used in plotting
addRequired(p,'timeStep',@isnumeric);


% ---Parameters for saving a gif---
% Switch to enable saving 0 = don't save
addParameter(p,'SaveGif',false,@islogical)
% Path to saved file, default is ./output
addParameter(p,'GifPath',fullfile(fileparts(which('OCTProject.prj')),'output'));
% Name of saved file, default is animation.gif
addParameter(p,'GifFile','animation.gif');
% Time step between frames of gif, default is time step (real time plot)
addParameter(p,'GifTimeStep',timeStep,@isnumeric)

% ---Parameters to save MPEG (NOT CURRENTLY IMPLEMENTED)---
addParameter(p,'SaveMPEG',false,@islogical) % Boolean switch to save a MPEG
addParameter(p,'MPEGPath',fullfile(fileparts(which('OCTProject.prj')),'output'));
addParameter(p,'MPEGFile','animation.gif');

% ---Plot Features---
% Name of the path geometry used 
addParameter(p,'PathFunc',[],@ischar);
% Plot ground coordinate system axes
addParameter(p,'PlotAxes',true,@islogical);
% Set camera view angle [azimuth, elevation]
addParameter(p,'View',[71,22],@isnumeric)
% Set font size
addParameter(p,'FontSize',get(0,'defaultAxesFontSize'),@isnumeric)
% Tracer (streaming red line behind the model)
addParameter(p,'PlotTracer',true,@islogical)
% How long (in seconds) to keep the tracer on for
addParameter(p,'TracerDuration',5,@isnumeric)
% Plot a red dot on the closest point on the path
addParameter(p,'PathPosition',false,@islogical)
% Plot normal, tangent and desired vectors
addParameter(p,'NavigationVecs',false,@islogical)
% Plot local aerodynamic force vectors on surfaces
addParameter(p,'LocalAero',false,@islogical)
% Add resulting net moment in the body frame to the table readout
addParameter(p,'FluidMoments',false,@islogical)
% Pause after each plot update (to go frame by frame)
addParameter(p,'Pause',false,@islogical)
% Zoom in the plot axes to focus on the body
addParameter(p,'ZoomIn',false,@islogical)

% ---Parse the output---
parse(p,tsc,timeStep,varargin{:})


%% Setup some infrastructure type things
% If the user wants to save something and the specified directory does not
% exist, create it
if p.Results.SaveGif && ~exist(p.Results.GifPath, 'dir')
    mkdir(p.Results.GifPath)
end
if p.Results.SaveMPEG && ~exist(p.Results.MPEGPath, 'dir')
    mkdir(p.Results.MPEGPath)
end
% Resample the timeseries to the specified framerate
tsc = resampleTSC(tsc,p.Results.timeStep);


%% Plot things
% Plot the aerodynamic surfaces
h = obj.plot('Basic',true);

% Get the "nominal" positions of the aerodynamic surfaces from that plot
for ii = 1:length(h.surf)
    hStatic{ii}.x = h.surf{ii}.XData;
    hStatic{ii}.y = h.surf{ii}.YData;
    hStatic{ii}.z = h.surf{ii}.ZData;
end
hold on

% Plot x, y and z ground fixed axes
if p.Results.PlotAxes
    posData = squeeze(tsc.positionVec.Data)';
    r = sqrt(sum(posData.^2,2));
    len = 0.1*max(r);
    plot3([0 len],[0 0],[0 0],...
        'Color','r','LineStyle','-');
    plot3([0 0],[0 len],[0 0],...
        'Color','g','LineStyle','-');
    plot3([0 0],[0 0],[0 len],...
        'Color','b','LineStyle','-');
end

% Plot the tracer (empty/NAN's)
if p.Results.PlotTracer
    h.tracer = plot3(...
        nan([round(p.Results.TracerDuration/p.Results.timeStep) 1]),...
        nan([round(p.Results.TracerDuration/p.Results.timeStep) 1]),...
        nan([round(p.Results.TracerDuration/p.Results.timeStep) 1]),...
        'Color','r','LineStyle','-','LineWidth',1.5);
end

% Plot the path
if ~isempty(p.Results.PathFunc)
    path = eval(sprintf('%s(linspace(0,1,1000),tsc.basisParams.Data(:,:,1))',...
        p.Results.PathFunc));
    h.path = plot3(...
        path(1,:),...
        path(2,:),...
        path(3,:),...
        'LineStyle','-','Color','k');
end

% Plot current path position
if p.Results.PathPosition
    pt = eval(sprintf('%s(tsc.currentPathVar.Data(1),tsc.basisParams.Data(:,:,1))',...
        p.Results.PathFunc));
    h.pathPosition = plot3(pt(1),pt(2),pt(3),'ro');
end

% Plot navigation vectors
if p.Results.NavigationVecs
    posData = squeeze(tsc.positionVec.Data)';
    r = sqrt(sum(posData.^2,2));
    len = 0.1*max(r);
    pathPt = eval(sprintf('%s(tsc.currentPathVar.Data(1),tsc.basisParams.Data(:,:,1))',...
        p.Results.PathFunc));
    h.tanVec = quiver3(...
        pathPt(1),pathPt(2),pathPt(3),...
        len*tsc.tanVec.Data(1,1),...
        len*tsc.tanVec.Data(1,2),...
        len*tsc.tanVec.Data(1,3),...
        'MaxHeadSize',0,'Color','r','LineStyle','-');
    h.perpVec = quiver3(...
        posData(1,1),posData(1,2),posData(1,3),...
        len*tsc.perpVec.Data(1,1,1),...
        len*tsc.perpVec.Data(2,1,1),...
        len*tsc.perpVec.Data(3,1,1),...
        'MaxHeadSize',0,'Color','g','LineStyle','-');
    h.desVec = quiver3(...
        posData(1,1),posData(1,2),posData(1,3),...
        len*tsc.velVectorDes.Data(1,1),...
        len*tsc.velVectorDes.Data(1,2),...
        len*tsc.velVectorDes.Data(1,3),...
        'MaxHeadSize',0,'Color','b','LineStyle','-');
end

% Create a table
if p.Results.LocalAero || p.Results.FluidMoments
    h.table = uitable(h.fig,'Units','Normalized','FontSize',16,...
        'Position',[0.0099    0.0197    0.2880    0.9668],...
        'ColumnWidth','auto',...
        'ColumnName',{'Description','Value'},...
        'ColumnWidth',{150,200});
end

% Set the plot limits to zoom in on the body
if p.Results.ZoomIn
    xlim(tsc.positionVec.Data(1,:,1)+obj.fuse.length.Value*[-1.5 1.5])
    ylim(tsc.positionVec.Data(2,:,1)+obj.fuse.length.Value*[-1.5 1.5])
    zlim(tsc.positionVec.Data(3,:,1)+obj.fuse.length.Value*[-1.5 1.5])
end

% Plot local aerodynamic force vectors
if p.Results.LocalAero
    % Get the surface names
    [aeroStruct,surfNames] = obj.struct('OCT.aeroSurf');
    
    % Get the aerodynamic vectors in the ground frames
    FLiftPart = rotation_sequence(tsc.eulerAngles.Data(:,:,1))*tsc.FLiftBdyPart.Data(:,:,1);
    FDragPart = rotation_sequence(tsc.eulerAngles.Data(:,:,1))*tsc.FDragBdyPart.Data(:,:,1);
    vAppPart  = rotation_sequence(tsc.eulerAngles.Data(:,:,1))*tsc.vAppLclBdy.Data(:,:,1);
    
    % Normalize them for plotting purposes
    uLiftPart = FLiftPart./sqrt(sum(FLiftPart.^2,1));
    uDragPart = FDragPart./sqrt(sum(FDragPart.^2,1));
    uAppPart = vAppPart./sqrt(sum(vAppPart.^2,1));
   
    % Plot the vectors on each surface
    for ii = 1:numel(surfNames)
        % Update the table
        h.table.Data = [h.table.Data;...
            {surfNames{ii}},{''};...
            {'V App'} ,{sprintf('%0.2f',sqrt(sum(vAppPart(ii).^2,1)))};...
            {'F Lift'},{sprintf('%0.0f',sqrt(sum(FLiftPart(ii).^2,1)))};...
            {'F Drag'},{sprintf('%0.0f',sqrt(sum(FDragPart(ii).^2,1)))}];
        
        % Calculate the position of the aerodynamic center
        aeroCentVec = tsc.positionVec.Data(:,:,1)+...
            rotation_sequence(tsc.eulerAngles.Data(:,:,1))*aeroStruct(ii).aeroCentPosVec(:);
        
        % Plot the vectors
        h.liftVecs(ii) = quiver3(...
            aeroCentVec(1),...
            aeroCentVec(2),...
            aeroCentVec(3),...
            uLiftPart(1,ii),...
            uLiftPart(2,ii),...
            uLiftPart(3,ii),...
            'Color','g','LineWidth',1.5,'LineStyle','-');
        h.dragVecs(ii) = quiver3(...
            aeroCentVec(1),...
            aeroCentVec(2),...
            aeroCentVec(3),...
            uDragPart(1,ii),...
            uDragPart(2,ii),...
            uDragPart(3,ii),...
            'Color','r','LineWidth',1.5,'LineStyle','-');
        h.vAppVecs(ii) = quiver3(...
            aeroCentVec(1),...
            aeroCentVec(2),...
            aeroCentVec(3),...
            -uAppPart(1,ii),...
            -uAppPart(2,ii),...
            -uAppPart(3,ii),...
            'Color','b','LineWidth',1.5,'LineStyle','-');
    end
end

% Put the fluid dynamic moments in the table
if p.Results.FluidMoments
    fluidStartRow = size(h.table.Data,1);
    h.table.Data = [h.table.Data;
        {'M Fluid Roll'} ,{sprintf('%0.0f',tsc.MFluidBdy.Data(1,1,1))};...
        {'M Fluid Pitch'},{sprintf('%0.0f',tsc.MFluidBdy.Data(2,1,1))};...
        {'M Fluid Yaw'}  ,{sprintf('%0.0f',tsc.MFluidBdy.Data(3,1,1))}];
end

% Plot the tethers
for ii = 1:numel(tsc.thrNodeBus)
    h.thr{ii} = plot3(...
        squeeze(tsc.thrNodeBus.nodePositions.Data(1,:,1)),...
        squeeze(tsc.thrNodeBus.nodePositions.Data(2,:,1)),...
        squeeze(tsc.thrNodeBus.nodePositions.Data(3,:,1)),...
        'Color','k','LineWidth',1.5,'LineStyle','-','Marker','o');
end

% Set the font size
set(gca,'FontSize',p.Results.FontSize);

% Set the viewpoint
view(p.Results.View)

% Set plot limits
setLimsToQuartSphere(gca,squeeze(tsc.positionVec.Data)',...
    'PlotAxes',true);

% Set data aspect ratio to realistic (not skewed)
daspect([1 1 1])

% Create a title
h.title = title({sprintf('Time = %.1f s',0),...
    sprintf('Speed = %.1f m/s',norm(tsc.velocityVec.Data(:,:,1)))});

% Update the graphics handles with new data
for ii = 1:length(tsc.eulerAngles.Time)
    for jj = 1:numel(hStatic)
        % Rotate and translate all aero surfaces
        pts = rotation_sequence(tsc.eulerAngles.Data(:,:,ii))*[...
            hStatic{jj}.x(:)';...
            hStatic{jj}.y(:)';...
            hStatic{jj}.z(:)']+...
            tsc.positionVec.Data(:,:,ii);
        % Update the OCT outline
        h.surf{jj}.XData = pts(1,:);
        h.surf{jj}.YData = pts(2,:);
        h.surf{jj}.ZData = pts(3,:);
    end
    % Update the tracer
    if p.Results.PlotTracer
        h.tracer.XData = [h.tracer.XData(2:end) tsc.positionVec.Data(1,:,ii)];
        h.tracer.YData = [h.tracer.YData(2:end) tsc.positionVec.Data(2,:,ii)];
        h.tracer.ZData = [h.tracer.ZData(2:end) tsc.positionVec.Data(3,:,ii)];
    end
    
    % Update the path
    if ~isempty(p.Results.PathFunc)
        currentBasisParams = tsc.basisParams.Data(:,:,ii);
        currentBasisParams(end) = norm(tsc.positionVec.Data(:,1,ii)) ;
        path = eval(sprintf('%s(linspace(0,1,1000),currentBasisParams)',...
            p.Results.PathFunc));
        h.path.XData = path(1,:);
        h.path.YData = path(2,:);
        h.path.ZData = path(3,:);
    end
    
    % Update current path position
    if p.Results.PathPosition
        currentBasisParams = tsc.basisParams.Data(:,:,ii);
        currentBasisParams(end) = norm(tsc.positionVec.Data(:,1,ii)) ;
        pt = eval(sprintf('%s(tsc.currentPathVar.Data(ii),currentBasisParams)',...
            p.Results.PathFunc));
        h.pathPosition.XData = pt(1);
        h.pathPosition.YData = pt(2);
        h.pathPosition.ZData = pt(3);
    end
    
    % Update navigation vectors
    if p.Results.NavigationVecs
        pathPt = eval(sprintf('%s(tsc.currentPathVar.Data(ii),tsc.basisParams.Data(:,:,ii))',...
            p.Results.PathFunc));
        
        h.tanVec.XData = pathPt(1);
        h.tanVec.YData = pathPt(2);
        h.tanVec.ZData = pathPt(3);
        h.tanVec.UData = len*tsc.tanVec.Data(ii,1);
        h.tanVec.VData = len*tsc.tanVec.Data(ii,2);
        h.tanVec.WData = len*tsc.tanVec.Data(ii,3);
        
        h.perpVec.XData = tsc.positionVec.Data(1,:,ii);
        h.perpVec.YData = tsc.positionVec.Data(2,:,ii);
        h.perpVec.ZData = tsc.positionVec.Data(3,:,ii);
        h.perpVec.UData = len*tsc.perpVec.Data(ii,1);
        h.perpVec.VData = len*tsc.perpVec.Data(ii,2);
        h.perpVec.WData = len*tsc.perpVec.Data(ii,3);
        
        h.desVec.XData = tsc.positionVec.Data(1,:,ii);
        h.desVec.YData = tsc.positionVec.Data(2,:,ii);
        h.desVec.ZData = tsc.positionVec.Data(3,:,ii);
        h.desVec.UData = len*tsc.velVectorDes.Data(ii,1);
        h.desVec.VData = len*tsc.velVectorDes.Data(ii,2);
        h.desVec.WData = len*tsc.velVectorDes.Data(ii,3);
    end
    
    % Update local aerodynamic force vectors
    if p.Results.LocalAero
        aeroStruct = obj.struct('OCT.aeroSurf');
        
        FLiftPart = rotation_sequence(tsc.eulerAngles.Data(:,:,ii))*tsc.FLiftBdyPart.Data(:,:,ii);
        FDragPart = rotation_sequence(tsc.eulerAngles.Data(:,:,ii))*tsc.FDragBdyPart.Data(:,:,ii);
        vAppPart  = rotation_sequence(tsc.eulerAngles.Data(:,:,ii))*tsc.vAppLclBdy.Data(:,:,ii);
        
        uLiftPart = FLiftPart./sqrt(sum(FLiftPart.^2,1));
        uDragPart = FDragPart./sqrt(sum(FDragPart.^2,1));
        uAppPart  = vAppPart./sqrt(sum(vAppPart.^2,1));
        
        for jj = 1:numel(aeroStruct)
            h.table.Data{4*jj-2,2} = sprintf('%0.2f',sqrt(sum(vAppPart(jj).^2,1)));
            h.table.Data{4*jj-1,2} = sprintf('%0.0f',sqrt(sum(FLiftPart(jj).^2,1)));
            h.table.Data{4*jj+0,2} = sprintf('%0.0f',sqrt(sum(FDragPart(jj).^2,1)));
            
            aeroCentVec = tsc.positionVec.Data(:,:,ii)+...
                rotation_sequence(tsc.eulerAngles.Data(:,:,ii))*aeroStruct(jj).aeroCentPosVec(:);

            h.liftVecs(jj).XData = aeroCentVec(1);
            h.liftVecs(jj).YData = aeroCentVec(2);
            h.liftVecs(jj).ZData = aeroCentVec(3);
            h.liftVecs(jj).UData = uLiftPart(1,jj);
            h.liftVecs(jj).VData = uLiftPart(2,jj);
            h.liftVecs(jj).WData = uLiftPart(3,jj);
            
            h.dragVecs(jj).XData = aeroCentVec(1);
            h.dragVecs(jj).YData = aeroCentVec(2);
            h.dragVecs(jj).ZData = aeroCentVec(3);
            h.dragVecs(jj).UData = uDragPart(1,jj);
            h.dragVecs(jj).VData = uDragPart(2,jj);
            h.dragVecs(jj).WData = uDragPart(3,jj);
            
            h.vAppVecs(jj).XData = aeroCentVec(1);
            h.vAppVecs(jj).YData = aeroCentVec(2);
            h.vAppVecs(jj).ZData = aeroCentVec(3);
            h.vAppVecs(jj).UData = -uAppPart(1,jj);
            h.vAppVecs(jj).VData = -uAppPart(2,jj);
            h.vAppVecs(jj).WData = -uAppPart(3,jj);
        end
    end
    
    % Update moments in the table
    if p.Results.FluidMoments
        h.table.Data{fluidStartRow+1,2} = sprintf('%0.0f',tsc.MFluidBdy.Data(1,1,ii));
        h.table.Data{fluidStartRow+2,2} = sprintf('%0.0f',tsc.MFluidBdy.Data(2,1,ii));
        h.table.Data{fluidStartRow+3,2} = sprintf('%0.0f',tsc.MFluidBdy.Data(3,1,ii));
    end
    
    % Update the tethers
    for jj = numel(tsc.thrNodeBus)
        h.thr{jj}.XData = squeeze(tsc.thrNodeBus.nodePositions.Data(1,:,ii));
        h.thr{jj}.YData = squeeze(tsc.thrNodeBus.nodePositions.Data(2,:,ii));
        h.thr{jj}.ZData = squeeze(tsc.thrNodeBus.nodePositions.Data(3,:,ii));
    end
    % Update the title
    h.title.String = {sprintf('Time = %.1f s',tsc.velocityVec.Time(ii)),...
        sprintf('Speed = %.1f m/s',norm(tsc.velocityVec.Data(:,:,ii)))};
    
    % Set the plot limits to zoom in on the body
    if p.Results.ZoomIn
        xlim(tsc.positionVec.Data(1,:,ii)+obj.fuse.length.Value*[-1.5 1.5])
        ylim(tsc.positionVec.Data(2,:,ii)+obj.fuse.length.Value*[-1.5 1.5])
        zlim(tsc.positionVec.Data(3,:,ii)+obj.fuse.length.Value*[-1.5 1.5])
    end
    
    drawnow
    
    % Save gif of results
    if p.Results.SaveGif
        frame = getframe(h.fig);
        im = frame2im(frame);
        [imind,cm] = rgb2ind(im,256);
        if ii == 1
            imwrite(imind,cm,fullfile(p.Results.GifPath,p.Results.GifFile),'gif', 'Loopcount',inf);
        else
            imwrite(imind,cm,fullfile(p.Results.GifPath,p.Results.GifFile),'gif','WriteMode','append','DelayTime',p.Results.GifTimeStep)
        end
    end


    if p.Results.Pause
        pause
    end
end

end

