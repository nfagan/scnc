data_p = 'C:\Repositories\scnc\data\121018';
% filename = 'incongruent_nonconscious_two_targ_07-Dec-2018 13_33_05.mat';
% filename = 'incongruent_nonconscious_two_targ_07-Dec-2018 14_18_43.mat';
filename = 'incongruent_nonconscious_two_targ_10-Dec-2018 13_44_24.mat';

% data_p = 'C:\Repositories\scnc\data\120518_Ephron';
% filename = 'incongruent_nonconscious_two_targ_05-Dec-2018 15_07_30.mat';

data = load( fullfile(data_p, filename) );

%%
events = {data.DATA.events};

saw_targ_events = cellfun( @(x) isfield(x, 'mask_onset'), events );

events = events(saw_targ_events);

diffs = cellfun( @(x) x.mask_onset - x.target_onset, events );
diffs(isnan(diffs)) = [];