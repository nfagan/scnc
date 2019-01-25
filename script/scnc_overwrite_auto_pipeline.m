inputs = struct();
inputs.overwrite = true;

folders = shared_utils.io.dirnames( raw_data_p, 'folders' );

sbha.make_unified( folders, inputs );

%%

sbha.make_xls_summary( inputs, 'files_containing', 'nc-congruent-twotarg-30-Nov-2018 16_17_57'  );

%%
              
sbha.make_events( inputs );

%%

sbha.make_trials( inputs );
sbha.make_meta( inputs );
sbha.make_labels( inputs );

%%

sbha.make_edfs( inputs );
