function scnc_run_test_masked_incongruent_timing()

p = fullfile( scnc.util.get_project_folder(), 'data', 'test-masked-incongruent-timing' );

files = shared_utils.io.findmat( p );

for i = 1:numel(files)
  f = load( files{i} );
  
  expected_time = f.opts.TIMINGS.time_in.pre_mask_delay;
  
  acquired_initial_fixation = [ f.DATA(:).acquired_initial_fixation ];
  
  acquired_init_data = f.DATA(acquired_initial_fixation);
  
	targ_onset = arrayfun( @(x) x.events.target_onset, acquired_init_data );
  mask_onset = arrayfun( @(x) x.events.mask_onset, acquired_init_data );
  
  diffs = mask_onset - targ_onset;
  
  if ( ~all(diffs > 0) )
    warning( 'Not all mask onsets were > 0.' );
  end
end

end