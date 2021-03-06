classdef mixture < iosr.dsp.audio
%MIXTURE Class of binaural sound source separation mixture.
% 
%   iosr.bss.mixture objects contain information about a binaural mixture
%   of sound sources.
% 
%   IOSR.BSS.MIXTURE is a subclass of IOSR.DSP.AUDIO.
% 
%   IOSR.BSS.MIXTURE properties:
%       azi_sep     - The azimuthal separation of the widest sources
%                     (read-only)
%       elevation   - The median elevation of the mixture (read-only)
%       filename_t  - Name of the target audio file (based on the mixture
%                     filename) (read-only)
%       filename_i  - Name of the interferer audio file (based on the
%                     Mixture filename) (read-only)
%       hrtfs       - Path to a SOFA file containing HRTF data
%       int_fns     - A char array containing the filenames of all of the
%                     interfering sources (read-only)
%       interferers - An array of interferer sources of type
%                     iosr.bss.source
%       signal_t    - The sampled data (target) (read-only)
%       signal_i    - The sampled data (interferer) (read-only)
%       target      - The target source of type iosr.bss.source
%       tir         - The target-to-interferer ratio (target or interferers
%                     are attenuated in order that their RMS amplitudes
%                     have this ratio)
% 
%   IOSR.BSS.MIXTURE methods:
%       mixture     - Create the mixture
%       copy        - Create an independent copy of the mixture, its
%                     sources, and any rendered files
%       sound_t     - Replay the target
%       sound_i     - Replay the interferer
%       write       - Save the mixture to an audio file
% 
%   Note that target and interferer properties may be modified as
%   MIXTURE.TARGET.PROPERTY_NAME and MIXTURE.INTERFERERS(N).PROPERTY_NAME,
%   except for the sampling frequency FS, which cannot be overridden. This
%   ensures that the sampling frequencies are identical for the mixture and
%   its sources.
% 
%   See also IOSR.DSP.AUDIO, IOSR.BSS.SOURCE, SOFALOAD.

%   Copyright 2016 University of Surrey.
    
    properties (AbortSet)
        hrtfs       % Path to a SOFA file containing HRTF data
        tir = 0     % The target to interferer ratio
        interferers % An array of interferer sources of type iosr.bss.source
        target      % The target source of type iosr.bss.source
    end
    
    properties (Dependent, SetAccess = protected)
        signal      % The sampled data (read-only)
    end
        
    properties (Dependent, SetAccess = private)
        azi_sep     % The azimuthal separation of the widest sources (read-only)
        elevation   % The median elevation of the mixture (read-only)
        filename_t  % Name of the target audio file (read-only)
        filename_i  % Name of the interferer audio file (read-only)
        int_fns     % Filenames of all of the interfering sources (read-only)
        signal_t    % Return target (read-only)
        signal_i    % Return interferer (read-only)
    end
    
    methods
        
        % constructor
        function obj = mixture(target,interferers,varargin)
        %MIXTURE Create a mixture
        % 
        %   OBJ = IOSR.BSS.MIXTURE(TARGET,INTERFERER) creates a mixture by
        %   summing together the target source and the interferer
        %   source(s). Monaural sources are mixed to stereo. The sources
        %   are mixed together such that their RMS amplitudes are equal
        %   (target-to-interferer ratio is 0dB). The OBJ sampling rate is
        %   equal to the target sampling rate. Information about the
        %   sources' spatial location is ignored.
        %   
        %   OBJ = IOSR.BSS.MIXTURE(...,'PARAMETER',VALUE) allows additional
        %   options to be specified. The options are ({} indicate
        %   defaults):
        %   
        %       'filename'  : {[]} | str
        %           A filename used when writing the file with the write()
        %           method. The filename may also be set when calling the
        %           write() method. Filenames for the target and interferer
        %           are determined automatically, by append the filename
        %           with '_target' and '_interferer' respectively.
        %       'fs'        : {obj.target.fs} | scalar
        %           The sampling frequency of the mixture. All HRTFs and/or
        %           sources will be resampled to this frequency each time
        %           the signal is requested.
        %       'hrtfs'     : {[]} | str
        %           A path to a SOFA file containing HRTFs that are
        %           convolved with sources in order to generate the
        %           mixture.
        %       'tir'       : {0} | scalar
        %           The RMS ratio of the target and interfer sources.
        %           Interferer sources are individually set to this level
        %           prior to their summation.
        %
        %   OBJ = IOSR.BSS.MIXTURE creates an empty mixture object with
        %   empty target and interferer sources.
        %
        %   Note that this is a handle class, as is IOSR.BSS.SOURCE. Target
        %   and interferer(s) are hence passed by reference. Use the COPY()
        %   method to create an independent copy of the mixture and its
        %   sources.
        
            if nargin > 0
                
                assert(nargin>1,'Not enough input arguments')
        
                propNames = {'filename','fs','hrtfs','tir'};

                % set sources
                obj.target = target;
                obj.interferers = interferers;

                % defaults
                obj.fs = obj.target.fs;
                obj.hrtfs = [];
                obj.tir = 0;
                obj.rendered = false;

                % read parameter/value inputs
                if nargin > 1 % if parameters are specified
                    obj.set_properties(varargin,propNames)
                end

                % set sample rate to SOFA file if set and fs not specified
                if ~isempty(obj.hrtfs) && all(~strcmp('fs',varargin))
                    SOFAobj = SOFAload(obj.hrtfs); % load SOFA object
                    obj.fs = SOFAobj.Data.SamplingRate;
                end

                % ensure fs for sources matches instance
                obj.target.fs = obj.fs;
                for n = 1:numel(obj.interferers)
                    obj.interferers(n).fs = obj.fs;
                end
                
                % set parent
                obj.target.parent = obj;
                for n = 1:numel(obj.interferers)
                    obj.interferers(n).parent = obj;
                end
                
            end
            
        end
        
        function sound_t(obj)
        %SOUND_T Replay the target signal
        %
        %   IOSR.BSS.MIXTURE.SOUND_T() replays the target signal.
            
            obj.replay(obj.signal_t)
            
        end
        
        function sound_i(obj)
        %SOUND_I Replay the interferer signal
        %
        %   IOSR.BSS.MIXTURE.SOUND_I() replays the interferer signal.
            
            obj.replay(obj.signal_i)
            
        end
        
        function write(obj,filename)
        %WRITE Save the mixture to an audio file
        %
        %   IOSR.BSS.MIXTURE.WRITE() writes the mixture to an audio file
        %   specified by MIXTURE.FILENAME, and also writes the target and
        %   interferer signals to automatically-determined file names
        %   (MIXTURE.FILENAME_T and MIXTURE.FILENAME_I respectively).
        %
        %   IOSR.BSS.MIXTURE.WRITE(FILENAME) uses the specified FILENAME
        %   and updates MIXTURE.FILENAME.
            
            if obj.rendered && exist('filename','var')==1
                obj.ensure_path(filename);
                copyfile(obj.filename,filename);
                copyfile(obj.filename_t,obj.make_target_filename(filename));
                copyfile(obj.filename_i,obj.make_interferer_filename(filename));
                obj.filename = filename;
            else
                if exist('filename','var')==1
                    obj.filename = filename;
                end
                % check filename is valid
                assert(ischar(obj.filename) && ~isempty(obj.filename),'FILENAME must be a non-empty char array. Set filename as MIXTURE.FILENAME or MIXTURE.WRITE(FILENAME).')

                % normalize
                M = obj.signal;
                T = obj.signal_t;
                I = obj.signal_i;
                [~,gain] = obj.normalize([M T I]);
                M = M.*gain;
                T = T.*gain;
                I = I.*gain;

                % ensure path
                obj.ensure_path(obj.filename)

                % write audio files
                audiowrite(obj.filename,M,obj.fs);
                audiowrite(obj.filename_t,T,obj.fs);
                audiowrite(obj.filename_i,I,obj.fs);

                % set flag to indicate mixture has been rendered to an audio file
                obj.rendered = true;
                
            end
            
        end        

        % set/validate properties
        
        % set tir
        function set.tir(obj,val)
            obj.tir = val;
            obj.property_changed('tir',val);
        end
        
        % validate hrtfs
        function set.hrtfs(obj,val)
            assert(ischar(val) || isempty(val),'HRTFs must be a char array or an empty array')
            if ~isempty(obj.hrtfs)
                assert(exist(val,'file')==2,'HRTFs file does not exist')
            end
            obj.hrtfs = val;
            obj.property_changed('hrtfs',val);
        end
        
        % validate interferers
        function set.interferers(obj,val)
            assert(isa(val,'iosr.bss.source'),'INTERFERERS must be of type source')
            obj.interferers = val;
            obj.property_changed('interferers',val);
        end
        
        % validate target
        function set.target(obj,val)
            assert(isa(val,'iosr.bss.source') && numel(val)==1,'TARGET must be a scalar of type source')
            obj.target = val;
            obj.property_changed('target',val);
        end
        
        % dependent properties
        
        % get azimuthal separation
        function s = get.azi_sep(obj)
            [s,~] = get_loc(obj);
        end
        
        % get median elevation
        function e = get.elevation(obj)
            [~,e] = get_loc(obj);
        end
        
        % target filename
        function fn = get.filename_t(obj)    
            fn = obj.make_target_filename(obj.filename);
        end
        
        % interferer filename
        function fn = get.filename_i(obj)
            fn = obj.make_interferer_filename(obj.filename);
        end
        
        % filenames of all interferers
        function fns = get.int_fns(obj)
            for n = 1:length(obj.interferers)
                if n==1
                    fns = obj.interferers(n).filename;
                else
                    fns = [fns ', ' obj.interferers(n).filename]; %#ok<AGROW>
                end
            end
        end
        
        % return target signal
        function signal_t = get.signal_t(obj)
            if obj.rendered && exist(obj.filename_t,'file')==2 % don't bother calculating
                signal_t = audioread(obj.filename_t);
            else % calculate
                signal_t = return_source(obj,obj.target);
                if obj.tir<0
                    % attenuate according to TIR
                    Trms = iosr.dsp.rms(signal_t(:));
                    Irms = iosr.dsp.rms(obj.signal_i(:));
                    signal_t = signal_t./(Trms/Irms); % match to interferer
                    signal_t = signal_t.*(10^(obj.tir/20)); % attenuate
                end
            end
        end
        
        % return interferer signal
        function signal_i = get.signal_i(obj)
            if obj.rendered && exist(obj.filename_i,'file')==2 % don't bother calculating
                signal_i = audioread(obj.filename_i);
            else % calculate
                signal_i = [0 0]; % initialise
                maxlength = 0; % initialise
                for n = 1:numel(obj.interferers) % step through each interferer
                    % source signal (ensure 2-channel)
                    s = obj.return_source(obj.interferers(n));
                    % ensure signals are same length, or zero-pad
                    maxlength = max([length(s) maxlength]);
                    s = obj.setlength(s,maxlength);
                    signal_i = obj.setlength(signal_i,maxlength);
                    % add source to interferer
                    signal_i = signal_i + s;
                end
                if obj.tir>=0
                    % attenuate according to TIR
                    Trms = iosr.dsp.rms(obj.signal_t(:));
                    Irms = iosr.dsp.rms(signal_i(:));
                    signal_i = signal_i./(Irms/Trms); % match to interferer
                    signal_i = signal_i./(10^(obj.tir/20)); % attenuate
                end
            end
        end
        
        % return mixture signal
        function signal = get.signal(obj)
            if obj.rendered && exist(obj.filename,'file')==2 % don't bother calculating
                signal = audioread(obj.filename);
            else % calculate
                % return target and interferers
                T = obj.signal_t;
                I = obj.signal_i;
                % mix, ensuring equal length
                maxlength = max([length(T) length(I)]);
                signal = obj.setlength(T,maxlength) + obj.setlength(I,maxlength);
            end
        end
    end
        
    methods (Static, Access = private)
        
        function y = setlength(x,signal_length)
        %SETLENGTH Crop or zero-pad signal to specified length
            
            if length(x)>signal_length % need to crop
                y = x(1:signal_length,:);
            elseif length(x)<signal_length % need to zero-pad
                y = [x; zeros(signal_length-length(x)+1,size(x,2))];
            else % do nothing
                y = x;
            end
            
        end
        
        function fn = append_filename(filename,append)
        %APPEND_FILENAME Append strings to MIXTURE.FILENAME
            
            if isempty(filename) % do nothing if filename is empty
                fn = [];
            else % append
                [filepath,name,ext] = fileparts(filename); % break up filename
                newname = [name append ext]; % append
                if isempty(filepath) % only filename specified
                    fn = newname;
                else % path specified
                    fn = [filepath filesep newname];
                end
            end
            
        end
        
    end
        
    methods (Access = private)
        
        function c = hrtf_is_set(obj)
        %HRTF_IS_SET Determine whether HRTFs are specified
            
            c = ~isempty(obj.hrtfs);
            
        end
        
        function s = return_source(obj,src)
        %RETURN_SOURCE Return binaural signal from specified source
            
            % ensure correct channel count
            if ~src.precomposed && obj.hrtf_is_set()
                src.numchans = 1; % signal will be binauralised
            else
                src.numchans = 2; % signal will be mixed directly
            end
            x = src.signal;
            % return/convolve signal
            if ~src.precomposed && obj.hrtf_is_set() % convolve
                s = obj.spat(obj.hrtfs,x,src.azimuth,src.elevation,obj.fs);
            else % return directly
                s = x; 
            end
            
        end
        
        function [s,em] = get_loc(obj)
        %GET_LOC Return location information
            
            % get angles from the sources
            a = zeros(numel(obj.interferers)+1,1);
            e = a;
            for n = 1:numel(obj.interferers)
                a(n) = obj.interferers(n).azimuth;
                e(n) = obj.interferers(n).elevation;
            end
            a(end) = obj.target.azimuth;
            e(end) = obj.target.elevation;
            
            % get separation
            if any(a<0) % assume angles are -179:180
                s = abs(max(a)-min(a));
            else % assume angles are 0:359
                s = (360-max(a))+min(a);
            end
            s = mod(s,180);
            
            % get elevation
            em = median(e);
            
        end
        
        function fn = make_target_filename(obj,filename)
        %MAKE_TARGET_FILENAME Return the automated target filename
        
            fn = obj.append_filename(filename,'_target');
            
        end
        
        function fn = make_interferer_filename(obj,filename)
        %MAKE_INTERFERER_FILENAME Return the automated interferer filename
        
            fn = obj.append_filename(filename,'_interferer');
            
        end
        
    end
    
    methods(Access = protected)
        
        function property_changed(obj,name,val)
        %PROPERTY_CHANGED handle property changes
        
            obj.rendered = false;
            
            switch lower(name)
                case 'fs'
                    obj.target.fs = val;
                    for n = 1:numel(obj.interferers)
                        obj.interferers(n).fs = val;
                    end
            end
            
        end
    
        function cpObj = copyElement(obj)
        %COPYELEMENT Overload copy method with additional functionality
        
            % Make a shallow copy of all properties
            cpObj = copyElement@iosr.dsp.audio(obj);
            
            % Changed rendered file name
            cpObj.filename = obj.append_filename(cpObj.filename,'_copy');
            
            % copy files
            if obj.rendered
                if exist(obj.filename,'file')==2
                    copyfile(obj.filename,cpObj.filename)
                end
                if exist(obj.filename_i,'file')==2
                    copyfile(obj.filename_i,cpObj.filename_i)
                end
                if exist(obj.filename_t,'file')==2
                    copyfile(obj.filename_t,cpObj.filename_t)
                end
            end
        
            % Make a deep copy of target and interferers
            cpObj.target = copy(obj.target);
            cpObj.interferers = copy(obj.interferers);
            
        end
        
    end
    
end
