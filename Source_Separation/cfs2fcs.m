function fcs = cfs2fcs(cfs,fs)
%CFS2FCS Calculate gammatone crossover frequencies.
% 
%   FCS = CFS2FCS(CFS,FS) calculates the crossover frequencies of a
%   gammatone filterbank. The output fcs is the same size as CFS, with the
%   last element being equal to fs/2.
% 
%   The crossover frequencies are determined empirically by measuring the
%   impulse responses of the gammatone filters.
% 
%   See also GAMMATONEFAST, MAKEERBCFS.

%   Copyright 2016 University of Surrey.

    % Pre-allocate cut-off frequencies
    fcs = zeros(size(cfs));
    fcs(end) = fs/2;

    % Create impulse to derive cut-offs empirically
    imp_length = fs;
    imp = zeros(imp_length,1);
    imp(1) = 1;

    % Pre-allocate gammatone transfer functions
    z_length = floor(imp_length/2)+1;
    gamma_TF = zeros(z_length,length(cfs));

    % Filter impulses and calculate transfer functions.
    for i = 1:length(cfs)
        % filter
        gamma_imp = gammatoneFast(imp,cfs,fs);
        % transfer function
        temp = abs(fft(gamma_imp));
        gamma_TF(:,i) = temp(1:z_length);
    end

    f = ((0:z_length)./imp_length).*fs;

    % Find cross point of transfer functions.
    for i = 1:length(cfs)-1
        IX = f>cfs(i) & f<cfs(i+1);
        f_temp = f(IX);
        low_TF = gamma_TF(IX,i);
        high_TF = gamma_TF(IX,i+1);
        diff_TF = abs(high_TF-low_TF);
        fcs(i) = f_temp(find(diff_TF==min(diff_TF),1,'first'));
    end

end
