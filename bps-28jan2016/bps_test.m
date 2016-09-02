%% Test BPS

nvars = 6;                              % Number of dimensions
LB = -Inf(1,nvars);                     % Lower bound
UB = Inf(1,nvars);                      % Upper bound
PLB = -8*ones(1,nvars);                 % Plausible lower bound
PUB = 12*ones(1,nvars);                 % Plausible upper bound
x0 = (PUB-PLB).*rand(1,nvars) + PLB;    % Initial point

%% Ellipsoid (BPS)

display('Test with deterministic function (ellipsoid). Press any key to continue.');

fun = @(x) sum((x./(1:numel(x)).^2).^2);     % Objective function

options = bps('defaults');              % Default options
options.Ninit = 2;                      % Only 2 points for initial mesh
options.Plot = 'profile';               % Show profile during optimization

pause;

[x,fval,exitflag,output] = bps(fun,x0,LB,UB,PLB,PUB,options);

display(['Final value: ' num2str(fval,'%.3f') ' (true value: 0.0), with ' num2str(output.FuncCount) ' fun evals.']);

%% Noisy sphere (BPS)

display('Test with noisy function (noisy sphere). Press any key to continue.');

fun = @(x) sum(x.^2) + randn();             % Noisy objective function

options = bps('defaults');              % Default options
options.Ninit = 2;                      % Only 2 points for initial mesh
options.Plot = 'profile';               % Show profile during optimization
options.UncertaintyHandling = 1;        % Activate noise handling
options.NoiseSize = 1;                  % Estimated noise magnitude

pause;

[x,fval,exitflag,output] = bps(fun,x0,LB,UB,PLB,PUB,options);

display(['Final value (not-noisy): ' num2str(sum(x.^2),'%.3f') ' (true value: 0.0) with ' num2str(output.FuncCount) ' fun evals.']);

%% Noisy sphere (FMINSEARCH)

display('Comparison with FMINSEARCH (noisy sphere). Press any key to continue.')

fun = @(x) sum(x.^2) + randn();             % Noisy objective function

options = optimset('Display','iter');

pause;

[x,fval,exitflag,output] = fminsearch(fun,x0,options);

display(['Final value (not-noisy): ' num2str(sum(x.^2),'%.3f') ' (true value: 0.0) with ' num2str(output.funcCount) ' fun evals.']);

%% Noisy sphere (GA)

if exist('ga.m','file')
    display('Comparison with GA (noisy sphere). Press any key to continue.')

    fun = @(x) sum(x.^2) + randn();             % Noisy objective function

    options = gaoptimset('Display','iter','Generations',19);
    
    pause;
    
    [x,fval,exitFlag,output] = ga(fun,nvars,[],[],[],[],LB,UB,[],[],options);
    display(['Final value (not-noisy): ' num2str(sum(x.^2),'%.3f')  ' (true value: 0.0) with ' num2str(output.funccount) ' fun evals.']);
end