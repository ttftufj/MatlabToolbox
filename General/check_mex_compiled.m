function check_mex_compiled(varargin)
%CHECK_MEX_COMPILED Check if mex file is compiled for system
% 
%   CHECK_MEX_COMPILED(SOURCE_FILE) checks whether a mex source file
%   SOURCE_FILE is compiled for the current operating system OR whether the
%   source file has been modified since it was compiled. It is compiled if
%   it does not pass these tests (to the same directory as the source
%   file). SOURCE_FILE must be a string that is the name of a source file
%   on the MATLAB search path.
% 
%   CHECK_MEX_COMPILED(OPTIONS,...,SOURCE_FILE) passes the script switches
%   in OPTIONS to the mex compiler, one argument per switch.
% 
%   Example
% 
%       % check function compiled, with debugging info, and
%       % with large-array-handling API
%       check_mex_compiled('-g','-largeArrayDims','myfun.c')
% 
%   See also MEX.

%   Copyright 2015 University of Surrey.

% =========================================================================
% Last changed:     $Date: 2015-07-02 15:47:12 +0100 (Thu, 02 Jul 2015) $
% Last committed:   $Revision: 391 $
% Last changed by:  $Author: ch0022 $
% =========================================================================

    source_file = varargin{end};

    % Check input filename
    assert(ischar(source_file),'source_file must be a string')

    % Check extension is specified
    assert(~isempty(strfind(source_file,'.')),'source_file: no file extension specified')

    % Locate source file
    [pathstr,name,ext] = fileparts(which(source_file));

    filename = [pathstr filesep name ext]; % Create filename
    mexfilename = [pathstr filesep name '.' mexext]; % Deduce mex file name based on current platform

    if strcmp(pathstr,'') % source file not found
        error([source_file ': not found'])
    elseif exist(mexfilename,'file')~=3 || get_mod_date(mexfilename)<get_mod_date(filename)
         % if source file does not exist or it was modified after the mex file
        disp(['Compiling "' name ext '".'])
        d = cd;
        cd(pathstr)
        % compile, with options if appropriate
        if length(varargin)>1
            options = varargin{1:end-1};
            mex(options,source_file)
        else
            mex(source_file)
        end
        disp('Done.')
        cd(d)
    end

end

function datenum = get_mod_date(file)
%GET_MOD_DATE get file modified date

    d = dir(file);
    datenum = d.datenum;

end