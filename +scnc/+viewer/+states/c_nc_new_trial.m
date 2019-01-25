function state = c_nc_new_trial(opts, data)

state = ptb.State();

state.Name = 'c-nc-new-trial';
state.Duration = Inf;

state.Entry = @(state) entry( state, opts, data );
state.Loop = @(state) loop( state, opts, data );
state.Exit = @(state) exit( state, opts, data );

end

function entry(state, opts, data)

trial = data.Value.timing_data.trial;
n_trials = data.Value.timing_data.n_trials;

trial_data = scnc.viewer.util.get_trial_data_next_trial( opts, data );

% If this is a break, fixation time will be NaN; skip this trial.
if ( isnan(trial_data.events.fixation) )
  trial = trial + 2;
else
  trial = trial + 1;
end

if ( trial >= n_trials )
  escape( opts.Value.TASK );
end

data.Value.timing_data.trial = trial;

end

function loop(state, opts, data)

import scnc.viewer.util.check_should_escape;

window = opts.Value.WINDOW;

scnc.viewer.util.draw_eye_position( opts, data );
flip( window );

[should_escape, fixation_time] = check_should_escape( opts, data, 'fixation' );

if ( isnan(fixation_time) )
  should_escape = check_should_escape( opts, data, 'break_display_image' );
end

if ( should_escape )
  escape( state );
end

end

function exit(state, opts, data)

states = opts.Value.STATES;
next( state, states('c-nc-fixation') );

end