subjs = fetch(varprecision.Subject & 'subj_type="real"');
keys = fetch(varprecision.InitialPoint & subjs & 'model_name in ("XP","XPG","XPVP","XPVPG")' & 'exp_id = 9' & 'int_point_id in (1)');

for iKey = keys'
    iKey.run_idx = 1;
    iKey.trial_num_sim = 5000;
    insert(varprecision.RunBps, iKey)

end