
function run(opts)

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

INTERFACE =   opts.INTERFACE;
TIMER =       opts.TIMER;
STIMULI =     opts.STIMULI;
TRACKER =     opts.TRACKER;
WINDOW =      opts.WINDOW;
STRUCTURE =   opts.STRUCTURE;
IMAGES =      opts.IMAGES;
SOUNDS =      opts.SOUNDS;
REWARDS =     opts.REWARDS;
comm =        opts.SERIAL.comm;

tracker_sync = struct();
tracker_sync.timer = NaN;
tracker_sync.interval = 1;
tracker_sync.times = [];
tracker_sync.index = 1;

%   begin in this state
cstate = 'new_trial';
first_entry = true;

stim_handles = rmfield( STIMULI, 'setup' );

trial_type = STRUCTURE.trial_type;
is_masked = STRUCTURE.is_masked;
is_two_targets = STRUCTURE.is_two_targets;

BLOCK_INDEX = 0;
TRIAL_NUMBER = 0;

DATA = struct();
events = struct();
errors = struct();

DIRECTIONS = { 'left', 'right' };

block_indices = get_block_indices( STRUCTURE.block_size );

while ( true )
  if ( isnan(tracker_sync.timer) || toc(tracker_sync.timer) >= tracker_sync.interval )
    TRACKER.send( 'RESYNCH' );
    tracker_sync.timer = tic();
    tracker_sync.times(tracker_sync.index) = TIMER.get_time( 'task' );
    tracker_sync.index = tracker_sync.index + 1;
  end

  [key_pressed, ~, key_code] = KbCheck();

  if ( key_pressed )
    if ( key_code(INTERFACE.stop_key) ), break; end
  end

  TRACKER.update_coordinates();
  structfun( @(x) x.update_targets(), stim_handles );

  %   STATE new_trial
  if ( strcmp(cstate, 'new_trial') )
    LOG_DEBUG( 'new trial', 'entry', opts );
    
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).acquired_initial_fixation = acquired_initial_fixation;
      DATA(tn).was_correct = was_correct;
      DATA(tn).made_selection = ~isnan( selected_target_index );
      DATA(tn).direction = current_direction;
      DATA(tn).selected_direction = selected_direction;
      DATA(tn).selected_target_index = selected_target_index;
      DATA(tn).image_info = get_image_name_struct( current_images );
      
      should_increment_block = acquired_initial_fixation;
    else
      should_increment_block = true;
    end
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    selected_direction = '';
    selected_target_index = nan;
    was_correct = false;
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    cue1 = STIMULI.left_image1;
    cue2 = STIMULI.right_image1;
    
    if ( BLOCK_INDEX == STRUCTURE.block_size )
      BLOCK_INDEX = 1;
      block_indices = get_block_indices( STRUCTURE.block_size );
    elseif ( should_increment_block )
      BLOCK_INDEX = BLOCK_INDEX + 1;
    end
    
    direction_indices = [1, 2];
    current_direction = DIRECTIONS{block_indices(BLOCK_INDEX)};
    
    correct_image_index = get_correct_image_index( current_direction, trial_type );
    
    current_images = get_current_images( IMAGES, current_direction, trial_type, is_masked );
    
    % assign cues
    assign_images( cue1, cue2, current_images.left_cue_image, current_images.right_cue_image );
    
    LOG_DEBUG( sprintf('TRIAL:        %d', TRIAL_NUMBER), 'param', opts );
    LOG_DEBUG( sprintf('BLOCK_INDEX:  %d', BLOCK_INDEX), 'param', opts );
    LOG_DEBUG( sprintf('DIRECTION:    %s', current_direction), 'param', opts );
    
    cstate = 'fixation';
    first_entry = true;
  end

  %   STATE fixation
  if ( strcmp(cstate, 'fixation') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      fix_square = STIMULI.fix_square;
      fix_square.reset_targets();
      
      logged_entry = false;
      acquired_initial_fixation = false;
      entered_target = false;
      drew_stimulus = false;
      first_entry = false;
    end

    if ( ~drew_stimulus )
      fix_square.draw();
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
      
      events.fixation_onset = TIMER.get_time( 'task' );
    end
    
    if ( ~logged_entry && fix_square.in_bounds() )
      events.fixation_entered = TIMER.get_time( 'task' );
      logged_entry = true;
    end

    if ( fix_square.duration_met() )
      LOG_DEBUG( 'fixation-met', 'event', opts );
      entered_target = true;
      cstate = 'present_targets';
      acquired_initial_fixation = true;
      first_entry = true;
    elseif ( entered_target && ~fix_square.in_bounds() )
      errors.broke_initial_fixation = true;
      cstate = 'new_trial';
      first_entry = true;
    end

    if ( TIMER.duration_met(cstate) && ~entered_target )
      errors.initial_fixation_not_entered = true;
      cstate = 'new_trial';
      first_entry = true;
    end
  end
  
  %   STATE present_targets
  if ( strcmp(cstate, 'present_targets') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      %   bridge reward
      comm.reward( 1, REWARDS.bridge );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      if ( ~is_two_targets )
        current_cues = current_cues(correct_image_index);
        direction_indices = direction_indices(correct_image_index);
      end
      
      pre_mask_delay = opts.TIMINGS.time_in.pre_mask_delay;
      
      entered_target = false;
      broke_target = false;
      entered_target_index = nan;
      selected_target_index = nan;
      drew_stimulus = false;
      did_show_mask = false;
      logged_entry = false;
      first_entry = false;
    end

    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      masked_timer = tic();
      drew_stimulus = true;
      
      events.target_onset = TIMER.get_time( 'task' );
    end
    
    if ( is_masked && ~did_show_mask && toc(masked_timer) > pre_mask_delay )
      assign_images( s1, s2, current_images.left_mask_cue_image, current_images.right_mask_cue_image );
      
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      
      did_show_mask = true;
      
      events.mask_onset = TIMER.get_time( 'task' );
    end
    
    for i = 1:numel(current_cues)
      stim = current_cues{i};
      
      is_ib = stim.in_bounds();
      
      if ( is_ib )
        if ( isnan(entered_target_index) )
          entered_target_index = direction_indices(i);
          
          if ( ~logged_entry )
            events.target_entered = TIMER.get_time( 'task' );
            logged_entry = true;
          end
        end
      elseif ( entered_target && entered_target_index == i )
        % broke fixation to the original target -- decide how to handle
        % this.
        broke_target = true;
      end
      
      if ( stim.duration_met() )
        LOG_DEBUG( sprintf('chose: %d', i), 'event', opts );
        selected_target_index = direction_indices(i);
        cstate = 'choice_feedback';
        
        events.target_acquired = TIMER.get_time( 'task' );
        break;
      end
    end
    
    state_dur_crit_met = TIMER.duration_met( cstate );
    error_crit_met = state_dur_crit_met && ( ~entered_target || broke_target );
    ok_crit_met = ~isnan( selected_target_index );    

    if ( ok_crit_met || error_crit_met )
      cstate = 'choice_feedback';
      first_entry = true;
    end
  end
  
  %   STATE choice_feedback
  if ( strcmp(cstate, 'choice_feedback') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      was_correct = selected_target_index == correct_image_index;
      
      if ( isnan(selected_target_index) )
        selected_direction = '';
      else
        selected_direction = DIRECTIONS{selected_target_index};
      end
      
      if ( was_correct )
        assign_images( s1, s2, current_images.left_success_image, current_images.right_success_image );
        current_sound = SOUNDS.correct;
        
        comm.reward( 1, REWARDS.main );
      else
        assign_images( s1, s2, current_images.left_err_image, current_images.right_err_image );
        current_sound = SOUNDS.incorrect;
      end
      
      current_stimuli = { s1, s2 };
      
      if ( ~is_two_targets )
        current_stimuli = current_stimuli(correct_image_index);
      end
      
      drew_stimulus = false;
      first_entry = false;
    end

    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), current_stimuli );
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
      
      events.feedback_onset = TIMER.get_time( 'task' );
      
      if ( INTERFACE.use_sounds )
        sound( current_sound.sound, current_sound.fs );
      end
    end

    if ( TIMER.duration_met(cstate) )
      cstate = 'iti';
      first_entry = true;
    end
  end
  
  %   STATE iti
  if ( strcmp(cstate, 'iti') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      first_entry = false;
    end

    if ( TIMER.duration_met(cstate) && ~entered_target )
      cstate = 'new_trial';
      first_entry = true;
    end
  end
end

TRACKER.shutdown();

if ( INTERFACE.save )
  fname = sprintf( '%s.mat', strrep(datestr(now), ':', '_') );
  save_p = opts.PATHS.data;
  
  shared_utils.io.require_dir( save_p );
  
  edf_file = TRACKER.edf;
  
  save( fullfile(save_p, fname), 'DATA', 'opts', 'edf_file', 'tracker_sync' );
end

end

function img_outs = get_current_images(images, direction, trial_type, is_masked)

base_images = images.(trial_type);
image_types = base_images(:, 1);

subdirs = { 'cue', 'error', 'success' };
[~, inds] = ismember( image_types, subdirs );

assert( ~any(inds == 0), 'Missing one of required folders: %s.', strjoin(subdirs, ', ') );

cues = base_images(inds(1), :);
cue_names = cues{:, end-1};
cue_images = cues{end};

cue_name = sprintf( '%s_cue', direction );
[cuel, cuel_name, cuer, cuer_name] = get_image( cue_images, cue_names, cue_name );

dir_specifiers = { 'L', 'R' };

if ( strcmp(trial_type, 'incongruent') )
  dir_specifiers = fliplr( dir_specifiers );
end

if ( strcmp(direction, 'left') )
  err_name = sprintf( 'wrong%s', dir_specifiers{2} );
  success_name = sprintf( 'treat%s', dir_specifiers{1} );
else
  assert( strcmp(direction, 'right') );
  err_name = sprintf( 'wrong%s', dir_specifiers{1} );
  success_name = sprintf( 'treat%s', dir_specifiers{2} );
end

if ( is_masked )
  mask_images = images.mask;
  
  err_ind = strcmp( mask_images(:, 1), 'error' );
  success_ind = strcmp( mask_images(:, 1), 'success' );
  cue_ind = strcmp( mask_images(:, 1), 'cue' );
  
  errs = mask_images(err_ind, :);
  
  err_names = errs{:, end-1};
  err_images = errs{end};

  success = mask_images(success_ind, :);
  success_names = success{:, end-1};
  success_images = success{end};
  
  mask_cues = mask_images(cue_ind, :);
  mask_cue_names = mask_cues{:, end-1};
  mask_cue_images = mask_cues{end};

  mask_cue_name = 'two_targets';
  [mask_cuel, mask_cuel_name, mask_cuer, mask_cuer_name] = get_image( mask_cue_images, mask_cue_names, mask_cue_name );
else
  errs = base_images(inds(2), :);
  err_names = errs{:, end-1};
  err_images = errs{end};

  success = base_images(inds(3), :);
  success_names = success{:, end-1};
  success_images = success{end};  
end

[err_l, err_l_name, err_r, err_r_name] = get_image( err_images, err_names, err_name );
[scc_l, scc_l_name, scc_r, scc_r_name] = get_image( success_images, success_names, success_name );

img_outs = struct();
img_outs.left_cue_image = cuel;
img_outs.right_cue_image = cuer;
img_outs.left_cue_image_name = cuel_name;
img_outs.right_cue_image_name = cuer_name;

if ( is_masked )
  img_outs.left_mask_cue_image = mask_cuel;
  img_outs.right_mask_cue_image = mask_cuer;
  img_outs.left_mask_cue_image_name = mask_cuel_name;
  img_outs.right_mask_cue_image_name = mask_cuer_name;
end

img_outs.left_err_image = err_l;
img_outs.right_err_image = err_r;
img_outs.left_err_image_name = err_l_name;
img_outs.right_err_image_name = err_r_name;

img_outs.left_success_image = scc_l;
img_outs.right_success_image = scc_r;
img_outs.left_success_image_name = scc_l_name;
img_outs.right_success_image_name = scc_r_name;

end

function [imgl, imgl_name, imgr, imgr_name] = get_image(images, names, search_for)

is_cue_name = cellfun( @(x) ~isempty(x), strfind(names, search_for) );
n_matches = nnz( is_cue_name );

is_left = is_cue_name & cellfun( @(x) ~isempty(strfind(x, '__left')), names );
is_right = is_cue_name & cellfun( @(x) ~isempty(strfind(x, '__right')), names );

assert( n_matches == 2, 'Expected 2 matches for "%s"; got %d', search_for, n_matches );
assert( nnz(is_left) == 1, 'Expected 1 left match; got %d', nnz(is_left) );
assert( nnz(is_right) == 1, 'Expected 1 right match; got %d', nnz(is_right) );

imgl = images{is_left};
imgr = images{is_right};
imgl_name = names{is_left};
imgr_name = names{is_right};

end

function assign_images(img1, img2, img_mat1, img_mat2)

img1.image = img_mat1;
img2.image = img_mat2;

end

function ind = get_correct_image_index(current_direction, trial_type)

if ( strcmp(trial_type, 'congruent') )
  inds = [1, 2];
else
  assert( strcmp(trial_type, 'incongruent') );
  
  inds = [2, 1];
end

if ( strcmp(current_direction, 'left') )
  ind = inds(1);
else
  ind = inds(2);
end

end

function LOG_DEBUG(msg, tag, opts)

if ( ~opts.INTERFACE.is_debug ), return; end

if ( nargin < 2 )
  should_display = true;
else
  tags = opts.INTERFACE.debug_tags;

  if ( ~iscell(tags) ), tags = { tags }; end

  is_all = numel(tags) == 1 && strcmp( tags, 'all' );
  should_display = is_all || ismember( tag, tags );
end

if ( should_display )
  fprintf( '\n%s', msg );
end

end

function image_names = get_image_name_struct(current_images)

copy_image_fields = { 'left_cue_image_name', 'right_cue_image_name' ...
        , 'left_err_image_name', 'right_err_image_name', 'left_success_image_name' ...
        , 'right_success_image_name' };
      
image_names = struct();

for i = 1:numel(copy_image_fields)
  image_names.(copy_image_fields{i}) = current_images.(copy_image_fields{i});
end

end
	

function inds = get_block_indices(N)

assert( mod(N, 2) == 0, 'Block size must be even.' );

inds = ones( 1, N );
n_two = floor( N / 2 );
inds(randperm(N, n_two)) = 2;

end