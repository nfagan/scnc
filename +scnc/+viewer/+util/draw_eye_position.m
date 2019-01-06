function draw_eye_position(opts, data)

eye_pos = opts.Value.STIMULI.eye_position;

current_window = opts.Value.WINDOW;
original_window = opts.Value.VIEWER.original_window;
task = opts.Value.TASK;
eye_data = data.Value.eye_data;

clock_offset = data.Value.timing_data.clock_offset;
current_time = elapsed( task ) + clock_offset;

[x, y] = scnc.viewer.util.get_nearest_eye_sample( eye_data, current_time );
eye_pos.Position = get_normalized_value( ptb.Transform([x, y]), original_window );

draw( eye_pos, current_window );

end