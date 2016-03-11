function r = urn(varargin)
%URN Generate random number sequence without duplicates
% 
%   URN(N) returns an N-by-N matrix containing a random sequence of
%   integers in the interval 1:N without duplicates. The integers are
%   unique down each column.
% 
%   URN(M,N) and URN([M,N]) return an M-by-N matrix.
% 
%   URN(M,N,P,...) and URN([M,N,P,...]) return an M-by-N-by-P-by-... array.
%   The integers are unique along the first non-singleton dimension.
% 
%   URN(...,[],DIM) creates the random sequence along the dimension dim.
% 
%   This function uses a simple algorithm whereby a series or
%   uniformly-distributed random numbers are generated and sorted. The
%   returned array r is simply the array of indices specifying the sort
%   order.
% 
%   The function was inspired by an object of the same name
%   in Cycling 74's Max/MSP.

%   Copyright 2015 University of Surrey.

% =========================================================================
% Last changed:     $Date: 2015-07-02 15:47:12 +0100 (Thu, 02 Jul 2015) $
% Last committed:   $Revision: 391 $
% Last changed by:  $Author: ch0022 $
% =========================================================================

    % determines whether dimension specified
    dimcheck = false;

    % find an empty matrix in input
    empties = find(cellfun(@isempty,varargin));
    if ~isempty(empties)
        % if there is an empty matrix (dim specified)
        range = 1:empties-1; % input array-size-data range
        if length(varargin)>empties % check extra dim input specified
            dimcheck = true; % dim has been specified
            dim = varargin{empties+1}; % get dim
        else
            warning('Empty array but no dim specified. Using default.') %#ok<WNTAG>
        end
    else
        % input array-size-data range if no dim specified
        range = 1:length(varargin);
    end

    % input array-size-data at input
    n = cell2mat(varargin(range));

    % random numbers
    c = rand(n);

    % If dim unspecified, find first non-singleton dimension
    if ~dimcheck
        nsdim = find(size(c)>1,1,'first');
        if isempty(nsdim)
            dim = 1;
        else
            dim = nsdim;
        end
    end

    % sort the sequence, keeping sort indices as random integers
    [~,r] = sort(c,dim);

end