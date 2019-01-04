function scnc_test_rt_task_counterbalancing(data, opts)

structure = opts.STRUCTURE;

task_type = shared_utils.struct.field_or( structure, 'task_type', 'c-nc' );
assert( strcmp(task_type, 'rt'), 'Test is not valid for task type: "%s".', task_type );

n_lr = structure.rt_n_lr;
n_two = structure.rt_n_two;

did_see_target = [ data.acquired_initial_fixation ];

data(~did_see_target) = [];

trial_types = { data.direction };
target_directions = { data.rt_correct_direction };

block_size = n_lr + n_two;

n_blocks = floor( numel(data) / block_size );

for i = 1:n_blocks
  use_lr = [ n_lr/2, n_lr/2 ];
  use_two = [ n_two/2, n_two/2 ];
  
  for j = 1:block_size
    stp = (i-1) * block_size + j;
    
    tt = trial_types{stp};
    td = target_directions{stp};
    
    ind = find( strcmp({'left', 'right'}, td) );
    
    switch ( tt )
      case { 'left', 'right' }
        use_lr(ind) = use_lr(ind) - 1;
      case 'two'
        use_two(ind) = use_two(ind) - 1;
      otherwise
        error( 'Unrecognized trial type "%s".', tt );
    end
  end
  
  assert( all(use_lr == 0) && all(use_two == 0), 'Blocks were imbalanced.' );
end

end