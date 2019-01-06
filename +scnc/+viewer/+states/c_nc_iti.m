function state = c_nc_iti(opts, data)

state = ptb.State();

state.Name = 'c-nc-iti';
state.Duration = Inf;

state.Entry = @(state) entry( state, opts, data );
state.Loop = @(state) loop( state, opts, data );
state.Exit = @(state) exit( state, opts, data );

end

function entry(state, opts, data)

end

function loop(state, opts, data)

import scnc.viewer.util.check_should_escape;

scnc.viewer.util.draw_eye_position( opts, data );
flip( opts.Value.WINDOW );

% Wait for the next trial's fixation, unless this is a break.
[should_escape, fixation_time] = check_should_escape( opts, data, 'fixation', true );

if ( isnan(fixation_time) )
  should_escape = check_should_escape( opts, data, 'break_display_image', true );
end

if ( should_escape )
  escape( state );
end

end

function exit(state, opts, data)

states = opts.Value.STATES;
next( state, states('c-nc-new-trial') );

end