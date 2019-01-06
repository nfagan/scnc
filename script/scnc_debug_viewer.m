runner = sbha.get_looped_make_runner();

runner.input_directories = sbha.gid( 'labels' );
runner.convert_to_non_saving_with_output();

result = runner.run( @(x) fcat.from(shared_utils.general.get(x, 'labels')) );

labs = vertcat( fcat(), result.output );

ids = combs( labs, 'identifier', find(labs, {'c-nc'}) );

%%

% id = ids{1};
id = 'nc-incongruent-twotarg-14-Dec-2018 17_58_26.mat';

unified_file = sbha.load1( 'unified', id );
edf_file = sbha.load1( 'edf', id );
edf_sync_file = sbha.load1( 'edf_sync', id );

%%

un_file = unified_file;

un_file.opts.SCREEN.index = 0;
un_file.opts.SCREEN.rect = [0, 0, 800, 800];
% un_file.opts.SCREEN.rect = [];

un_file.opts.STRUCTURE.n_star_frames = 100;

clock_offset = 10;
open_windows = true;

scnc.viewer.start( un_file, edf_file, edf_sync_file ...
  , 'clock_offset', clock_offset ...
  , 'open_windows', open_windows ...
);