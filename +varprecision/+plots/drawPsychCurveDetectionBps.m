function drawPsychCurveDetectionBps(varargin)
%DRAWPSYCHCURVEDETECTION plots the psychometric function of both data and model
%   function drawPsychCurveDetecion(varagin)
%   one particular parameter set should be specified

    res_exp = varprecision.utils.parseVarargin('exp',varargin);
    res_subj = varprecision.utils.parseVarargin('subj',varargin);
    exps = fetch(varprecision.Experiment & res_exp);
    subjs = fetch(varprecision.Subject & res_subj);
    
    for iexp = 1:length(exps)
        exp = exps(iexp);
        setsizes = fetch1(varprecision.Experiment & exp,'setsize');
        keys_temp = fetch(varprecision.DataStatsDetectionBpsBestAvg & exp & varargin);
        bins = fetch1(varprecision.DataStatsDetectionBpsBestAvg & keys_temp(1),'bins');
        
        if length(subjs)==1
            % fetch data
            [data_pres_ss,data_abs_ss,model_pres_ss,model_abs_ss,data_pres_bin,data_abs_bin,model_pres_bin,model_abs_bin]...
                = fetch1(varprecision.DataStatsDetectionBpsBestAvg & keys_temp, 'data_pres_setsize','data_abs_setsize','model_pres_setsize','model_abs_setsize','data_pres_bin','data_abs_bin','model_pres_bin','model_abs_bin');

            % plot p_present vs set size

            fig1 = Figure(101,'size',[35,25]); hold on
            
            plot(setsizes, data_pres_ss, 'bo','LineStyle','None')
            plot(setsizes, data_abs_ss, 'ro','LineStyle','None')
            plot(setsizes, model_pres_ss, 'b-')
            plot(setsizes, model_abs_ss, 'r-')

            ylim([0,1]); xlim([0,max(setsizes)+2])
            set(gca, 'xTick',setsizes)
            %   legend('target present','target absent','Location','SouthEast')
            xlabel('setsize'); ylabel('p present')

            fig1.cleanup

            % plot p_present vs bins

            fig2 = Figure(103,'size',[180,30]); 
            for ii = 1:length(setsizes)
                if ii==1
                    subplot(1,4,ii)
                    hold on
                    plot(bins,model_abs_bin(ii,:),'r-')
                    plot(bins,data_abs_bin(ii,:),'ro')
                    ylim([0,1]); xlim([0,max(bins)+2])

                    xlabel('distractor orienation'); ylabel('p present')
                else 
                    subplot(1,4,ii)
                    hold on
                    plot(bins,model_abs_bin(ii,:),'r-')
                    plot(bins,data_abs_bin(ii,:),'ro')
                    plot(bins,model_pres_bin(ii,:),'b-')
                    plot(bins,data_pres_bin(ii,:),'bo')
                    ylim([0,1]); xlim([0,max(bins)+2])
                    if ii == 4
    %                     legend('target present','target absent','Location','NorthEast')
                    end
                    xlabel('distractor orienation'); ylabel('p present')
                end
            end
        else
            % fetch data
            [data_pres_ssMat,data_abs_ssMat,model_pres_ssMat,model_abs_ssMat,data_pres_binMat,data_abs_binMat,model_pres_binMat,model_abs_binMat]...
                = fetchn(varprecision.DataStatsDetectionBpsBestAvg & keys_temp, 'data_pres_setsize','data_abs_setsize','model_pres_setsize','model_abs_setsize','data_pres_bin','data_abs_bin','model_pres_bin','model_abs_bin');

            % plot p_present vs set size
            [data_pres_ss_mean,data_pres_ss_sem] = getMeanStdfromCell(data_pres_ssMat);
            [data_abs_ss_mean,data_abs_ss_sem] = getMeanStdfromCell(data_abs_ssMat);  

            model_pres_ss_patch = getPatch(model_pres_ssMat); 
            model_abs_ss_patch = getPatch(model_abs_ssMat); 

            fig = Figure(101,'size',[150,15]);
            
            subplot(1,5,1)
            hold on
            patch([setsizes, wrev(setsizes)], model_pres_ss_patch,[0.65,0.65,1],'LineStyle','None');
            patch([setsizes, wrev(setsizes)], model_abs_ss_patch, [1,0.65,0.65],'LineStyle','None');
            errorbar(setsizes, data_pres_ss_mean, data_pres_ss_sem,'b.','LineStyle','None');
            errorbar(setsizes, data_abs_ss_mean, data_abs_ss_sem,'r.','LineStyle','None');
            ylim([0,1]); xlim([0,max(setsizes)+2])
            set(gca, 'xTick',setsizes,'xTickLabel',[], 'yTick',0:0.2:1,'YTickLabel',{'0','','0.4','','0.8',''})
            
            %   legend('target present','target absent','Location','SouthEast')
%             xlabel('setsize'); ylabel('p present')

            % plot p_present vs bins
            [data_pres_bin_mean,data_pres_bin_sem] = getMeanStdfromCell(data_pres_binMat); 
            [data_abs_bin_mean,data_abs_bin_sem] = getMeanStdfromCell(data_abs_binMat);

            model_pres_bin_patch = getPatch(model_pres_binMat); 
            model_abs_bin_patch = getPatch(model_abs_binMat); 

            for ii = 1:length(setsizes)
                if ii==1
                    subplot(1,5,ii+1)
                    hold on
                    patch([bins, wrev(bins)],model_abs_bin_patch(ii,:),[1,0.65,0.65],'LineStyle','None')
                    errorbar(bins, data_abs_bin_mean(ii,:), data_abs_bin_sem(ii,:),'r','LineStyle','None')
                    ylim([0,1]); xlim([0,max(bins)+2])

%                     xlabel('distractor orienation'); 
%                     ylabel('p present')
                    
                else 
                    subplot(1,5,ii+1)
                    hold on
                    patch([bins, wrev(bins)],model_pres_bin_patch(ii,:),[0.65,0.65,1],'LineStyle','None')
                    patch([bins, wrev(bins)],model_abs_bin_patch(ii,:),[1,0.65,0.65],'LineStyle','None')
                    errorbar(bins, data_pres_bin_mean(ii,:), data_pres_bin_sem(ii,:),'b','LineStyle','None')
                    errorbar(bins, data_abs_bin_mean(ii,:), data_abs_bin_sem(ii,:),'r','LineStyle','None')
                    ylim([0,1]); xlim([0,max(bins)+2])
                    set(gca,'XTickLabel',[], 'YTick',[])
                    if ii == 4
%                         disp check!
    %                     legend('target present','target absent','Location','NorthEast')
                    end
%                     xlabel('distractor orienation'); 
%                     ylabel('p present')
                end
                set(gca,'YTick',0:0.2:1,'YTickLabel',[],'XTick',0:5:20,'XTickLabel',[]);
            end
            
        end
        fig.cleanup
        fig.save(['~/Dropbox/VR/+varprecision/figures/exp' num2str(exp.exp_id) '_' keys_temp(1).model_name '_psy.eps'])
    end
end

% helper function
function [data_mean,data_sem] = getMeanStdfromCell(dataMat)
    [dataMat,dim] = varprecision.utils.decell(dataMat);
    [data_mean,data_sem] = varprecision.utils.getMeanStd(dataMat,'sem',dim);
end

function patch = getPatch(dataMat)
    [dataMat,dim] = varprecision.utils.decell(dataMat);
    patch = varprecision.utils.getUpperLowerBound(dataMat,dim);
end