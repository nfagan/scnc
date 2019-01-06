function t = get_trial_data_next_trial(opts, data)

trial_number = data.Value.timing_data.trial + 1;
t = data.Value.trial_data(trial_number);

end