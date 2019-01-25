function state = choice_feedback(opts, data)

state = ptb.State();

state.Name = 'choice-feedback';
state.Duration = Inf;

state.Entry = @(state) entry( state, opts, data );
state.Loop = @(state) loop( state, opts, data );
state.Exit = @(state) exit( state, opts, data );

end

function entry(state, opts, data)
end

function loop(state, opts, data)

window = opts.Value.WINDOW;
left_image1 = opts.Value.STIMULI.left_image1;
right_image1 = opts.Value.STIMULI.right_image1;

if ( window.IsOpen )
  configure_images( opts, data, left_image1, right_image1 );
end

drawables = { left_image1, right_image1 };

for i = 1:numel(drawables)
  draw( drawables{i}, window );
end

scnc.viewer.util.draw_eye_position( opts, data );
flip( window );

if ( scnc.viewer.util.check_should_escape(opts, data, 'iti') )
  escape( state );
end

end

function exit(state, opts, data)

states = opts.Value.STATES;
next( state, states('c-nc-iti') );

end

function configure_images(opts, data, left_image, right_image)

images = opts.Value.IMAGES;

trial_data = scnc.viewer.util.get_trial_data_this_trial( opts, data );
image_info = trial_data.image_info;

if ( trial_data.was_correct )
  left_image_name = image_info.left_success_image_name;
  right_image_name = image_info.right_success_image_name;
else
  left_image_name = image_info.left_err_image_name;
  right_image_name = image_info.right_err_image_name;
end

left_image.FaceColor = images(left_image_name);
right_image.FaceColor = images(right_image_name);

end