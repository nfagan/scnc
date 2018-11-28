function tf = n_selected_stop_criterion(perf, opts)

n_selected_threshold = opts.STRUCTURE.n_selected_threshold;
tf = perf.n_selected >= n_selected_threshold;

end