function make(ids, overwrite)

if ( nargin < 2 ), overwrite = false; end

ids = cellstr( ids );

p = fullfile( scnc.util.get_project_folder(), 'rand' );

N = numel( ids );

s = rng();

for i = 1:N
  full_id = sprintf( '%s.mat', fullfile(p, ids{i}) );
  
  if ( shared_utils.io.fexists(full_id) && ~overwrite )
    fprintf( '\n Skipping "%s" because it already exists.\n', full_id );
  end
  
  rng( 'shuffle' );
  rng_state = rng();
  
  try
    shared_utils.io.require_dir( p );
    save( full_id, 'rng_state' );
  catch err
    warning( err.message );
  end
end

rng( s );

end