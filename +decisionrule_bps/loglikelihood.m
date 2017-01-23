function [LL,predMat,prediction] = loglikelihood(params,key)
%loglikelihood computes likelihood given all trials and one set of parameters
%   LL is the negative log likelihood, predMat is the likelihood of a model
%   for each trial given subject's response, prediction is the model
%   prediction of reporting "right" or "present" for each trial.

[stimuli, response, set_size] = fetch1(varprecision.Data & key ,'stimuli','response','set_size');
setsizes = unique(set_size);
exp_id = key.exp_id;

if ismember(key.exp_id,[6,7,11])
    vm = 1;
    [jmap,kmap] = fetch1(varprecision.JbarKappaMap & 'jkmap_id=2','jmap','kmap');
else
    vm = 0;
end
% get parameters correctly
if ismember(key.exp_id,[3,5,7])
    exp_id = exp_id - 1;
end

subj_type = fetch1(varprecision.Subject & ['subj_initial="' key.subj_initial '"'],'subj_type');
if ismember(key.exp_id,[3,5,7,10,11]) && ismember(subj_type,{'real','fake'})
    
    pars.p_right = params(1);
    pars.lambdaVec = params(2:5);
    switch key.model_name
        case 'CPG'
            pars.guess = params(6);
        case 'VP'
            pars.theta = params(6);
        case 'VPG'
            pars.theta = params(6);
            pars.guess = params(7);
        case {'OP','XP'}
            pars.beta = params(6);
        case {'OPG','XPG'}
            pars.beta = params(6);
            pars.guess = params(7);
        case {'OPVP','XPVP'}
            pars.theta = params(6);
            pars.beta = params(7);
        case {'OPVPG','XPVPG'}
            pars.theta = params(6);
            pars.beta = params(7);
            pars.guess = params(8);
        case 'CPN'
            pars.sigma_dn = params(6);
        case 'CPGN'
            pars.guess = params(6);
            pars.sigma_dn = params(7);
        case 'VPN'
            pars.theta = params(6);
            pars.sigma_dn = params(7);
        case 'VPGN'
            pars.theta = params(6);
            pars.guess = params(7);
            pars.sigma_dn = params(8);
        case 'OPN'
            pars.beta = params(6);
            pars.sigma_dn = params(7);
        case 'OPGN'
            pars.beta = params(6);
            pars.guess = params(7);
            pars.sigma_dn = params(8);
        case 'OPVPN'
            pars.theta = params(6);
            pars.beta = params(7);
            pars.sigma_dn = params(8);
        case 'OPVPGN'
            pars.theta = params(6);
            pars.beta = params(7);
            pars.guess = params(8);
            pars.sigma_dn = params(9);
    end
else
    pars.p_right = params(1);
    pars.lambda = params(2);
    switch key.model_name
        case 'CPG'
            pars.guess = params(3);
        case 'VP'
            pars.theta = params(3);
        case 'VPG'
            pars.theta = params(3);
            pars.guess = params(4);
        case {'OP','XP'}
            pars.beta = params(3);
        case {'OPG','XPG'}
            pars.beta = params(3);
            pars.guess = params(4);
        case {'OPVP','XPVP'}
            pars.theta = params(3);
            pars.beta = params(4);
        case {'OPVPG','XPVPG'}
            pars.theta = params(3);
            pars.beta = params(4);
            pars.guess = params(5);
        case 'CPN'
            pars.sigma_dn = params(3);
        case 'CPGN'
            pars.guess = params(3);
            pars.sigma_dn = params(4);
        case 'VPN'
            pars.theta = params(3);
            pars.sigma_dn = params(3);
        case 'VPGN'
            pars.theta = params(3);
            pars.guess = params(4);
            pars.sigma_dn = params(5);
        case 'OPN'
            pars.beta = params(3);
            pars.sigma_dn = params(4);
        case 'OPGN'
            pars.beta = params(3);
            pars.guess = params(4);
            pars.sigma_dn = params(5);
        case 'OPVPN'
            pars.theta = params(3);
            pars.beta = params(4);
            pars.sigma_dn = params(5);
        case 'OPVPGN'
            pars.theta = params(3);
            pars.beta = params(4);
            pars.guess = params(5);
            pars.sigma_dn = params(6);
    end
end

f = eval(['@varprecision.decisionrule.exp' num2str(exp_id)]);
pars.model_name = key.model_name;
pars.pre = 0;
pars.sigma_s = fetch1(varprecision.Experiment & key, 'sigma_s');
trial_num_sim = key.trial_num_sim;

predMat = zeros(size(response));

if length(setsizes)==1
    if ismember(key.model_name,{'CP','CPG','CPN','CPGN'})
        if vm == 0
            noiseMat = normrnd(0,1/sqrt(pars.lambda),[setsizes,trial_num_sim]);
        else
            pars.lambda = pars.lambda*180^2/pi^2/4;
            % map jbar to kappa
            pars.lambda = varprecision.utils.mapJK(pars.lambda,jmap,kmap);
            noiseMat = circ_vmrnd(zeros(setsizes,trial_num_sim),pars.lambda)/2;
        end
    elseif ismember(key.model_name, {'VP','VPG','VPN','VPGN'})
        pars.lambdaMat = gamrnd(pars.lambda/pars.theta,pars.theta,[setsizes,trial_num_sim]);
        if vm == 0
            noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
        else
            pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;
            pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
            noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
        end
    elseif ismember(key.model_name, {'OP','OPG','OPVP','OPVPG','XP','XPG','XPVP','XPVPG','OPN','OPGN','OPVPN','OPVPGN'})
        sigma_baseline = 1/sqrt(pars.lambda);
    end
    stimuli = varprecision.utils.adjustStimuliSize(exp_id,stimuli,setsizes);
    for ii = 1:length(stimuli)    
        stimulus = stimuli(ii,:);
        if ismember(key.model_name, {'OP','OPG','XP','XPG','OPN','OPGN'})
            sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*stimulus)));
            if vm
                pars.lambdaMat = 1./sigma.^2*180^2/pi^2/4;
                pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
                pars.lambdaMat = repmat(pars.lambdaMat, trial_num_sim,1)';
                noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
            else
                pars.lambdaMat = 1./sigma.^2;
                pars.lambdaMat = repmat(pars.lambdaMat,trial_num_sim,1)';
                noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
            end
        elseif ismember(key.model_name, {'OPVP','OPVPG','XPVP','XPVPG','OPVPN','OPVPGN'})
            sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*stimulus)));           
            pars.lambdaMat = 1./sigma.^2;
            pars.lambdaMat = repmat(pars.lambdaMat, trial_num_sim,1)';
            pars.lambdaMat = gamrnd(pars.lambdaMat/pars.theta,pars.theta);
            if vm
                pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;
                pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);                       
                noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
            else
                noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
            end
        end
        x = repmat(stimulus',[1,trial_num_sim]) + noiseMat;
        if ismember(key.model_name,{'XP','XPG'})
            sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*x)));
            if vm
                pars.lambdaMat = 1./sigma.^2*180^2/pi^2/4;
                pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
            else
                pars.lambdaMat = 1./sigma.^2;
            end
        elseif ismember(key.model_name,{'XPVP','XPVPG'})
            sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*x)));
            pars.lambdaMat = 1./sigma.^2;
            pars.lambdaMat = gamrnd(pars.lambdaMat/pars.theta,pars.theta);
            if vm
                pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;         
                pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
            end
            
        end
        predMat(ii) = f(x,pars);    
    end
else
    for jj = 1:length(setsizes)
        setsize = setsizes(jj);
        if ismember(key.exp_id,[7,10,11])
            stimuli_sub = stimuli(set_size==setsize,:);
        else
            stimuli_sub = stimuli(set_size==setsize);
        end
        response_sub = response(set_size==setsize);
        if ismember(key.model_name,{'CP','CPG','CPN','CPGN'})
            pars.lambda = pars.lambdaVec(jj);
            if vm == 0            
                noiseMat = normrnd(0,1/sqrt(pars.lambdaVec(jj)),[setsize,trial_num_sim]);
            else
                pars.lambda = pars.lambda*180^2/pi^2/4;
                pars.lambda = varprecision.utils.mapJK(pars.lambda,jmap,kmap);
                noiseMat = circ_vmrnd(zeros(setsize,trial_num_sim),pars.lambda)/2;
            end  
        elseif ismember(key.model_name,{'VP','VPG','VPN','VPGN'})
            pars.lambdaMat = gamrnd(pars.lambdaVec(jj)/pars.theta,pars.theta,[setsize,trial_num_sim]);
            if vm == 0
                noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
            else
                pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;
                pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
                noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
            end
        elseif ismember(key.model_name, {'OP','OPG','OPVP','OPVPG','XP','XPG','XPVP','XPVPG','OPN','OPGN','OPVPN','OPVPGN'})
            sigma_baseline = 1/sqrt(pars.lambdaVec(jj));
        end
        
        stimuliMat = varprecision.utils.adjustStimuliSize(key.exp_id,stimuli_sub,setsize);
        predMat_sub = zeros(size(response_sub));
        for ii = 1:length(stimuli_sub)
            stimulus = stimuliMat(ii,:);
            if ismember(key.model_name, {'OP','OPG','XP','XPG','OPN','OPGN'})
                sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*stimulus)));
                if vm
                    pars.lambdaMat = 1./sigma.^2*180^2/pi^2/4;
                    pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
                    pars.lambdaMat = repmat(pars.lambdaMat, trial_num_sim,1)';
                    noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
                else
                    pars.lambdaMat = 1./sigma.^2;
                    pars.lambdaMat = repmat(pars.lambdaMat, trial_num_sim,1)';
                    noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
                end
            elseif ismember(key.model_name, {'OPVP','OPVPG','XPVP','XPVPG','OPVPN','OPVPGN'})
                sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*stimulus)));
                pars.lambdaMat = 1./sigma.^2;
                pars.lambdaMat = repmat(pars.lambdaMat, trial_num_sim,1)';
                pars.lambdaMat = gamrnd(pars.lambdaMat/pars.theta,pars.theta);
                if vm
                    pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;
                    pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap); 
                    noiseMat = circ_vmrnd(0,pars.lambdaMat)/2;
                else
                    noiseMat = normrnd(0,1./sqrt(pars.lambdaMat));
                end
            end
            x = repmat(stimulus', [1,trial_num_sim]) + noiseMat;
            if ismember(key.model_name,{'XP','XPG'})
                sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*x)));
                if vm
                    pars.lambdaMat = 1./sigma.^2*180^2/pi^2/4;
                    pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
                else
                    pars.lambdaMat = 1./sigma.^2;
                end
            elseif ismember(key.model_name,{'XPVP','XPVPG'})
                sigma = sigma_baseline*(1 + pars.beta*abs(sin(2*x)));
                pars.lambdaMat = 1./sigma.^2;
                pars.lambdaMat = gamrnd(pars.lambdaMat/pars.theta,pars.theta);
                if vm
                    pars.lambdaMat = pars.lambdaMat*180^2/pi^2/4;         
                    pars.lambdaMat = varprecision.utils.mapJK(pars.lambdaMat,jmap,kmap);
                end
            end
        	predMat_sub(ii) = f(x,pars);
        end
        predMat(set_size==setsize) = predMat_sub;
    end
end
    
predMat(predMat==0) = 1/trial_num_sim;
predMat(predMat==1) = 1 - 1/trial_num_sim;

if ismember(key.model_name,{'CPG','VPG','OPG','OPVPG','XPG','XPVPG','CPGN','VPGN','OPGN','OPVPGN'})
    predMat = predMat*(1-pars.guess) + .5*pars.guess;
end

prediction = predMat;

if ~ismember(key.exp_id,[10,11])
    predMat(response==-1) = 1-predMat(response==-1);
else
    predMat(response==0) = 1-predMat(response==0);
end


LL = -sum(log(predMat));