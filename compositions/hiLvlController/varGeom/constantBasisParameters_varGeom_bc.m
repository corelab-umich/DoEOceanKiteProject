function constantBasisParameters_varGeom_bc()

% Creates output bus used by 
elems(1) = Simulink.BusElement;
elems(1).Name = 'basisParams';
try
elems(1).Dimensions = 5;
catch
end
elems(1).DimensionsMode = 'Fixed';
elems(1).DataType = 'double';
elems(1).SampleTime = -1;
elems(1).Complexity = 'real';
elems(1).Unit = '';

elems(2) = Simulink.BusElement;
elems(2).Name = 'state';
elems(2).Dimensions = 1;
elems(2).DimensionsMode = 'Fixed';
elems(2).DataType = 'double';
elems(2).SampleTime = -1;
elems(2).Complexity = 'real';
elems(2).Unit = '';

CONTROL = Simulink.Bus;
CONTROL.Elements = elems;
CONTROL.Description = 'Bus constant basis parameters';

assignin('base','hiLvlCtrlBus',CONTROL)

end