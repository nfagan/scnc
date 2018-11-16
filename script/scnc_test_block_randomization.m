function scnc_test_block_randomization(data)

dat = data.DATA;

if ( isempty(dat) || numel(fieldnames(dat)) == 0 )
  warning( 'Data were empty; skipping test ...' );
  return
end
  
directions = { dat(:).direction };
saw_targ = [ dat(:).acquired_initial_fixation ];

blocked_directions = directions(saw_targ);
block_size = data.opts.STRUCTURE.randomization_block_size;

assert( mod(block_size, 2) == 0, 'Expected block size to be even.' );

binned = shared_utils.vector.slidebin( blocked_directions, block_size, block_size );

is_complete = cellfun( @(x) numel(x) == block_size, binned );

if ( nnz(is_complete) == 0 )
  warning( 'No block with at least %d trials was present; skipping test ...', block_size );
  return
end

binned = binned(is_complete);

counts_left = cellfun( @(x) strcmp(x, 'left'), binned, 'un', 0 );
counts_right = cellfun( @(x) strcmp(x, 'right'), binned, 'un', 0 );

crit = block_size / 2;

left_matches_crit = cellfun( @(x) nnz(x) == crit, counts_left );
right_matches_crit = cellfun( @(x) nnz(x) == crit, counts_right );

assert( all(left_matches_crit) && all(right_matches_crit) ...
  , 'Some blocks had unequal numbers of left or right trials.' );

fprintf( ['\n OK: Blocks of size %d had matching numbers of left and right' ...
  , ' trials.\n'], block_size );

end