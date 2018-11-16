files = shared_utils.io.find( '/Users/Nick/Documents/MATLAB/repositories/scnc/data', '.mat' );

labs = fcat();
perf = nan( numel(files), 1 );

for i = 1:numel(files)
  
  all_data = load( files{i} );
  
  did_complete_trial = [ all_data.DATA(:).acquired_initial_fixation ];
  was_correct = [ all_data.DATA(:).was_correct ];
  
  perf(i) = sum( was_correct & did_complete_trial ) / sum( did_complete_trial );
  
  pre_delay = all_data.opts.TIMINGS.time_in.pre_mask_delay;
  
  if ( ~isempty(strfind(files{i}, 'shay')) )
    name = 'shay';
  else
    name = 'nick';
  end
  
  if ( pre_delay < 0.01666 )
    c_labs = fcat.create( 'delay_length', 'short', 'name', name );
  else
    c_labs = fcat.create( 'delay_length', 'long', 'name', name );
  end
  
  append( labs, c_labs );  
end

%%

pl = plotlabeled();

pl.bar( perf, labs, 'delay_length', 'name', {} )

