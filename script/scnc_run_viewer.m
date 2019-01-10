import shared_utils.general.map_fun;

id = '03-Dec';

files = sbha.load_many( {'unified', 'edf', 'edf_sync'}, id );
% Error if any files do not match `id`
map_fun( @(x) assert(~isempty(x), 'File does not exist.'), files );

unified_file = files('unified');
edf_file = files('edf');
edf_sync_file = files('edf_sync');

un_file = unified_file;

un_file.opts.SCREEN.index = 0;
% un_file.opts.SCREEN.rect = [0, 0, 800, 800];
un_file.opts.SCREEN.rect = [];

% un_file.opts.STRUCTURE.n_star_frames = 25;

clock_offset = 0;
open_windows = true;

scnc.viewer.start( un_file, edf_file, edf_sync_file ...
  , 'clock_offset', clock_offset ...
  , 'open_windows', open_windows ...
);