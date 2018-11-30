data_p = fullfile( scnc.util.get_project_folder(), 'data', datestr(now, 'mmddyy') );
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_13_17.mat';
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_19_41';
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_28_24';
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_31_41';
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_40_25';
% data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_50_40';
data_file = 'congruent_nonconscious_two_targ_30-Nov-2018 13_54_59';

file = load( fullfile(data_p, data_file) );

%%

data = file.DATA;
did_seen_cue = [ data.acquired_initial_fixation ];

cue_on = arrayfun( @(x) x.events.cue_onset, data(did_seen_cue) );
mask_on = arrayfun( @(x) x.events.mask_onset, data(did_seen_cue) );
targ_on = arrayfun( @(x) x.events.rt_response, data(did_seen_cue) );