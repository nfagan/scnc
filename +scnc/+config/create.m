
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

const = scnc.config.constants();

conf = struct();

% ID
conf.(const.config_id) = true;

% META
META = struct();
META.subject = '';
META.notes = '';

% PATHS
PATHS = struct();
PATHS.repositories = fileparts( scnc.util.get_project_folder() );
PATHS.data = fullfile( scnc.util.get_project_folder(), 'data' );

% DEPENDENCIES
DEPENDS = struct();
DEPENDS.repositories = { 'ptb_helpers', 'serial_comm' };

%	INTERFACE
INTERFACE = struct();
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.use_mouse = true;
INTERFACE.use_reward = false;
INTERFACE.use_brains_arduino = false;
INTERFACE.is_debug = true;
INTERFACE.use_sounds = true;
INTERFACE.save = true;
INTERFACE.debug_tags = 'all';
INTERFACE.gui_fields.exclude = { 'stop_key', 'debug_tags' };

% STRUCTURE
STRUCTURE = struct();
STRUCTURE.trial_type = 'congruent';
STRUCTURE.is_masked = 0;
STRUCTURE.is_two_targets = 1;
STRUCTURE.block_size = 6;

%	SCREEN
SCREEN = struct();

SCREEN.full_size = get( 0, 'screensize' );
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect = [ 0, 0, 400, 400 ];

%	TIMINGS
TIMINGS = struct();

time_in = struct();
time_in.new_trial = 0;
time_in.fixation = 1;
time_in.task = Inf;
time_in.present_targets = 2;
time_in.choice_feedback = 1;
time_in.pre_mask_delay = 1/60;
time_in.iti = 1;

TIMINGS.time_in = time_in;

%	STIMULI
STIMULI = struct();
STIMULI.setup = struct();

non_editable_properties = {{ 'placement', 'has_target', 'image_matrix' }};

STIMULI.setup.fix_square = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 50, 50 ] ...
  , 'color',            [ 255, 255, 255 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.left_image1 =  struct( ...
    'class',            'Image' ...
  , 'size',             [ 50, 50 ] ...
  , 'image_matrix',     [] ...
  , 'color',            [ 0, 0, 255 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.setup.right_image1 =  struct( ...
    'class',            'Image' ...
  , 'size',             [ 50, 50 ] ...
  , 'image_matrix',     [] ...
  , 'color',            [ 255, 0, 0 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       true ...
  , 'target_duration',  0.3 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

%	SERIAL
SERIAL = struct();
SERIAL.port = 'COM3';
SERIAL.channels = { 'A' };
SERIAL.gui_fields.include = { 'port' };

% REWARDS
REWARDS = struct();
REWARDS.key_press = 100;
REWARDS.main = 100;
REWARDS.bridge = 50;

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