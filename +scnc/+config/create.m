
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

try
  scnc.util.try_add_ptoolbox();
  
  KbName( 'UnifyKeyNames' );
catch err
  warning( err.message );
end

const = scnc.config.constants();

conf = struct();

% ID
conf.(const.config_id) = true;

% META
META = struct();
META.subject = '';
META.notes = '';
META.notes2 = '';

% PATHS
PATHS = struct();
PATHS.repositories = fileparts( scnc.util.get_project_folder() );
PATHS.data = fullfile( scnc.util.get_project_folder(), 'data' );

% DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'ptb_helpers', 'serial_comm', 'shared_utils' };

%	INTERFACE
INTERFACE = struct();
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.reward_key = KbName( 'r' );
INTERFACE.use_mouse = true;
INTERFACE.use_reward = false;
INTERFACE.allow_hide_mouse = true;
INTERFACE.allow_set_mouse = true;
INTERFACE.use_brains_arduino = false;
INTERFACE.is_debug = true;
INTERFACE.use_sounds = true;
INTERFACE.save = true;
INTERFACE.skip_sync_tests = false;
INTERFACE.use_auto_paths = true;
INTERFACE.debug_tags = 'all';
INTERFACE.gui_fields.exclude = { 'stop_key', 'reward_key', 'debug_tags' };

% STRUCTURE
STRUCTURE = struct();
STRUCTURE.task_type = 'c-nc';
STRUCTURE.rt_conscious_type = 'conscious';
STRUCTURE.trial_type = 'congruent';
STRUCTURE.is_masked = false;
STRUCTURE.is_two_targets = true;
STRUCTURE.rt_n_lr = 8;
STRUCTURE.rt_n_two = 2;
STRUCTURE.randomization_block_size = 6;
STRUCTURE.trial_block_size = 55;
STRUCTURE.track_n_previous_trials = 25;
STRUCTURE.correct_performance_threshold = 0.80;
STRUCTURE.n_selected_threshold = 385;
STRUCTURE.use_performance_threshold = true;
STRUCTURE.use_randomization_seed = true;
STRUCTURE.use_break = true;
STRUCTURE.show_break_images = false;
STRUCTURE.randomization_id = 'a';
STRUCTURE.stop_criterion = 'scnc.util.default_stop_criterion';
STRUCTURE.debug_stimuli_size = false;
STRUCTURE.show_feedback = true;
STRUCTURE.show_break_text = false;
STRUCTURE.rt_show_mask_target = true;
STRUCTURE.rt_is_two_targets = false;
STRUCTURE.n_star_frames = 1;
STRUCTURE.star_use_frame_count = false;
STRUCTURE.side_bias_chest_direction = 'right';

%	SCREEN
SCREEN = struct();

SCREEN.full_size = get( 0, 'screensize' );
SCREEN.index = 0;
SCREEN.background_color = [ 255 255 255 ];
SCREEN.rect = [];

%	TIMINGS
TIMINGS = struct();

time_in = struct();
time_in.new_trial = 0;
time_in.fixation = 2;
time_in.task = Inf;
time_in.present_targets = 5;
time_in.present_targets_frame_count = 5;
time_in.side_bias_present_targets = 5;
time_in.side_bias_choice_feedback = 1;
time_in.rt_present_targets = 5;
time_in.rt_response = 5;
time_in.choice_feedback = 1;
time_in.pre_mask_delay = 1e-7;  % short as possible; usually will be 16.666 ms
time_in.rt_pre_response_delay = 0.4;
time_in.iti = 1;
time_in.break_display_image = 30;
time_in.cycle_break_image = 5;
time_in.debug_stimuli_size = 100;

TIMINGS.time_in = time_in;

%	STIMULI
STIMULI = struct();
STIMULI.setup = struct();

non_editable_properties = {{ 'placement', 'image_matrix' }};

STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 100, 100 ] ...
  , 'color',            [ 0, 0, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.15 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.left_image1 =  struct( ...
    'class',            'Image' ...
  , 'size',             [ 200, 200 ] ...
  , 'image_matrix',     [] ...
  , 'color',            [ 0, 0, 255 ] ...
  , 'placement',        'center-left' ...
  , 'shift',            [ -15, 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  0.2 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.right_image1 =  struct( ...
    'class',            'Image' ...
  , 'size',             [ 200, 200 ] ...
  , 'image_matrix',     [] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'shift',            [ 15, 0 ] ...
  , 'has_target',       true ...
  , 'target_duration',  0.2 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.no_choice_indicator = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 200, 200 ] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       false ...
  , 'visible',          true ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.break_image1 = struct( ...
    'class',            'Image' ...
  , 'size',             [ 400, 400 ] ...
  , 'image_matrix',     [] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

%	SERIAL
SERIAL = struct();
SERIAL.port = 'COM4';
SERIAL.channels = { 'A' };
SERIAL.gui_fields.include = { 'port' };

% REWARDS
REWARDS = struct();
REWARDS.key_press = 100;
REWARDS.main = 300;
REWARDS.bridge = 50;
REWARDS.recurring_break = 300;

% EXPORT
conf.PATHS = PATHS;
conf.DEPENDS = DEPENDS;
conf.TIMINGS = TIMINGS;
conf.STIMULI = STIMULI;
conf.SCREEN = SCREEN;
conf.INTERFACE = INTERFACE;
conf.SERIAL = SERIAL;
conf.STRUCTURE = STRUCTURE;
conf.REWARDS = REWARDS;
conf.META = META;

if ( do_save )
  scnc.config.save( conf );
end

end