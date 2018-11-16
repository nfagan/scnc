function scnc_run_test_rng_config()

p = fullfile( scnc.util.get_project_folder(), 'data', 'test-rand-sequence' );

try
  files = shared_utils.io.findmat( p );
catch err
  warning( err.message )
  files = {};
end

all_directions = rowcell( numel(files) );

for i = 1:numel(files)
  f = load( files{i} );
  dat = f.DATA;
  
  directions = { dat(:).direction };
  saw_targ = [ dat(:).acquired_initial_fixation ];
  
  all_directions{i} = directions(saw_targ);  
end

min_n = min( cellfun(@numel, all_directions) );

matched_directions = cellfun( @(x) x(1:min_n), all_directions, 'un', 0 );

if ( numel(matched_directions) < 2 )
  warning( 'Not enough files to run test.' );
else
  assert( isequal(matched_directions{:}) );
end

end