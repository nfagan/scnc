
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

STIMULI = opts.STIMULI;
SCREEN = opts.SCREEN;
SERIAL = opts.SERIAL;
STRUCTURE = opts.STRUCTURE;

try
  validate_structure( STRUCTURE );
catch err
  throw( err );
end

%   SCREEN
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, SCREEN.rect );

%   WINDOW
WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

%   TRACKER
TRACKER = EyeTracker( '', cd, WINDOW.index );
TRACKER.bypass = opts.INTERFACE.use_mouse;
TRACKER.init();

%   TIMER
TIMER = Timer();
TIMER.register( opts.TIMINGS.time_in );

image_path = fullfile( scnc.util.get_project_folder(), 'stimuli', 'active' );
image_info = get_images( image_path, opts.INTERFACE.is_debug, 4 );

%   STIMULI
stim_fs = fieldnames( STIMULI.setup );
for i = 1:numel(stim_fs)
  stim = STIMULI.setup.(stim_fs{i});
  if ( ~isstruct(stim) ), continue; end;
  if ( ~isfield(stim, 'class') ), continue; end
  switch ( stim.class )
    case 'Rectangle'
      stim_ = Rectangle( windex, wrect, stim.size );
    case 'Image'
      im = stim.image_matrix;
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
  STIMULI.(stim_fs{i}) = stim_;
end

%   SERIAL
comm = serial_comm.SerialManager( SERIAL.port, struct(), SERIAL.channels );
comm.bypass = ~opts.INTERFACE.use_reward;
comm.start();
SERIAL.comm = comm;

%   EXPORT
opts.STIMULI = STIMULI;
opts.WINDOW = WINDOW;
opts.TRACKER = TRACKER;
opts.TIMER = TIMER;
opts.SERIAL = SERIAL;
opts.IMAGES = image_info;

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
      
      imgs{k} = uint8( ind2rgb(img, map) .* 255 );
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

validatestring( structure.trial_type, {'congruent', 'incongruent'} );

end