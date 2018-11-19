function scnc_run_test_rng_config()

p = fullfile( scnc.util.get_project_folder(), 'data', 'test-rng-config' );

try
  files = shared_utils.io.findmat( p );
catch err
  warning( err.message )
  files = {};
end

all_directions = containers.Map();

for i = 1:numel(files)
  f = load( files{i} );
  dat = f.DATA;
  
  rand_id = f.opts.STRUCTURE.randomization_id;
  
  directions = { dat(:).direction };
  saw_targ = [ dat(:).acquired_initial_fixation ];
  seen_directions = directions(saw_targ);
  
  if ( ~isKey(all_directions, rand_id) )
    all_directions(rand_id) = { seen_directions(:) };
  else
    current = all_directions(rand_id);
    all_directions(rand_id) = [ current; {seen_directions(:)} ];
  end
end

rand_ids = keys( all_directions );

for i = 1:numel(rand_ids)
  rand_id = rand_ids{i};
  
  c_directions = all_directions(rand_id);

  min_n = min( cellfun(@numel, c_directions) );

  matched_directions = cellfun( @(x) x(1:min_n), c_directions, 'un', 0 );

  if ( numel(matched_directions) < 2 )
    warning( 'Not enough files to run test for: "%s".', rand_id );
  else
    assert( isequal(matched_directions{:}) );
    fprintf( '\n Ok: randomization sequences were equivalent for: "%s".\n', rand_id );  
  end
end

fprintf( newline );

end