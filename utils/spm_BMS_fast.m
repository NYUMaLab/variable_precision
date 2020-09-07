function [alpha,exp_r,xp,pxp,bor,g] = spm_BMS_fast(lme, Nsamp, do_plot, sampling, ecp, alpha0)
% Bayesian model selection for group studies (vectorized for speed)
% FORMAT [alpha,exp_r,xp,pxp,bor] = spm_BMS_fast (lme, Nsamp, do_plot, sampling, ecp, alpha0)
% 
% INPUT:
% lme      - array of log model evidences 
%              rows: subjects
%              columns: models (1..Nk)
% Nsamp    - number of samples used to compute exceedance probabilities
%            (default: 1e6)
% do_plot  - 1 to plot p(r|y)
% sampling - use sampling to compute exact alpha
% ecp      - 1 to compute exceedance probability
% alpha0   - [1 x Nk] vector of prior model counts
% 
% OUTPUT:
% alpha   - vector of model probabilities
% exp_r   - expectation of the posterior p(r|y)
% xp      - exceedance probabilities
% pxp     - protected exceedance probabilities
% bor     - Bayes Omnibus Risk (probability that model frequencies 
%           are equal)
% g       - matrix of individual posterior probabilities
% 
% REFERENCES:
%
% Stephan KE, Penny WD, Daunizeau J, Moran RJ, Friston KJ (2009)
% Bayesian Model Selection for Group Studies. NeuroImage 46:1004-1017
%
% Rigoux, L, Stephan, KE, Friston, KJ and Daunizeau, J. (2014)
% Bayesian model selection for group studies?Revisited. 
% NeuroImage 84:971-85. doi: 10.1016/j.neuroimage.2013.08.065
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% 2016 Modified by Luigi Acerbi for speed and added interface

% Klaas Enno Stephan, Will Penny, Lionel Rigoux and J. Daunizeau
% $Id: spm_BMS.m 5842 2014-01-20 10:53:17Z will $

if nargin < 2 || isempty(Nsamp)
    Nsamp = 1e6;
end
if nargin < 3 || isempty(do_plot)
    do_plot = 0;
end
if nargin < 4 || isempty(sampling)
    sampling = 0;
end
if nargin < 5 || isempty(ecp)
    ecp = (nargout > 2);
end

max_val = log(realmax('double'));
Ni      = size(lme,1);  % number of subjects
Nk      = size(lme,2);  % number of models
c       = 1;
cc      = 10e-6;


% prior observations
%--------------------------------------------------------------------------
if nargin < 6 || isempty(alpha0)
    alpha0  = ones(1,Nk);    
end
alpha   = alpha0;


% iterative VB estimation
%--------------------------------------------------------------------------
while c > cc,

    % compute posterior belief g(i,k)=q(m_i=k|y_i) that model k generated
    % the data for the i-th subject

    % integrate out prior probabilities of models (in log space)
    log_u = bsxfun(@plus, lme, psi(alpha)- psi(sum(alpha)));    
    log_u = bsxfun(@minus, log_u, mean(log_u,2));

    % prevent numerical problems for badly scaled posteriors
    log_u = sign(log_u) .* min(max_val,abs(log_u));
   
    % exponentiate (to get back to non-log representation)
    u  = exp(log_u);

    % normalisation: sum across all models for i-th subject
    u_i     = sum(u,2);
    g       = bsxfun(@rdivide, u, u_i);
                
    % expected number of subjects whose data we believe to have been 
    % generated by model k
    beta = sum(g,1);

    % update alpha
    prev  = alpha;
    alpha = alpha0 + beta;
    
    % convergence?
    c = norm(alpha - prev);

end


% Compute expectation of the posterior p(r|y)
%--------------------------------------------------------------------------
exp_r = alpha./sum(alpha);


% Compute exceedance probabilities p(r_i>r_j), Bayesian Omnibus Risk, and
% protected exceedance probabilities
%--------------------------------------------------------------------------
if ecp
    [xp,bor,pxp] = spm_dirichlet_exceedance_fast(alpha, Nsamp, lme, g, alpha0);
else
    xp = []; bor = []; pxp = [];
end


% Graphics output (currently for 2 models only)
%--------------------------------------------------------------------------
if do_plot && Nk == 2
    % plot Dirichlet pdf
    %----------------------------------------------------------------------
    if alpha(1)<=alpha(2)
       alpha_now =sort(alpha,1,'descend');
       winner_inx=2;
    else
        alpha_now =alpha;
       winner_inx=1;
    end
    
    x1  = [0:0.0001:1];
    for i = 1:length(x1),
        p(i)   = spm_Dpdf([x1(i) 1-x1(i)],alpha_now);
    end
    fig1 = figure;
    axes1 = axes('Parent',fig1,'FontSize',14);
    plot(x1,p,'k','LineWidth',1);
    % cumulative probability: p(r1>r2)
    i  = find(x1 >= 0.5);
    hold on
    fill([x1(i) fliplr(x1(i))],[i*0 fliplr(p(i))],[1 1 1]*.8)
    v = axis;
    plot([0.5 0.5],[v(3) v(4)],'k--','LineWidth',1.5);
    xlim([0 1.05]);
    xlabel(sprintf('r_%d',winner_inx),'FontSize',18);
    ylabel(sprintf('p(r_%d|y)',winner_inx),'FontSize',18);
    title(sprintf('p(r_%d>%1.1f | y) = %1.3f',winner_inx,0.5,xp(winner_inx)),'FontSize',18);
    legend off
end


% Sampling approach ((currently implemented for 2 models only):
% plot F as a function of alpha_1
%--------------------------------------------------------------------------
if sampling
    if Nk == 2
        % Compute lower bound on F by sampling
        %------------------------------------------------------------------
        alpha_max = size(lme,1) + Nk*alpha0(1);
        dx        = 0.1;
        a         = [1:dx:alpha_max];
        Na        = length(a);
        for i=1:Na,
            alpha_s                = [a(i),alpha_max-a(i)];
            [F_samp(i),F_bound(i)] = spm_BMS_F(alpha_s,lme,alpha0);
        end
        if do_plot
        % graphical display
        %------------------------------------------------------------------
        fig2 = figure;
        axes2 = axes('Parent',fig2,'FontSize',14);
        plot(a,F_samp,'Parent',axes2,'LineStyle','-','DisplayName','Sampling Approach',...
            'Color',[0 0 0]);
        hold on;
        yy = ylim;
        plot([alpha(1),alpha(1)],[yy(1),yy(2)],'Parent',axes2,'LineStyle','--',...
            'DisplayName','Variational Bayes','Color',[0 0 0]);
        legend2 = legend(axes2,'show');
        set(legend2,'Position',[0.15 0.8 0.2 0.1],'FontSize',14);
        xlabel('\alpha_1','FontSize',18);
        ylabel('F','FontSize',18);
        end
    else
        fprintf('\n%s\n','Verification of alpha estimates by sampling not available.')
        fprintf('%s\n','This approach is currently only implemented for comparison of 2 models.');
    end
end