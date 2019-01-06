function t = get_trial_data_this_trial(opts, data)

trial_number = data.Value.timing_data.trial;
t = data.Value.trial_data(trial_number);

end