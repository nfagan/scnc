function v = get_random_binary_vector(n_blocks, block_size, rng_state)

validateattributes( n_blocks, {'double'}, {'scalar', 'positive', 'real'} ...
  , mfilename, 'n_blocks' );
validateattributes( block_size, {'double'}, {'scalar', 'positive', 'real', 'even'} ...
  , mfilename, 'n_blocks' );

if ( nargin < 3 )
  provided_rng_state = false;
else
  validateattributes( rng_state, {'struct'}, {'scalar'}, mfilename, 'rng_state' );
  provided_rng_state = true;
end

if ( provided_rng_state )
  orig_state = rng( rng_state );
end

N = n_blocks * block_size;
v = ones( N, 1 );
stp = 0;
half_block = block_size / 2;

for i = 1:n_blocks 
  ind_two = randperm( block_size, half_block ) + stp;
  
  v(ind_two) = 2;
  
  stp = stp + block_size;  
end

if ( provided_rng_state )
  rng( orig_state );
end

end