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
task_type = field_or( structure, 'task_type', 'c-nc' );
use_frame_count = field_or( structure, 'star_use_frame_count', false );
should_update_frame_count = true;

if ( strcmp(task_type, 'c-nc') )
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
elseif ( strcmp(task_type, 'rt') )
  mask_time_elapsed = check_should_escape( opts, data, 'mask_onset' );
  response_target_onset_elaped = check_should_escape( opts, data, 'rt_target_onset' );
  
  if ( response_target_onset_elaped )
    [left_image_name, right_image_name] = get_rt_response_target_image_names( trial_data );
    
%     left_image_name = 
  elseif ( mask_time_elapsed )
    left_image_name = 'two_masks__left.png';
    right_image_name = 'two_masks__right.png';
  end
else
  error( 'Unimplemented task type: "%s".', task_type );
end

if ( should_update_frame_count )
  n_cue_frames = n_cue_frames + 1;
end

try
  left_image = images(left_image_name);
  right_image = images(right_image_name);

  stimuli.left_image1.FaceColor = left_image;
  stimuli.right_image1.FaceColor = right_image;
catch err
  %
end

state.UserData.n_cue_frames = n_cue_frames;

end

function [left, right] = get_rt_response_target_image_names(trial_data)

direction = trial_data.direction;
correct_direction = char( setdiff({'left', 'right'}, direction) );

left = sprintf( '%s_mask2__left.png', correct_direction );
right = sprintf( '%s_mask2__right.png', correct_direction );

end