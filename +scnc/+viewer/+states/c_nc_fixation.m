function state = c_nc_fixation(opts, data)

state = ptb.State();

state.Name = 'c-nc-fixation';
state.Duration = Inf;

state.Entry = @(state) entry( state, opts, data );
state.Loop = @(state) loop( state, opts, data );
state.Exit = @(state) exit( state, opts, data );

end

function entry(state, opts, data)

states = opts.Value.STATES;
next( state, states('c-nc-present-targets') );

end

function loop(state, opts, data)

import scnc.viewer.util.check_should_escape;
import shared_utils.struct.field_or;

fix_square = opts.Value.STIMULI.fix_square;
window = opts.Value.WINDOW;
states = opts.Value.STATES;
structure = opts.Value.STRUCTURE;

draw( fix_square, window );
scnc.viewer.util.draw_eye_position( opts, data );

flip( window );

use_frame_count = field_or( structure, 'star_use_frame_count', false );
task_type = field_or( structure, 'task_type', 'c-nc' );

if ( strcmp(task_type, 'c-nc') )
  if ( use_frame_count )
    target_event_name = 'present_targets_frame_count';
  else
    target_event_name = 'present_targets';
  end
elseif ( strcmp(task_type, 'rt') )
  target_event_name = 'rt_present_targets';
else
  error( 'Unrecognized task type: "%s".', task_type );
end
  
[should_escape, check_time] = check_should_escape( opts, data, target_event_name );

if ( isnan(check_time) )
  % If fixation is broken, no targets are presented; wait for iti instead.
  if ( check_should_escape(opts, data, 'iti') )
    next( state, states('c-nc-iti') );
    escape( state );
  end
elseif ( should_escape )
  escape( state );
end

end

function exit(state, opts, data)

end