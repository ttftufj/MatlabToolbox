classdef source < audio
%SOURCE Class of sound source separation source.
% 
%   Source objects contain information about a sound source (including its
%   spatial location). Source objects are passed to mixture objects in
%   order to create a mixture.
% 
%   SOURCE is a subclass of AUDIO.
% 
%   SOURCE properties:
%       azimuth     - Azimuth of the source
%       elevation   - Elevation of the source
%       numchans    - Number of audio channels in the source
%       precomposed - Logical flag indicating whether the source should be
%                     spatialised
% 
%   SOURCE methods:
%       source      - Create a source object
%       copy        - Create an independent copy of the source (but not its
%                     audio file)
%       write       - Write the source audio file (and resample/downmix)
% 
%   See also AUDIO, MIXTURE.

%   Copyright 2015 University of Surrey.
    
% =========================================================================
% Last changed:     $Date: 2016-02-09 10:51:21 +0000 (Tue, 09 Feb 2016) $
% Last committed:   $Revision: 463 $
% Last changed by:  $Author: ch0022 $
% =========================================================================
    
    properties (AbortSet)
        azimuth     % Azimuth of the source
        elevation   % Elevation of the source
        numchans    % Number of audio channels in the source
        precomposed % Logical flag indicating whether the source should be spatialised
    end
    
    properties (Dependent, SetAccess = protected)
        signal      % The sampled data (read-only)
    end
    
    properties (GetAccess = private, SetAccess = public)
         parent
    end
    
    methods
        
        % constructor
        function obj = source(filename,varargin)
        %SOURCE Create a source object
        % 
        %   OBJ = SOURCE(FILENAME) creates a source whose
        %   signal is contained in the audio file FILENAME. The source will
        %   have and azimuth and elevation of 0. The number of channels and
        %   sampling frequency will be determined by the audio file.
        % 
        %   OBJ = SOURCE(...,'PARAMETER',VALUE) allows
        %   additional options to be specified. The options are ({}
        %   indicate defaults):
        % 
        %       'azimuth'       : {0} | scalar
        %           The azimuth of the source for rendering.
        %       'elevation'     : {0} | scalar
        %           The elevation of the source for rendering.
        %       'fs'            : {fs of FILENAME} | scalar
        %           The sampling frequency of the source. If the sampling
        %           frequency of the audio file FILENAME does not match,
        %           the audio file will be resampled each time the signal
        %           is requested.
        %       'precomposed'   : {false} | true
        %           Logical flag indicating whether the source should be
        %           spatialised. By default it is assumed that the source
        %           is a point source (irrespective of its channel count),
        %           and it will be spatialised. When set to true, the
        %           source will be summed directly with the spatial signal.
        %       'numchans'      : {numchans of FILENAME} | scalar
        %           The number of channels in the source. If this does not
        %           match the channel count of the audio file FILENAME, the
        %           audio file will be up-/down-mixed each time the signal
        %           is requested.
        %
        %   The FS and NUMCHANS parameters do not affect the underlying
        %   audio file, but are implemented on-the-fly each time the signal
        %   is requested. To render the changes to a new audio file, use
        %   the write() method.
        %
        %   OBJ = SOURCE creates an empty source object.
        % 
        %   Note that this is a handle class. Sources are hence passed by
        %   reference. Use the COPY() method to create an independent copy
        %   of the source.
        %
        %   See also AUDIO.UP_DOWN_MIX.
        
            if nargin > 0
        
                propNames = {'azimuth','elevation','fs','precomposed','numchans'};

                obj.filename = filename;
                info = audioinfo(obj.filename);

                % defaults
                obj.azimuth = 0;
                obj.elevation = 0;
                obj.precomposed = false;
                obj.fs = info.SampleRate;
                obj.numchans = info.NumChannels;
                obj.rendered = false;

                % read parameter/value inputs
                if nargin > 1 % if parameters are specified
                    obj.set_properties(varargin,propNames)
                end
                
            end
            
        end
        
        function write(obj,filename)
        %WRITE Write the source audio file (and resample/downmix)
        % 
        %   SOURCE.WRITE() overwrites the source's audio file. If the
        %   source audio file's sampling rate and/or channel count do not
        %   match the object's properties, then the audio file will be
        %   resampled and/or up- or down-mixed accordingly.
        %
        %   SOURCE.WRITE(FILENAME) writes the audio file to the specified
        %   file FILENAME and updates SOURCE.FILENAME.
        %
        %   See also AUDIO.UP_DOWN_MIX.
            
            % overwrite filename if one is specified
            if exist('filename','var')==1
                obj.filename = filename;
            end
            
            assert(~isempty(obj.filename),'SOURCE.FILENAME is empty.')
        
            % ensure path exists
            obj.ensure_path(obj.filename)
            
            % write new file and update filename
            audiowrite(obj.filename,obj.normalize(obj.signal),obj.fs);
            obj.rendered = true;
            
        end
        
        % validate properties
        
        % validate azimuth
        function set.azimuth(obj,val)
            assert(isscalar(val),'AZIMUTH must be a scalar')            
            obj.azimuth = val;
            obj.property_changed('azimuth',val);
        end
        
        % validate elevation
        function set.elevation(obj,val)
            assert(isscalar(val),'ELEVATION must be a scalar')
            obj.elevation = val;
            obj.property_changed('elevation',val);
        end
        
        % validate numchans
        function set.numchans(obj,val)
            assert(isscalar(val),'NUMCHANS must be a scalar')
            obj.numchans = val;
            obj.property_changed('numchans',val);
        end
        
        % validate precomposed
        function set.precomposed(obj,val)
            assert(islogical(val) && numel(val)==1,'PRECOMPOSED property must be true or false') 
            obj.precomposed = val;
            obj.property_changed('precomposed',val);
        end
        
        % dependent properties
        
        % get dependent property signal
        function signal = get.signal(obj)
            
            % read audio file
            [signal,fs2] = audioread(obj.filename);
            
            % do more stuff if differences not rendered
            if ~obj.rendered
                N = size(signal,2);

                if fs2~=obj.fs % resample
                    signal = resample(signal,obj.fs,fs2);
                end
                if N~=obj.numchans % downmix
                    signal = audio.up_down_mix(signal,obj.numchans);
                end
            end
            
        end
        
    end
    
    methods(Access = protected)
        
        function property_changed(obj,name,val)
        %PROPERTY_CHANGED handle property changes
        
            obj.rendered = false;
            
            switch lower(name)
                case 'fs'
                    if isa(obj.parent,'mixture') && obj.parent.fs~=val
                        obj.parent.fs = val;
                    end
            end
            
        end
    
        function cpObj = copyElement(obj)
        %COPYELEMENT Overload copy method with additional functionality
            
            % Make a shallow copy of all properties
            cpObj = copyElement@audio(obj);
            
        end
        
    end
    
end