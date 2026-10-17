% Demo of QSI-EEM & related algorithms
%
% Runs the algorithms on the modified Branin example from Figure 1 and plots
% the points selected by each method.
%
% The number of evaluations default to 10, but can modified as follows:
% ```matlab
% NB_EVALUATONS = 30
% qsieempaper_demo
% ```
%
% Outputs are written to `outputs/`.

close all;

script_dir = fileparts(mfilename('fullpath'));
paper_code_dir = fileparts(script_dir);
root_dir = fileparts(paper_code_dir);

data_dir = fullfile(script_dir,'outputs');
paper_prepare_data_dir(data_dir);

% debug_mode = true: shortened configuration (see paper_debug_config)
debug_mode = false;

% seeds the RNG and names the initial design file
run_id = 1;

% any name known to paper_get_test_case: 'branin_mod', 'double_camel',
% 'hart4', 'piston_smc', 'otl_smc', 'trid_smc', 'rotor37'
case_name = 'branin_mod';

% FIXME: Explain batch_size, make it possible to change it from here
% (this parameter is not available for all implemented algorithms)
% batch_sizes = 1;

if ~ exist ('NB_EVALUATONS', 'var')
  NB_EVALUATONS = 10;  % default
end

if ~ isfinite (NB_EVALUATONS) ...
    || NB_EVALUATONS ~= (fix (NB_EVALUATONS)) ...
    || NB_EVALUATONS <= 0
  error('Invalid NB_EVALUATONS: %s', mat2str (NB_EVALUATONS));
end

[problem, config] = paper_get_test_case (case_name, debug_mode);
config.T = NB_EVALUATONS;
config.axT = 1;
paper_generate_initial_designs (problem, config, run_id, data_dir);
[prm, ~, ~] = problem();
n_init = config.pts_init;

algorithm_labels = {'QSI-EEM','QSI-SUR','Joint-SUR','Ranjan', ...
  'Misclassification','Random'};
n_algorithms = numel(algorithm_labels);

time_files = cell(n_algorithms,1);
time_files{1} = fullfile(data_dir,'results','time', ...
  sprintf('time_QSI_EEM_%s_%d.csv',prm.name,run_id));
time_files{2} = fullfile(data_dir,'results','time', ...
  sprintf('time_QSI_%s_%s_%d.csv',config.critName,prm.name,run_id));
time_files{3} = fullfile(data_dir,'results','time', ...
  sprintf('time_joint_%s_%s_%d.csv',config.critName,prm.name,run_id));
time_files{4} = fullfile(data_dir,'results','time', ...
  sprintf('time_Ranjan_%s_%d.csv',prm.name,run_id));
time_files{5} = fullfile(data_dir,'results','time', ...
  sprintf('time_misclassification_%s_%d.csv',prm.name,run_id));
time_files{6} = fullfile(data_dir,'results','time', ...
  sprintf('time_random_%s_%d.csv',prm.name,run_id));

fprintf('Running Figure 1 algorithm demo on %s\n',case_name);
fprintf('  Sequential evaluations per algorithm: %d\n',config.T);

% FIXME: The default should be to run QSI-EEM only
% with options to run other algorithms, or all the algorithms
% (and if we run several, plot some graphical comparisons)

paper_set_seed(1001);
paper_run_timed_algorithm(algorithm_labels{1}, ...
  @() QSI_EEM (problem, config, run_id, data_dir, 0), time_files{1});

paper_set_seed(1002);
paper_run_timed_algorithm(algorithm_labels{2}, ...
  @() QSI_SUR (problem, config, run_id, data_dir, 0), time_files{2});

paper_set_seed(1003);
paper_run_timed_algorithm(algorithm_labels{3}, ...
  @() joint_SUR (problem, config, run_id, data_dir), time_files{3});

paper_set_seed(1004);
paper_run_timed_algorithm(algorithm_labels{4}, ...
  @() Ranjan (problem, config, run_id, data_dir), time_files{4});

paper_set_seed(1005);
paper_run_timed_algorithm(algorithm_labels{5}, ...
  @() misclassification (problem,config,run_id,data_dir),time_files{5});

paper_set_seed(1006);
paper_run_timed_algorithm(algorithm_labels{6}, ...
  @() random (problem,config,run_id,data_dir),time_files{6});

fig_timer = tic();
fig_dir = fullfile(data_dir,'results','figures');
png_file = fullfile(fig_dir,'qsi_eem_uncertainty_demo.png');
plot_succeeded = true;
try
    qsieempaper_demo_plot
    fprintf ('  %-20s done in %.2f s\n','Figure generation', toc (fig_timer));
catch plot_error
    plot_succeeded = false;
    png_file = '[PLOT FAILED]';
    fprintf ('  Figure generation    failed in %.2f s\n', toc (fig_timer));
    fprintf ('  Completed algorithm outputs are still available in %s\n', data_dir);
    fprintf ('  %s\n', plot_error.message);
end

manifest = cell (7, 1);
manifest{1} = sprintf ('debug_mode=%d', debug_mode);
manifest{2} = sprintf ('problem=%s', case_name);
manifest{3} = sprintf ('run_id=%d', run_id);
manifest{4} = sprintf ('iterations=%d', config.T);
manifest{5} = sprintf ('initial_design_size=%d', n_init);
manifest{6} = sprintf ('algorithms=%s', strjoin (algorithm_labels, ','));
manifest{7} = sprintf ('figure=%s', png_file);
paper_write_manifest (data_dir, manifest);

fprintf('\nCompleted Figure 1 algorithm demo.\n');
fprintf('  Initial design points: %d\n',n_init);
fprintf('  Sequential steps per algorithm: %d\n',config.T);
if plot_succeeded
  fprintf('  Figure: %s\n',png_file);
else
  fprintf('  Figure: not generated\n');
end

cd(root_dir);

