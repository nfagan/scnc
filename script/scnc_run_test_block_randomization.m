%%  test block randomization

p = fullfile( scnc.util.get_project_folder(), 'data', 'test-block-rand' );
files = shared_utils.io.findmat( p );

for i = 1:numel(files)
  f = load( files{i} );
  
  scnc_test_block_randomization( f );
end