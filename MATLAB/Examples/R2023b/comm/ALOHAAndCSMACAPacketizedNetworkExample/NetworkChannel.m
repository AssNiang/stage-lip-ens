classdef NetworkChannel < matlab.System
%

%   Copyright 2017-2020 The MathWorks, Inc.                     
                     
properties (Nontunable)
    %SampleRateSource Sample rate source
    SampleRateSource = 'Property'
    %SampleRate Sample rate (Hz)
    %   Specify the sample rate of the input signal in Hz as a double
    %   precision, real, positive scalar. The default value of this
    %   property is 1 Hz.
    SAMPLERATE = [1E3, 2E3, 3E3];
    %PathDelays Discrete path delays (s)
    %   Specify the delays of the discrete paths in seconds as a double
    %   precision, real, scalar or row vector. When PathDelays is a scalar,
    %   the channel is frequency-flat; When PathDelays is a vector, the
    %   channel is frequency-selective. The default value of this property
    %   is 0.
    PathDelays = {[0 1 2]/1e3 [0 3.2 3.6 5.3 9.6]/1e3; ...
        [0 1 2]/1e3 [0 3.2 3.6 5.3 9.6]/1e3; ...
        [0 1 2]/1e3 [0 3.2 3.6 5.3 9.6]/1e3};
    %AveragePathGains Average path gains (dB)
    %   Specify the average gains of the discrete paths in dB as a double
    %   precision, real, scalar or row vector. AveragePathGains must have
    %   the same size as PathDelays. The default value of this property is
    %   0.
    AveragePathGains = {zeros(1, 3), zeros(1, 5); ...
        zeros(1, 3), zeros(1, 5); zeros(1, 3), zeros(1, 5)};
    %MaximumDopplerShift Maximum Doppler shift (Hz)
    %   Specify the maximum Doppler shift for the path(s) of the channel in
    %   Hz as a double precision, real, nonnegative scalar. It applies to
    %   all the paths of the channel. When MaximumDopplerShift is 0, the
    %   channel is static for the entire input and you can use the reset
    %   method to generate a new channel realization. The
    %   MaximumDopplerShift must be smaller than SampleRate/10/fc for each
    %   path, where fc is the cutoff frequency factor of the path. For a
    %   Doppler spectrum type other than Gaussian and BiGaussian, the value
    %   of fc is 1; Otherwise, the value of fc is dependent on the Doppler
    %   spectrum structure fields. Refer to the documentation of this
    %   System object for more details about how fc is defined. The default
    %   value of this property is 0.001.
    MaximumDopplerShift = [10, 20; 20 30; 30 40];
end

properties(Constant, Hidden)
    SampleRateSourceSet = matlab.system.StringSet({ ...
        'Property','Input port'});    
end

properties (Access = private, Nontunable)
    pNumNodes
end

properties (Access = private)
    pChannels
end

methods
  function obj = NetworkChannel(varargin) % Constructor
    coder.allowpcode('plain');
    setProperties(obj, nargin, varargin{:});
  end  
end

methods(Access = protected)
  function validatePropertiesImpl(obj)
    coder.internal.errorIf( ...
        any(size(obj.PathDelays) ~= size(obj.AveragePathGains)), ... 
        'comm:examples:SizeMismatch');
    coder.internal.errorIf( ...
        any(size(obj.PathDelays) ~= size(obj.MaximumDopplerShift)), ... 
        'comm:examples:SizeMismatch');
    coder.internal.errorIf( ...
        strcmp(obj.SampleRate, 'Property') && ...
        any((size(obj.PathDelays, 1) ~= length(obj.SampleRate))), ... 
        'comm:examples:SampleRateSizeMismatch');
  end

  function setupImpl(obj, ~)
    numNodes = size(obj.PathDelays, 1);
    
    if (getExecPlatformIndex(obj) == 1) && ...
        strcmp(obj.SampleRateSource, 'Input port') % Simulink
        % Use maximum input dimension instead of runtime input dimension to
        % calculate the sample rate. And only in this way codegen works.
        inDim = propagatedInputSize(obj, 1);
        sts = getSampleTime(obj);
        Rs = repmat(inDim(1)/sts.SampleTime, 1, numNodes);
    else
        Rs = obj.SampleRate;
    end
    
    obj.pNumNodes = numNodes;    
    obj.pChannels = cell(obj.pNumNodes, obj.pNumNodes - 1);
    for i = coder.unroll(1:numNodes)
        for j = coder.unroll(1:numNodes - 1)
            obj.pChannels{i, j} = comm.RayleighChannel( ...
                'SampleRate', Rs(i), ...
                'PathDelays', obj.PathDelays{i, j}, ...
                'AveragePathGains', obj.AveragePathGains{i, j}, ...
                'MaximumDopplerShift', obj.MaximumDopplerShift(i, j), ...
                'NormalizePathGains', false, ...
                'RandomStream', 'mt19937ar with seed', ...
                'Seed', 73);
        end        
    end
  end
  
  function resetImpl(obj)    
    for i = 1:numel(obj.pChannels)
        obj.pChannels{i}.reset;
    end
  end    
  
  function y = stepImpl(obj, x)
    numNodes = obj.pNumNodes;
    y = complex(zeros(size(x)));
    for rx = coder.unroll(1:numNodes)
        for tx = coder.unroll(1:numNodes)
            if tx < rx
                y(:,rx) = y(:,rx) + ... %x(:, tx); %...
                   step(obj.pChannels{tx, rx-1}, x(:, tx));
                  
            elseif tx > rx
                y(:,rx) = y(:,rx) + ...%x(:, tx);% + ...
                    step(obj.pChannels{tx, rx}, x(:, tx));
                  
            end
        end
    end
  end
  
  function releaseImpl(obj)
    for i = 1:numel(obj.pChannels)
        obj.pChannels{i}.release;
    end
  end
  
  function flag = isInactivePropertyImpl(obj, prop)
    flag = strcmp(prop, 'SampleRate') && ...
        strcmp(obj.SampleRateSource, 'Input port');
  end
  
  function varargout = getInputNamesImpl(~)
    varargout = {''};
  end
  
  function varargout = getOutputNamesImpl(~)
    varargout = {''}; 
  end
  
  function icon = getIconImpl(~)
    icon = sprintf('Network\nChannel');
  end  
      
  function num = getNumOutputsImpl(~)
    num = 1;
  end    
  
  function varargout = isOutputFixedSizeImpl(~)
    varargout = {true};
  end
  
  function varargout = getOutputSizeImpl(obj)
    varargout = {propagatedInputSize(obj, 1)};
  end
  
  function varargout = getOutputDataTypeImpl(obj) 
    varargout = {propagatedInputDataType(obj, 1)};
  end
  
  function varargout = isOutputComplexImpl(~)
    varargout = {true};
  end   
end

% methods(Static)
%   function props = matlabCodegenNontunableProperties(~)
%     props = {'SampleRate', 'pChannels'};
%   end
% end

methods(Static, Access = protected)
  function header = getHeaderImpl
    header = matlab.system.display.Header('NetworkChannel', ...
        'ShowSourceLink', true, ... 
        'Title', 'Network Channel', 'Text', ...
        'Each node transmit signals to all nodes in the network except for itself.');
  end  
end

end
