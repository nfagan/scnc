function state = c_nc_present_targets(opts, data)

state = ptb.State();

state.Name = 'c-nc-present-targets';
state.Duration = Inf;
state.UserData = struct();

state.Entry = @(state) entry( state, opts, data );
state.Loop = @(state) loop( state, opts, data );
state.Exit = @(state) exit( state, opts, data );

end

function entry(state, opts, data)

state.UserData.n_cue_frames = 0;

end

function loop(state, opts, data)

import scnc.viewer.util.check_should_escape;

stimuli = opts.Value.STIMULI;
window = opts.Value.WINDOW;

drawables = { stimuli.left_image1, stimuli.right_image1 };

if ( window.IsOpen )
  configure_images( state, opts, data );
end

for i = 1:numel(drawables)
  draw( drawables{i}, window );
end

scnc.viewer.util.draw_eye_position( opts, data );

flip( window );

if ( check_should_escape(opts, data, 'choice_feedback') )
  escape( state );
end

end

function exit(state, opts, data)

states = opts.Value.STATES;
next( state, states('choice-feedback') );

end

function configure_images(state, opts, data)

import scnc.viewer.util.check_should_escape;
import shared_utils.struct.field_or;

images = opts.Value.IMAGES;
stimuli = opts.Value.STIMULI;
structure = opts.Value.STRUCTURE;
n_cue_frames = state.UserData.n_cue_frames;
  
trial_data = scnc.viewer.util.get_trial_data_this_trial( opts, data );
image_info = trial_data.image_info;

left_image_name = image_info.left_cue_image_name;
right_image_name = image_info.right_cue_image_name;

is_masked = structure.is_masked;
use_frame_count = field_or( structure, 'star_use_frame_count', false );
should_update_frame_count = true;

if ( is_masked )
  if ( use_frame_count )
    criterion = state.UserData.n_cue_frames == structure.n_star_frames;
  else
    % Show at least one frame of mask.
    time_elapsed = check_should_escape( opts, data, 'mask_onset' );
    criterion = time_elapsed && n_cue_frames > 0;
  end
  
  if ( criterion )
    left_image_name = 'two_targets2__left.png';
    right_image_name = 'two_targets2__right.png';
    % show mask image
    should_update_frame_count = false;
  end
end

if ( should_update_frame_count )
  n_cue_frames = n_cue_frames + 1;
end

left_image = images(left_image_name);
right_image = images(right_image_name);

stimuli.left_image1.FaceColor = left_image;
stimuli.right_image1.FaceColor = right_image;

state.UserData.n_cue_frames = n_cue_frames;

end