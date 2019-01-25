function start(unified_file, edf_file, sync_file, varargin)

params = shared_utils.general.parsestruct( make_defaults(), varargin );

open_windows = params.open_windows;

opts = ptb.Reference( unified_file.opts );
data = ptb.Reference( struct('trial_data', unified_file.DATA) );

make_task( opts );
make_windows( opts, open_windows );
make_states( opts, data );
make_stimuli( opts, params );
make_images( opts, opts.Value.WINDOW );
make_eye_data( data, edf_file, sync_file );
make_timing_data( data, params.clock_offset );

task = opts.Value.TASK;
states = opts.Value.STATES;

run( task, states('c-nc-new-trial') );

end

function defaults = make_defaults()

defaults = struct();
defaults.open_windows = true;
defaults.clock_offset = 0;
defaults.eye_position_indicator_size = 10;
defaults.eye_position_indicator_color = [255, 255, 255];

end

function make_task(opts)

task = ptb.Task();

task.Duration = Inf;
exit_on_key_down( task );

opts.Value.TASK = task;

end

function make_windows(opts, open_windows)

screen = opts.Value.SCREEN;
window = opts.Value.WINDOW;

display_window = ptb.Window();
original_window = ptb.Window( window.rect );

display_window.Index = screen.index;
display_window.Rect = screen.rect;
display_window.BackgroundColor = screen.background_color;

if ( open_windows )
  display_window.SkipSyncTests = true;
  open( display_window );
end

opts.Value.WINDOW = display_window;
opts.Value.VIEWER.original_window = original_window;

end

function make_states(opts, data)

import scnc.viewer.states.*;

states = containers.Map();

states('c-nc-fixation') = c_nc_fixation( opts, data );
states('c-nc-present-targets') = c_nc_present_targets( opts, data );
states('c-nc-new-trial') = c_nc_new_trial( opts, data );
states('c-nc-iti') = c_nc_iti( opts, data );
states('choice-feedback') = choice_feedback( opts, data );

if ( opts.Value.INTERFACE.is_debug )
  for k = keys(states)
    set_logging( states(k{1}), true );
  end
end

opts.Value.STATES = states;

end

function make_stimuli(opts, params)

original_window = opts.Value.VIEWER.original_window;
current_window = opts.Value.WINDOW;

stim_setup = opts.Value.STIMULI.setup;

stim_names = fieldnames( stim_setup );

for i = 1:numel(stim_names)
  stim_name = stim_names{i};
  stim_schema = stim_setup.(stim_name);
  
  switch ( stim_schema.placement )
    case 'center'
      pos = [ 1/2, 1/2 ];
    case 'center-left'
      pos = [ 1/4, 1/2 ];
    case 'center-right'
      pos = [ 3/4, 1/2 ];
    otherwise
      error( 'Unrecognized placement "%s".', stim_schema.placement );
  end
  
  color = set( ptb.Color(), stim_schema.color );
  
  pos = ptb.Transform( pos, 'normalized' );
  scl = ptb.Transform( stim_schema.size, 'px' );
  
  if ( isfield(stim_schema, 'shift') )
    shift = stim_schema.shift;
    amount_shift = get_normalized_value( ptb.Transform(shift), original_window );
    pos.Value = pos.Value + amount_shift;
  end
  
  stimulus = ptb.stimuli.Rect();
  stimulus.Position = pos;
  stimulus.Scale = scl;
  stimulus.FaceColor = color;
  stimulus.Window = current_window;
  
  opts.Value.STIMULI.(stim_name) = stimulus;
end

% eye position indicator
eye_position = ptb.stimuli.Rect();
eye_position.Shape = 'oval';
eye_position.Window = current_window;
eye_position.Position.Units = 'normalized';
eye_position.Scale = params.eye_position_indicator_size;
eye_position.FaceColor = params.eye_position_indicator_color;

opts.Value.STIMULI.eye_position = eye_position;

end

function make_eye_data(data, edf_file, sync_file)

data.Value.eye_data = struct();
data.Value.eye_data.x = edf_file.x;
data.Value.eye_data.y = edf_file.y;
data.Value.eye_data.t = edf_file.t;

data.Value.eye_data.mat_sync = sync_file.mat;
data.Value.eye_data.edf_sync = sync_file.edf;
data.Value.eye_data.minimum_index = 1;

end

function make_timing_data(data, clock_offset)

data.Value.timing_data = struct();
data.Value.timing_data.trial = 0;
data.Value.timing_data.n_trials = numel( data.Value.trial_data );
data.Value.timing_data.clock_offset = clock_offset;

end

function make_images(opts, window)

import scnc.viewer.util.get_images;
import shared_utils.struct.field_or;

images = containers.Map();

opts.Value.IMAGES = images;

if ( ~window.IsOpen )
  return
end

image_p = fullfile( scnc.util.get_project_folder(), 'stimuli' );
task_type = field_or( opts.Value.STRUCTURE, 'task_type', 'c-nc' );

switch ( task_type )
  case 'c-nc'
    image_info = get_images( fullfile(image_p, 'cnc-images'), true, 4 );
    use_fields = { 'congruent', 'incongruent', 'mask' };
  case 'rt'
    image_info = get_images( fullfile(image_p, 'rt-images'), true, 6 );
    use_fields = { 'cue', 'error', 'mask', 'success', 'target' };
  otherwise
    error( 'Unrecognized or unsupported task type: "%s".', task_type );
end

for i = 1:numel(use_fields)
  field = use_fields{i};
  
  if ( ~isfield(image_info, field) )
    warning( 'Expected image field: "%s"; was not present.', field );
    continue;
  end
  
  c_images = image_info.(field);
  
  for j = 1:rows(c_images)
    image_matrices = c_images{j, end};
    image_filenames = c_images{j, end-1};
    
    for k = 1:numel(image_filenames)
      if ( isKey(images, image_filenames{k}) )
        warning( 'Duplicate key: "%s".', image_filenames{k} );
      end
      
      images(image_filenames{k}) = ptb.Image( window, image_matrices{k} );
    end
  end
end

end