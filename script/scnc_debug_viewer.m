runner = sbha.get_looped_make_runner();

runner.input_directories = sbha.gid( 'labels' );
runner.convert_to_non_saving_with_output();

result = runner.run( @(x) fcat.from(shared_utils.general.get(x, 'labels')) );

labs = vertcat( fcat(), result.output );

ids = combs( labs, 'identifier', find(labs, {'c-nc'}) );

%%

import shared_utils.general.map_fun;

% id = ids{1};
id = 'nc-incongruent-twotarg-14-Dec-2018 17_58_26.mat';

files = sbha.load_many( {'unified', 'edf', 'edf_sync'}, id );
% Error if any files do not match `id`
map_fun( @(x) assert(~isempty(x), 'File does not exist.'), files );

unified_file = files('unified');
edf_file = files('edf');
edf_sync_file = files('edf_sync');

%%

un_file = unified_file;

un_file.opts.SCREEN.index = 0;
% un_file.opts.SCREEN.rect = [0, 0, 800, 800];
un_file.opts.SCREEN.rect = [];

un_file.opts.STRUCTURE.n_star_frames = 25;

clock_offset = 0;
open_windows = true;

scnc.viewer.start( un_file, edf_file, edf_sync_file ...
  , 'clock_offset', clock_offset ...
  , 'open_windows', open_windows ...
);