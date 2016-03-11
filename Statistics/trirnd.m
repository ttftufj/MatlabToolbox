function r = trirnd(varargin)
%TRIRND Pseudorandom numbers drawn from the triangular distribution
%   
%   R = TRIRND(N) returns an N-by-N matrix containing pseudorandom values
%   drawn from the triangular distribution constrained to (-1,1) and mode =
%   0. TRIRND(M,N) or TRIRND([M,N]) returns an M-by-N matrix.
%   TRIRND(M,N,P,...) or TRIRND([M,N,P,...]) returns an M-by-N-by-P-by-...
%   array. TRIRND returns a scalar. TRIRND(SIZE(A)) returns an array the
%   same size as A.
%
%   Note: The size inputs M, N, P, ... should be nonnegative integers.
%   Negative integers are treated as 0.
%
%   The sequence of numbers produced by TRIRND is determined by the
%   settings of the uniform random number generator that underlies RAND,
%   RANDI, and RANDN. Control that shared random number generator using
%   RNG.
% 
%   See also LAPRND, RAND, RANDN, RANDI, RNG.

%   Based on code (Matlab FE File ID: #13705) written by Elvis Chen, 2007.

%   Copyright 2015 University of Surrey.

% =========================================================================
% Last changed:     $Date: 2015-07-02 15:47:12 +0100 (Thu, 02 Jul 2015) $
% Last committed:   $Revision: 391 $
% Last changed by:  $Author: ch0022 $
% =========================================================================

    % Generate traingular noise
    u1 = rand(varargin{:})-0.5;
    u2 = rand(varargin{:})-0.5;
    r = u1+u2;

end