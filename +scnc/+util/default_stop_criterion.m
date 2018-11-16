function tf = default_stop_criterion(perf, opts)

n_prev = opts.STRUCTURE.track_n_previous_trials;
crit = opts.STRUCTURE.correct_performance_threshold;
n_selected_threshold = opts.STRUCTURE.n_selected_threshold;

tf_1 = perf.n_selected >= n_selected_threshold;
tf = tf_1 || (perf.n_selected >= n_prev && perf.p_correct >= crit);

end