
function opts = setup(opts)

%   SETUP -- Prepare to run the task based on the saved config file.
%
%     Opens windows, starts EyeTracker, initializes Arduino, etc.
%
%     OUT:
%       - `opts` (struct) -- Config file, with additional parameters
%         appended.

if ( nargin < 1 || isempty(opts) )
  opts = scnc.config.load();
else
  scnc.util.assertions.assert__is_config( opts );
end

%   add missing fields to `opts` as necessary
opts = scnc.config.reconcile( opts );

try
  scnc.util.add_depends( opts );
  scnc.util.try_add_ptoolbox();
catch err
  warning( err.message );
end

try
  KbName( 'UnifyKeyNames' );
  opts.INTERFACE.stop_key = KbName( 'escape' );
  opts.INTERFACE.rating_keys = get_rating_key_codes_and_map( 4 );
catch err
  warning( err.message );
end

has_ptb = ~isempty( which('Screen') );

if ( opts.INTERFACE.skip_sync_tests && has_ptb )
  Screen( 'Preference', 'SkipSyncTests', 1 );
elseif ( has_ptb )
  Screen( 'Preference', 'SkipSyncTests', 0 );
end

STIMULI = opts.STIMULI;
SCREEN = opts.SCREEN;
SERIAL = opts.SERIAL;
STRUCTURE = opts.STRUCTURE;

try
  validate_structure( STRUCTURE );
catch err
  throw( err );
end

if ( STRUCTURE.is_randomized_frame_counts )
  STRUCTURE.frame_count_index_sampler = get_frame_count_index_sampler( STRUCTURE );
else
  STRUCTURE.frame_count_index_sampler = [];
end

if ( opts.INTERFACE.use_auto_paths )
  data_path = fullfile( scnc.util.get_project_folder(), 'data' );
else
  data_path = opts.PATHS.data;
end

root_data_path = fullfile( data_path, datestr(now, 'mmddyy') );
opts.PATHS.current_data_root = root_data_path;

shared_utils.io.require_dir( root_data_path );

%   SCREEN
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, SCREEN.rect );

%   WINDOW
WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

%   TRACKER
edf_p = fullfile( root_data_path, 'edf' );
shared_utils.io.require_dir( edf_p );

edf_filename = get_edf_filename( edf_p, 'sc' );

TRACKER = EyeTracker( edf_filename, edf_p, WINDOW.index );
TRACKER.bypass = opts.INTERFACE.use_mouse;
TRACKER.init();

%   TIMER
TIMER = Timer();
TIMER.register( opts.TIMINGS.time_in );

stimuli_p = fullfile( scnc.util.get_project_folder(), 'stimuli' );

switch ( STRUCTURE.task_type )
  case 'rt'
    image_info = get_rt_image_info( stimuli_p, opts.INTERFACE.is_debug );
  case 'c-nc'
    image_info = get_cnc_image_info( stimuli_p, opts.INTERFACE.is_debug );
  case 'side-bias'
    image_info = get_side_bias_image_info( stimuli_p, opts.INTERFACE.is_debug );
  otherwise
    error( 'Unrecognized task type "%s".', task_type );
end

if ( STRUCTURE.is_trial_by_trial_self_evaluation )
  image_info.self_evaluation = get_self_evaluation_images( stimuli_p );
end

%   STIMULI
stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = Rectangle( windex, wrect, stim.size );
    case 'Image'
      if ( isfield(stim, 'image_matrix') )
        im = stim.image_matrix;
      else
        im = [];
      end
      stim_ = Image( windex, wrect, stim.size, im );
  end
  stim_.color = stim.color;
  stim_.put( stim.placement );
  if ( stim.has_target )
    duration = stim.target_duration;
    padding = stim.target_padding;
    stim_.make_target( TRACKER, duration );
    stim_.targets{1}.padding = padding;
  end
  
  if ( isfield(stim, 'shift') )
    stim_.shift( stim.shift(1), stim.shift(2) );
  end
  
  STIMULI.(stim_fs{i}) = stim_;
end

%   SOUNDS
sounds = get_sounds( fullfile(stimuli_p, 'sounds') );

%   SERIAL
if ( opts.INTERFACE.use_brains_arduino )
  comm = brains.arduino.get_serial_comm();
else
  comm = serial_comm.SerialManager( SERIAL.port, struct(), SERIAL.channels );
end

comm.bypass = ~opts.INTERFACE.use_reward;
comm.start();
SERIAL.comm = comm;

%   RAND
RAND = struct();
RAND.original_state = rng();

if ( STRUCTURE.use_randomization_seed )
  RAND.state = get_rng_state( STRUCTURE.randomization_id );
else
  RAND.state = [];
end

%   EXPORT
opts.STIMULI = STIMULI;
opts.WINDOW = WINDOW;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.SERIAL = SERIAL;
opts.IMAGES = image_info;
opts.SOUNDS = sounds;
opts.STRUCTURE = STRUCTURE;
opts.RAND = RAND;

end

function image_info = get_cnc_image_info(stimuli_p, is_debug)

image_p = fullfile( stimuli_p, 'cnc-images' );
image_info = get_images( image_p, is_debug, 4 );

end

function image_info = get_rt_image_info(stimuli_p, is_debug)

image_p = fullfile( stimuli_p, 'rt-images' );
image_info = get_images( image_p, is_debug, 6 );

end

function image_info = get_side_bias_image_info(stimuli_p, is_debug)

image_p = fullfile( stimuli_p, 'side-bias-images' );
image_info = get_images( image_p, is_debug, Inf );

end

function sound_info = get_sounds(sound_p)

sound_info = struct();
sound_info.correct = get_sound( fullfile(sound_p, 'correct') );
sound_info.incorrect = get_sound( fullfile(sound_p, 'incorrect') );
sound_info.break = get_sound( fullfile(sound_p, 'break') );

end

function sound_info = get_sound(p)

files = shared_utils.io.find( p, {'.wav', '.mp3'} );

assert( numel(files) > 0, 'No sound files found in: "%s".', p );

file = files{1};

[read_sound, fs] = audioread( file );

sound_info = struct( 'sound', read_sound, 'fs', fs );

end

function s = get_rng_state(id)

p = fullfile( scnc.util.get_project_folder(), 'rand' );
fname = shared_utils.char.require_end( fullfile(p, id), '.mat' );

if ( ~shared_utils.io.fexists(fname) )
  error( 'Randomization with id "%s" does not exist in "%s".', id, p );
end

s = shared_utils.io.fload( fname );

end

function image_info = get_images(image_path, is_debug, max_n, subfolders)

import shared_utils.io.dirnames;
percell = @(varargin) cellfun( varargin{:}, 'un', 0 );

% walk setup
fmts = { '.png', '.jpg', '.jpeg' };
max_depth = 3;
%   exclude files that have __archive__ in them
condition_func = @(p) isempty(strfind(p, '__archive__'));
%   find files that end in any of `fmts`
find_func = @(p) percell(@(x) shared_utils.io.find(p, x), fmts);
%   include files if more than 0 files match, and condition_func returns
%   false.
include_func = @(p) condition_func(p) && numel(horzcat_mult(find_func(p))) > 0;

if ( nargin < 4 )
  subfolders = shared_utils.io.dirnames( image_path, 'folders' );
end

image_info = struct();

for i = 1:numel(subfolders)
  
  walk_func = @(p, level) ...
    deal( ...
        {horzcat_mult(percell(@(x) shared_utils.io.find(p, x), fmts))} ...
      , include_func(p) ...
    );

  [image_fullfiles, image_components] = shared_utils.io.walk( ...
      fullfile(image_path, subfolders{i}), walk_func ...
    , 'outputs', true ...
    , 'max_depth', max_depth ...
  );

  images = cell( size(image_fullfiles) );
  image_filenames = cell( size(image_fullfiles) );

  for j = 1:numel(image_fullfiles)
    if ( is_debug )
      fprintf( '\n Image set %d of %d', j, numel(image_fullfiles) );
    end
    
    fullfiles = image_fullfiles{j};
    
    use_n = min( numel(fullfiles), max_n );
    imgs = cell( use_n, 1 );
    
    for k = 1:use_n
      if ( is_debug )
        [~, filename] = fileparts( fullfiles{k} );
        fprintf( '\n\t Image "%s": %d of %d', filename, k, numel(imgs) );
      end
      
      [img, map] = imread( fullfiles{k} );
      
      if ( ~isempty(map) )
        img = ind2rgb( img, map );
      end
      
      if ( isfloat(img) )
        imgs{k} = uint8( img .* 255 );
      else
        imgs{k} = img;
      end
    end
    
    images{j} = imgs;
    image_filenames{j} = cellfun( @fname, image_fullfiles{j}, 'un', 0 );
  end

  image_info.(subfolders{i}) = [ image_components, image_fullfiles, image_filenames, images ];

end

end

function y = fname(x)
[~, y, ext] = fileparts( x );
y = [ y, ext ];
end

function y = horzcat_mult(x)
y = horzcat( x{:} );
end

function validate_structure(structure)

req_fields = { 'trial_type', 'is_masked' };

assert( all(isfield(structure, req_fields)) ...
  , 'STRUCTURE is missing one of required fields: %s' ...
  , strjoin(req_fields, ', ') );

validatestring( structure.trial_type, {'congruent', 'incongruent', 'objective'} );
validatestring( structure.task_type, {'c-nc', 'rt', 'side-bias'} );
validatestring( structure.rt_conscious_type, {'conscious', 'nonconscious'} );

if ( strcmp(structure.task_type, 'rt') )
  validateattributes( structure.rt_n_lr, {'double'}, {'even', 'scalar'}, 'rt_n_lr' );
  validateattributes( structure.rt_n_two, {'double'}, {'even', 'scalar'}, 'rt_n_lr' );
end

if ( isfield(structure, 'is_randomized_frame_counts') && structure.is_randomized_frame_counts )
  frame_counts = structure.n_star_frames;
  frame_block_size = structure.frame_count_block_size;
  
  if ( mod(frame_block_size, numel(frame_counts)) ~= 0 )
    error( 'Frame count block size must be a multiple of the number of frame counts (%d).' ...
      , numel(frame_counts) );
  end
end

end

function fname = get_edf_filename(path, prefix)

does_exist = true;
stp = 1;

while ( does_exist )
  fname = sprintf( '%s%d.edf', prefix, stp );
  does_exist = shared_utils.io.fexists( fullfile(path, fname) );
  stp = stp + 1;
end

end

function frame_count_index_sampler = get_frame_count_index_sampler(structure)

frame_counts = structure.n_star_frames;
frame_block_size = structure.frame_count_block_size;
n_blocks = 100;

frame_count_index_sampler = scnc.util.BlockedConditionSampler( n_blocks, frame_block_size, numel(frame_counts) );

end

function images = get_self_evaluation_images(stimuli_p)

full_stim_p = fullfile( stimuli_p, 'self-evaluation-images' );

evaluation_filepaths = shared_utils.io.find( full_stim_p, {'.png', '.jpeg', '.jpg'} );

is_confidence_level = cellfun( @(x) ~isempty(strfind(x, 'confidence-level')), evaluation_filepaths );

assert( any(is_confidence_level), 'No confidence-level images found.' );

confidence_level_filepath = evaluation_filepaths{find(is_confidence_level, 1)};

images = struct();
images.confidence_level = imread( confidence_level_filepath );

end

function rating_info = get_rating_key_codes_and_map(n_ratings)

assert( n_ratings <= 10 );

rating_codes = nan( 1, n_ratings );

rating_codes(1) = KbName( '`~' );

key1_code = KbName( '1!' );

key_code_rating_map = containers.Map( 'keytype', 'double', 'valuetype', 'double' );
key_code_rating_map(rating_codes(1)) = 0;

for i = 1:n_ratings-1
  rating_codes(i+1) = key1_code + i - 1;
  key_code_rating_map(rating_codes(i+1)) = i;
end

rating_info = struct();
rating_info.key_codes = rating_codes;
rating_info.key_code_rating_map = key_code_rating_map;

end