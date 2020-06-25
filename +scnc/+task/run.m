
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
GIF_IMAGES =  opts.GIF_IMAGES;
SOUNDS =      opts.SOUNDS;
REWARDS =     opts.REWARDS;
comm =        opts.SERIAL.comm;

tracker_sync = struct();
tracker_sync.timer = NaN;
tracker_sync.interval = 1;
tracker_sync.times = [];
tracker_sync.index = 1;

stim_handles = rmfield( STIMULI, 'setup' );

task_type = STRUCTURE.task_type;
trial_type = STRUCTURE.trial_type;
is_masked = STRUCTURE.is_masked;
is_two_targets = STRUCTURE.is_two_targets;

TRIAL_BLOCK_INDEX = 1;
BLOCK_NUMBER = 1;
TRIAL_NUMBER = 0;

DATA = struct();
events = struct();
errors = struct();

DIRECTIONS = { 'left', 'right' };

PERFORMANCE = struct();
PERFORMANCE.index = 1;
PERFORMANCE.end = STRUCTURE.track_n_previous_trials;
PERFORMANCE.was_correct = false( PERFORMANCE.end, 1 );
PERFORMANCE.p_correct = nan;
PERFORMANCE.n_correct = 0;
PERFORMANCE.n_incorrect = 0;
PERFORMANCE.n_initiated = 0;
PERFORMANCE.n_uninitiated = 0;
PERFORMANCE.n_selected = 0;
PERFORMANCE.n_unselected = 0;
PERFORMANCE.one_star_rt = nan;
PERFORMANCE.one_star_rt_stp = 1;
PERFORMANCE.two_star_rt = nan;
PERFORMANCE.two_star_rt_stp = 1;

reward_timer = nan;
rt = nan;

if ( INTERFACE.allow_hide_mouse )
  HideCursor();
end

n_randomization_blocks = 1000;
CONDITIONS = struct();
CONDITIONS.stp = 0;

use_key_responses = INTERFACE.use_key_responses;
% left_key = INTERFACE.left_response_key;
% right_key = INTERFACE.right_response_key;

left_key = KbName( 'c' );
right_key = KbName( 'm' );

switch ( task_type )
  case 'rt'
    NEW_TRIAL_STATE = 'rt_new_trial';
    
    if ( STRUCTURE.star_use_frame_count )
      PRESENT_TARGET_STATE = 'rt_present_targets_frame_count';
    else
      PRESENT_TARGET_STATE = 'rt_present_targets';
    end
    
    n_lr = STRUCTURE.rt_n_lr;
    n_two = STRUCTURE.rt_n_two;
    n_conditions = n_lr + n_two;
    rt_block_size = n_conditions;
    
    CONDITIONS.indices = ...
      get_rt_condition_indices( rt_block_size, opts.RAND, n_conditions, n_randomization_blocks );
    CONDITIONS.matrix = get_rt_condition_matrix( n_lr/2, n_lr/2, n_two );
    
    assert( max(CONDITIONS.indices) == size( CONDITIONS.matrix, 1 ) );
    
  case 'c-nc'
    NEW_TRIAL_STATE = 'new_trial';
    
    if ( STRUCTURE.star_use_frame_count )
      PRESENT_TARGET_STATE = 'present_targets_frame_count';
    else
      PRESENT_TARGET_STATE = 'present_targets';
    end
    
    CONDITIONS.indices = get_condition_indices( STRUCTURE, opts.RAND, n_randomization_blocks );
    
  case 'side-bias'
    NEW_TRIAL_STATE = 'side_bias_new_trial';
    PRESENT_TARGET_STATE = 'side_bias_present_targets';
  otherwise
    error( 'Unrecognized task type "%s".', task_type );
end

%   begin in this state
cstate = NEW_TRIAL_STATE;
first_entry = true;

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
    
    if ( key_code(INTERFACE.reward_key) )
      if ( isnan(reward_timer) || toc(reward_timer) > 0.4 )
        comm.reward( 1, REWARDS.key_press );
        reward_timer = tic();
      end
    end
  end

  TRACKER.update_coordinates();
  structfun( @(x) x.update_targets(), stim_handles );
  
  %%   STATE rt_new_trial
  if ( strcmp(cstate, 'rt_new_trial') )
    LOG_DEBUG( cstate, 'entry', opts );
    
    is_first_trial = TRIAL_NUMBER == 0;
    
    if ( ~is_first_trial )
      made_selection = ~isnan( selected_target_index );
      
      should_increment_rand_block = acquired_initial_fixation;
      should_increment_trial_block = made_selection;
      
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).acquired_initial_fixation = acquired_initial_fixation;
      DATA(tn).was_correct = was_correct;
      DATA(tn).made_selection = made_selection;
      DATA(tn).direction = current_direction;
      DATA(tn).rt_correct_direction = correct_direction;
      DATA(tn).selected_direction = selected_direction;
      DATA(tn).selected_target_index = selected_target_index;
      DATA(tn).image_info = get_image_name_struct( current_images );
      DATA(tn).rt = rt;
      
      last_was_correct = was_correct;
      last_block_n = BLOCK_NUMBER;
      last_rand_block_number = mod( CONDITIONS.stp, STRUCTURE.randomization_block_size );
      last_direction = current_direction;
      last_selected_direction = selected_direction;
      last_trial_n = TRIAL_NUMBER;
      last_made_selection = made_selection;
      last_acquired_fixation = acquired_initial_fixation;
      last_rt = rt;
    else
      should_increment_rand_block = true;
      should_increment_trial_block = false;
      last_was_correct = false;
      acquired_initial_fixation = false;
    end
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    if ( ~is_first_trial && last_made_selection )
      PERFORMANCE = update_performance( PERFORMANCE, was_correct, current_direction, last_rt );
    end
    
    stop_criterion_met = false;
    
    if ( ~is_first_trial )
      aq_init = acquired_initial_fixation;
      
      PERFORMANCE.n_initiated = PERFORMANCE.n_initiated + double( acquired_initial_fixation );
      PERFORMANCE.n_uninitiated = PERFORMANCE.n_uninitiated + double( ~acquired_initial_fixation );
      PERFORMANCE.n_selected = PERFORMANCE.n_selected + double( aq_init && last_made_selection );
      PERFORMANCE.n_unselected = PERFORMANCE.n_unselected + double( aq_init && ~last_made_selection );
      
      %   check whether performance has been met
      stop_criterion_met = feval( STRUCTURE.stop_criterion, PERFORMANCE, opts );
    end
    
    selected_direction = '';
    selected_target_index = nan;
    was_correct = false;
    rt = nan;
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    cue1 = STIMULI.left_image1;
    cue2 = STIMULI.right_image1;
    
    next_state = 'fixation';
    
    if ( should_increment_trial_block )
      TRIAL_BLOCK_INDEX = TRIAL_BLOCK_INDEX + 1;
    end
    
    if ( TRIAL_BLOCK_INDEX > opts.STRUCTURE.trial_block_size )
      BLOCK_NUMBER = BLOCK_NUMBER + 1;
      
      if ( STRUCTURE.use_break )
        next_state = 'break_display_image';
      end
      
      TRIAL_BLOCK_INDEX = 1;
    end
    
    if ( STRUCTURE.debug_stimuli_size )
      next_state = 'debug_stimuli_size';
    end
    
    if ( CONDITIONS.stp > numel(CONDITIONS.indices) )
      CONDITIONS.stp = 1;
    elseif ( should_increment_rand_block )
      CONDITIONS.stp = CONDITIONS.stp + 1;
    end
    
    direction_indices = [1, 2];
    
    current_condition_index = CONDITIONS.indices(CONDITIONS.stp);
    current_direction = CONDITIONS.matrix{current_condition_index, 1};
    
    if ( ~strcmp(current_direction, 'two') )
      correct_direction = char( setdiff(DIRECTIONS, current_direction) );
    else
      correct_direction = CONDITIONS.matrix{current_condition_index, 2};
%       correct_image_index = direction_indices( randi(numel(direction_indices), 1) );
    end
    
    correct_image_index = get_correct_image_index( correct_direction, trial_type );
    
    rt_is_two_targets = STRUCTURE.rt_is_two_targets;
    
    if ( rt_is_two_targets )
      current_images = get_rt_current_images_two_targets( IMAGES, current_direction, correct_direction, trial_type );
    else
      current_images = get_rt_current_images( IMAGES, current_direction, correct_direction );
    end
    
    % assign cues
    assign_images( cue1, cue2, current_images.left_cue_image, current_images.right_cue_image );
    
    if ( ~is_first_trial )
      clc;
      common_print_performance();
    end
    
    if ( stop_criterion_met )
      fprintf( '\n\n\n Stop criterion met; stopping.' );
      break;
    end
    
    cstate = next_state;
    first_entry = true;
  end

  %%   STATE new_trial
  if ( strcmp(cstate, 'new_trial') )
    LOG_DEBUG( 'new trial', 'entry', opts );
    
    is_first_trial = TRIAL_NUMBER == 0;
    
    if ( ~is_first_trial )
      made_selection = ~isnan( selected_target_index );
      
      should_increment_rand_block = acquired_initial_fixation;
      should_increment_trial_block = made_selection;
      
      tn = TRIAL_NUMBER;
      
      DATA(tn).events = events;
      DATA(tn).errors = errors;
      DATA(tn).acquired_initial_fixation = acquired_initial_fixation;
      DATA(tn).was_correct = was_correct;
      DATA(tn).made_selection = made_selection;
      DATA(tn).direction = current_direction;
      DATA(tn).selected_direction = selected_direction;
      DATA(tn).selected_target_index = selected_target_index;
      DATA(tn).image_info = get_image_name_struct( current_images );
      DATA(tn).n_star_frames = current_n_star_frames;
      DATA(tn).confidence_level = confidence_level;
      
      last_was_correct = was_correct;
      last_block_n = BLOCK_NUMBER;
      last_rand_block_number = mod( CONDITIONS.stp, STRUCTURE.randomization_block_size );
      last_direction = current_direction;
      last_selected_direction = selected_direction;
      last_trial_n = TRIAL_NUMBER;
      last_made_selection = made_selection;
      last_acquired_fixation = acquired_initial_fixation;
      last_rt = rt;
    else
      should_increment_rand_block = true;
      should_increment_trial_block = false;
      last_was_correct = false;
      acquired_initial_fixation = false;
    end
    
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    
    if ( ~is_first_trial && last_made_selection )
      PERFORMANCE = update_performance( PERFORMANCE, was_correct, current_direction, last_rt );
    end
    
    stop_criterion_met = false;
    
    if ( ~is_first_trial )
      aq_init = acquired_initial_fixation;
      
      PERFORMANCE.n_initiated = PERFORMANCE.n_initiated + double( acquired_initial_fixation );
      PERFORMANCE.n_uninitiated = PERFORMANCE.n_uninitiated + double( ~acquired_initial_fixation );
      PERFORMANCE.n_selected = PERFORMANCE.n_selected + double( aq_init && last_made_selection );
      PERFORMANCE.n_unselected = PERFORMANCE.n_unselected + double( aq_init && ~last_made_selection );
      
      %   check whether performance has been met
      stop_criterion_met = feval( STRUCTURE.stop_criterion, PERFORMANCE, opts );
    end
    
    selected_direction = '';
    selected_target_index = nan;
    was_correct = false;
    confidence_level = [];
    
    events = structfun( @(x) nan, events, 'un', 0 );
    errors = structfun( @(x) false, errors, 'un', 0 );
    
    cue1 = STIMULI.left_image1;
    cue2 = STIMULI.right_image1;
    
    % default: go to fixation
    next_state = 'fixation';
    
    if ( should_increment_trial_block )
      TRIAL_BLOCK_INDEX = TRIAL_BLOCK_INDEX + 1;
      
      if ( STRUCTURE.is_randomized_frame_counts )
        increment_condition_index( STRUCTURE.frame_count_index_sampler );
      end
    end
    
    if ( STRUCTURE.is_randomized_frame_counts )
      current_star_frame_index = current_condition( STRUCTURE.frame_count_index_sampler );
    else
      current_star_frame_index = 1;
    end
    
    current_n_star_frames = STRUCTURE.n_star_frames(current_star_frame_index);
    
    if ( TRIAL_BLOCK_INDEX > opts.STRUCTURE.trial_block_size )
      BLOCK_NUMBER = BLOCK_NUMBER + 1;
      
      if ( STRUCTURE.use_break )
        next_state = 'break_display_image';
      end
      
      TRIAL_BLOCK_INDEX = 1;
    end
    
    if ( STRUCTURE.debug_stimuli_size )
      next_state = 'debug_stimuli_size';
    end
    
    if ( CONDITIONS.stp > numel(CONDITIONS.indices) )
      CONDITIONS.stp = 1;
    elseif ( should_increment_rand_block )
      CONDITIONS.stp = CONDITIONS.stp + 1;
    end
    
    direction_indices = [1, 2];
    
    current_direction_index = CONDITIONS.indices(CONDITIONS.stp);
    current_direction = DIRECTIONS{current_direction_index};
    
    correct_image_index = get_correct_image_index( current_direction, trial_type );
    
    current_images = get_current_images( IMAGES, current_direction, trial_type, is_masked );
    
    % assign cues
    assign_images( cue1, cue2, current_images.left_cue_image, current_images.right_cue_image );

    if ( isa(STIMULI.fix_square, 'Image') )
      assign_fixation_image( STIMULI.fix_square, IMAGES );
    end
    
    if ( ~is_first_trial )
      clc;
      common_print_performance();
    end
    
    if ( stop_criterion_met ) 
      fprintf( '\n\n\n Stop criterion met; stopping.' );
      break;
    end
    
    cstate = next_state;
    first_entry = true;
  end
  
  %%  STATE side_bias_new_trial
  if ( strcmp(cstate, 'side_bias_new_trial') )
    
    cue1 = STIMULI.left_image1;
    cue2 = STIMULI.right_image1;
    
    if ( strcmp(STRUCTURE.side_bias_chest_direction, 'right') )
      current_direction = 'right';
      correct_image_index = 2;
      direction_indices = 2;
    else
      current_direction = 'left';
      correct_image_index = 1;
      direction_indices = 1;
    end
    
    current_images = get_side_bias_current_images( IMAGES, current_direction );
    
%     direction_indices = [ 1, 2 ];
    
     % assign cues
    assign_images( cue1, cue2, current_images.left_cue_image, current_images.right_cue_image );

    if ( isa(STIMULI.fix_square, 'Image') )
      assign_fixation_image( STIMULI.fix_square, IMAGES );
    end
    
    cstate = 'fixation';
    first_entry = true;    
  end

  %%   STATE fixation
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
      
      c_rect = fix_square.vertices;
      cx = (c_rect(3) - c_rect(1)) / 2 + c_rect(1);
      cy = (c_rect(4) - c_rect(2)) / 2 + c_rect(2);
      sz = 60;
      new_rect = CenterRectOnPointd( [0, 0, sz, sz], cx, cy );
%       Screen( 'FillOval', WINDOW.index, [125, 125, 125], new_rect ); 
      
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
      
      events.fixation_onset = TIMER.get_time( 'task' );
    end
    
    if ( STIMULI.setup.fix_square.has_target )
      %   Use fixation target
      if ( ~logged_entry && fix_square.in_bounds() )
        events.fixation_entered = TIMER.get_time( 'task' );
        logged_entry = true;
      end

      if ( fix_square.duration_met() )
        LOG_DEBUG( 'fixation-met', 'event', opts );
        entered_target = true;
        cstate = PRESENT_TARGET_STATE;
        acquired_initial_fixation = true;
        first_entry = true;
      elseif ( entered_target && ~fix_square.in_bounds() )
        errors.broke_initial_fixation = true;
        cstate = NEW_TRIAL_STATE;
        first_entry = true;
      elseif ( TIMER.duration_met(cstate) && ~entered_target )
        errors.initial_fixation_not_entered = true;
        cstate = 'iti';
        first_entry = true;
      end
    else
      acquired_initial_fixation = true;
      entered_target = true;
      
      %   Just wait for the state to end.
      if ( TIMER.duration_met(cstate) )
        cstate = PRESENT_TARGET_STATE;
        first_entry = true;
      end
    end
  end
  
  %   STATE debug_stimuli_size
  
  if ( strcmp(cstate, 'debug_stimuli_size') )
    if ( first_entry )
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      did_show = false;
      first_entry = false;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
    end
    
    if ( ~did_show )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      
      did_show = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = NEW_TRIAL_STATE;
      first_entry = true;
    end
  end
  
  %%  STATE rt_present_targets
  if ( strcmp(cstate, 'rt_present_targets') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      %   bridge reward
      comm.reward( 1, REWARDS.bridge );
      
      if ( INTERFACE.use_mouse && INTERFACE.allow_set_mouse )
        SetMouse( opts.WINDOW.center(1), opts.WINDOW.center(2) );
      end
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      pre_mask_delay = opts.TIMINGS.time_in.(cstate);
      remaining_time = opts.TIMINGS.time_in.pre_mask_delay;
      
      drew_stimulus = false;
      did_show_mask = false;
      logged_entry = false;
      first_entry = false;
    end

    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      
      events.cue_onset = TIMER.get_time( 'task' );
      
      masked_timer = tic();
      drew_stimulus = true;
    end
    
    if ( ~did_show_mask && toc(masked_timer) > pre_mask_delay )      
      assign_images( s1, s2, current_images.left_mask_cue_image ...
        , current_images.right_mask_cue_image );
      
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      
      did_show_mask = true;
      
      events.mask_onset = TIMER.get_time( 'task' );
      
      remaining_timer = tic();
    end
    
    if ( did_show_mask && toc(remaining_timer) >= remaining_time )      
      cstate = 'rt_response';
      first_entry = true;
    end
  end
  
  %%  STATE rt_present_targets_frame_count
  if ( strcmp(cstate, 'rt_present_targets_frame_count') )
    if ( first_entry )
      LOG_DEBUG( 'rt_present_targets', 'entry', opts );
      TIMER.reset_timers( 'rt_present_targets' );
      
      % Use event time with the same name as 'rt_present_targets';
      events.rt_present_targets = TIMER.get_time( 'task' );
      
      %   bridge reward
      comm.reward( 1, REWARDS.bridge );
      
      if ( INTERFACE.use_mouse && INTERFACE.allow_set_mouse )
        SetMouse( opts.WINDOW.center(1), opts.WINDOW.center(2) );
      end
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      current_star_frame = 1;
      n_star_frames = STRUCTURE.n_star_frames;
      
      remaining_time = opts.TIMINGS.time_in.pre_mask_delay;
      
      drew_stimulus = false;
      did_show_mask = false;
      logged_entry = false;
      logged_cue_onset = false;
      first_entry = false;
    end
    
    if ( current_star_frame <= n_star_frames )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
      
      if ( ~logged_cue_onset )
        events.cue_onset = TIMER.get_time( 'task' );
        logged_cue_onset = true;
      end
      
      current_star_frame = current_star_frame + 1;
    elseif ( ~did_show_mask )
      assign_images( s1, s2, current_images.left_mask_cue_image, current_images.right_mask_cue_image );

      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );

      did_show_mask = true;

      events.mask_onset = TIMER.get_time( 'task' );
      
      remaining_timer = tic();
    end
    
    if ( did_show_mask && toc(remaining_timer) > remaining_time )
      cstate = 'rt_response';
      first_entry = true;
    end
  end
  
  
  %%  STATE rt_delay
  if ( strcmp(cstate, 'rt_pre_response_delay') )
    current_pre_response_delay = opts.TIMINGS.time_in.(cstate);
    
    if ( current_pre_response_delay > 0 )
      if ( first_entry )
        Screen( 'Flip', opts.WINDOW.index );

        cstate_timer = tic();
        first_entry = false;
      end

      if ( toc(cstate_timer) >= current_pre_response_delay )
        cstate = 'rt_response';
        first_entry = true;
      end
    else
      cstate = 'rt_response';
      first_entry = true;
    end
  end
  
  %%  STATE rt_response
  if ( strcmp(cstate, 'rt_response') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      if ( INTERFACE.use_mouse )
        [last_x, last_y] = GetMouse();
      end
      
      l_image = current_images.left_response_image;
      r_image = current_images.right_response_image;
      
      assign_images( s1, s2, l_image, r_image );
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      if ( ~STRUCTURE.rt_show_mask_target )
        if ( strcmp(correct_direction, 'left') )
          draw_cues = { s1 };
        else
          draw_cues = { s2 };
        end
      else
        draw_cues = current_cues;
      end
      
      is_rt_forced_correct_target = STRUCTURE.rt_forced_correct_target;
      
      entered_target = false;
      broke_target = false;
      entered_target_index = nan;
      selected_target_index = nan;
      drew_stimulus = false;
      logged_key_event = false;
      
      first_entry = false;
    end
    
    if ( INTERFACE.use_mouse )
      [curr_x, curr_y] = GetMouse();
      
      if ( curr_x ~= last_x || curr_y ~= last_y )
        ShowCursor();
      end
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), draw_cues );
      Screen( 'Flip', opts.WINDOW.index );
      
      events.rt_target_onset = TIMER.get_time( 'task' );
      
      drew_stimulus = true;
%       rt_timer = tic;
    end
    
    if ( use_key_responses )
      % Key response
      if ( key_code(left_key) )
        if ( ~is_rt_forced_correct_target || direction_indices(1) == correct_image_index )
          selected_target_index = direction_indices(1);
        end
      elseif ( key_code(right_key) )
        if ( ~is_rt_forced_correct_target || direction_indices(2) == correct_image_index )
          selected_target_index = direction_indices(2);
        end
      end
      
      if ( ~isnan(selected_target_index) && ~logged_key_event )
        events.target_acquired = TIMER.get_time( 'task' );
        logged_key_event = true;
        entered_target = true;
      end
    else
      % Gaze / mouse response
      for i = 1:numel(current_cues)
        if ( STRUCTURE.rt_forced_correct_target && direction_indices(i) ~= correct_image_index )
          continue;
        end

        stim = current_cues{i};

        is_ib = stim.in_bounds();

        if ( is_ib )
          if ( isnan(entered_target_index) )
            entered_target_index = direction_indices(i);

            if ( ~logged_entry )
              events.target_entered = TIMER.get_time( 'task' );

  %             rt = toc( rt_timer );

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

          choice_time = STIMULI.setup.left_image1.target_duration;

          rt = events.target_acquired - events.rt_target_onset - choice_time;
          break;
        end
      end
    end
    
    state_dur_crit_met = TIMER.duration_met( cstate );
    error_crit_met = state_dur_crit_met && ( ~entered_target || broke_target );
    ok_crit_met = ~isnan( selected_target_index );    

    if ( ok_crit_met || error_crit_met )
      cstate = 'choice_feedback';
      
      first_entry = true;
      
      if ( INTERFACE.allow_hide_mouse )
        HideCursor();
      end
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'choice_feedback';
      first_entry = true;
    end
  end
  
  %%  STATE side_bias_present_targets
  
  if ( strcmp(cstate, 'side_bias_present_targets') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      if ( strcmp(current_direction, 'right') )
        current_cues = { s2 };
      else
        current_cues = { s1 };
      end
      
      cellfun( @(x) x.reset_targets(), current_cues );
      
      entered_target = false;
      broke_target = false;
      entered_target_index = nan;
      selected_target_index = nan;
      drew_stimulus = false;
      
      first_entry = false;
    end
    
    if ( ~drew_stimulus )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'Flip', opts.WINDOW.index );
      
      drew_stimulus = true;
%       rt_timer = tic;
    end
    
    for i = 1:numel(current_cues)
      stim = current_cues{i};
      
      is_ib = stim.in_bounds();
      
      if ( is_ib )
        if ( isnan(entered_target_index) )
          entered_target_index = direction_indices(i);
          
          if ( ~logged_entry )
            events.target_entered = TIMER.get_time( 'task' );
            
%             rt = toc( rt_timer );
            
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
        
        if ( STRUCTURE.show_feedback )
          cstate = 'side_bias_choice_feedback';
        else
          cstate = 'iti';
        end
        
        events.target_acquired = TIMER.get_time( 'task' );
        
        choice_time = STIMULI.setup.left_image1.target_duration;
        break;
      end
    end
    
    state_dur_crit_met = TIMER.duration_met( cstate );
    error_crit_met = state_dur_crit_met && ( ~entered_target || broke_target );
    ok_crit_met = ~isnan( selected_target_index );    

    if ( ok_crit_met || error_crit_met )
      cstate = 'choice_feedback';
      
      first_entry = true;
      
      if ( INTERFACE.allow_hide_mouse )
        HideCursor();
      end
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = 'choice_feedback';
      first_entry = true;
    end
  end
  
  %%  STATE present_targets_frame_count
  
  if ( strcmp(cstate, 'present_targets_frame_count') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      %   bridge reward
      comm.reward( 1, REWARDS.bridge );
      
      if ( INTERFACE.use_mouse && INTERFACE.allow_set_mouse )
        SetMouse( opts.WINDOW.center(1), opts.WINDOW.center(2) );
      end
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      if ( ~is_two_targets )
        current_cues = current_cues(correct_image_index);
        direction_indices = direction_indices(correct_image_index);
      end
      
      if ( INTERFACE.use_mouse )
        [last_x, last_y] = GetMouse();
      end
      
      current_star_frame = 1;
      
      logged_target_onset = false;
      
      entered_target = false;
      broke_target = false;
      entered_target_index = nan;
      selected_target_index = nan;
      drew_stimulus = false;
      did_show_mask = false;
      logged_entry = false;
      logged_key_event = false;
      first_entry = false;
    end
    
    if ( INTERFACE.use_mouse )
      [curr_x, curr_y] = GetMouse();
      
      if ( curr_x ~= last_x || curr_y ~= last_y )
        ShowCursor();
      end
    end
    
    if ( current_star_frame <= current_n_star_frames )
      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );
      drew_stimulus = true;
      
      if ( ~logged_target_onset )
        events.target_onset = TIMER.get_time( 'task' );
        logged_target_onset = true;
      end
      
      current_star_frame = current_star_frame + 1;
    elseif ( is_masked && ~did_show_mask )
      assign_images( s1, s2, current_images.left_mask_cue_image, current_images.right_mask_cue_image );

      cellfun( @(x) x.draw(), current_cues );
      Screen( 'flip', WINDOW.index );

      did_show_mask = true;

      events.mask_onset = TIMER.get_time( 'task' );
    end
    
    if ( use_key_responses )
      if ( key_code(left_key) )
        selected_target_index = direction_indices(1);
      elseif ( key_code(right_key) )
        selected_target_index = direction_indices(2);
      end
      
      if ( ~isnan(selected_target_index) && ~logged_key_event )
        events.target_acquired = TIMER.get_time( 'task' );
        logged_key_event = true;
        entered_target = true;
      end
    else
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

          if ( STRUCTURE.is_trial_by_trial_self_evaluation )
            cstate = 'self_evaluation';
          else
            cstate = 'choice_feedback';
          end

          events.target_acquired = TIMER.get_time( 'task' );
          break;
        end
      end
    end
    
    state_dur_crit_met = TIMER.duration_met( cstate );
    error_crit_met = state_dur_crit_met && ( ~entered_target || broke_target );
    ok_crit_met = ~isnan( selected_target_index );    

    if ( ok_crit_met || error_crit_met )
      if ( STRUCTURE.is_trial_by_trial_self_evaluation )
        cstate = 'self_evaluation';
      else
        cstate = 'choice_feedback';
      end
      
      first_entry = true;
      
      if ( INTERFACE.allow_hide_mouse )
        HideCursor();
      end
    end
  end
  
  %%  STATE present_targets
  if ( strcmp(cstate, 'present_targets') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      %   bridge reward
      comm.reward( 1, REWARDS.bridge );
      
      if ( INTERFACE.use_mouse && INTERFACE.allow_set_mouse )
        SetMouse( opts.WINDOW.center(1), opts.WINDOW.center(2) );
      end
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      current_cues = { s1, s2 };
      cellfun( @(x) x.reset_targets(), current_cues );
      
      if ( ~is_two_targets )
        current_cues = current_cues(correct_image_index);
        direction_indices = direction_indices(correct_image_index);
      end
      
      pre_mask_delay = opts.TIMINGS.time_in.pre_mask_delay;
      
      if ( INTERFACE.use_mouse )
        [last_x, last_y] = GetMouse();
      end
      
      entered_target = false;
      broke_target = false;
      entered_target_index = nan;
      selected_target_index = nan;
      drew_stimulus = false;
      did_show_mask = false;
      logged_entry = false;
      logged_key_event = false;
      first_entry = false;
    end
    
    if ( INTERFACE.use_mouse )
      [curr_x, curr_y] = GetMouse();
      
      if ( curr_x ~= last_x || curr_y ~= last_y )
        ShowCursor();
      end
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
    
    if ( use_key_responses )
      if ( key_code(left_key) )
        selected_target_index = direction_indices(1);
      elseif ( key_code(right_key) )
        selected_target_index = direction_indices(2);
      end
      
      if ( ~isnan(selected_target_index) && ~logged_key_event )
        events.target_acquired = TIMER.get_time( 'task' );
        logged_key_event = true;
        entered_target = true;
      end
    else
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
    end
    
    state_dur_crit_met = TIMER.duration_met( cstate );
    error_crit_met = state_dur_crit_met && ( ~entered_target || broke_target );
    ok_crit_met = ~isnan( selected_target_index );    

    if ( ok_crit_met || error_crit_met )
      cstate = 'choice_feedback';
      
      first_entry = true;
      
      if ( INTERFACE.allow_hide_mouse )
        HideCursor();
      end
    end
  end
  
  %%  STATE side_bias_choice_feedback
  if ( strcmp(cstate, 'side_bias_choice_feedback') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      was_correct = selected_target_index == correct_image_index;
      made_select = ~isnan( selected_target_index );
      
      if ( isnan(selected_target_index) )
        selected_direction = '';
      else
        selected_direction = DIRECTIONS{selected_target_index};
      end
      
      if ( made_select )
        if ( was_correct )
          assign_images( s1, s2, current_images.left_success_image, current_images.right_success_image );
          current_sound = SOUNDS.correct;

          comm.reward( 1, REWARDS.main );
        else
          assign_images( s1, s2, current_images.left_err_image, current_images.right_err_image );
          current_sound = SOUNDS.incorrect;
        end
      end
      
      current_stimuli = { s1, s2 };
      
      if ( ~is_two_targets )
        current_stimuli = current_stimuli(correct_image_index);
        use_correct_image_index = 1;
      else
        use_correct_image_index = correct_image_index;
      end
      
      drew_stimulus = false;
      first_entry = false;
    end

    if ( ~drew_stimulus )
      if ( ~made_select )
        Screen( 'BlendFunction', WINDOW.index, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
      end
      
      cellfun( @(x) x.draw(), current_stimuli );
      
      if ( ~made_select )
        mask_color = [ STIMULI.setup.no_choice_indicator.color, 125 ];
        
        if ( STIMULI.setup.no_choice_indicator.visible )
          Screen( 'FillRect', WINDOW.index, mask_color ...
            , current_stimuli{use_correct_image_index}.vertices );
          fprintf( '\n Drawing ... ' );
        end
      end
      
      Screen( 'flip', WINDOW.index );
      
      if ( ~made_select )
        Screen( 'BlendFunction', WINDOW.index, GL_ONE, GL_ZERO );
      end
      
      drew_stimulus = true;
      
      events.feedback_onset = TIMER.get_time( 'task' );
      
      if ( made_select && INTERFACE.use_sounds )
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

    if ( TIMER.duration_met(cstate) )
      cstate = NEW_TRIAL_STATE;
      first_entry = true;
    end
  end
  
  
  %%  STATE choice_feedback
  if ( strcmp(cstate, 'choice_feedback') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      TIMER.reset_timers( cstate );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      s1 = STIMULI.left_image1;
      s2 = STIMULI.right_image1;
      
      was_correct = selected_target_index == correct_image_index;
      made_select = ~isnan( selected_target_index );
      
      if ( isnan(selected_target_index) )
        selected_direction = '';
      else
        selected_direction = DIRECTIONS{selected_target_index};
      end
      
      if ( made_select )
        if ( was_correct )
          assign_images( s1, s2, current_images.left_success_image, current_images.right_success_image );
          current_sound = SOUNDS.correct;

          comm.reward( 1, REWARDS.main );
        else
          assign_images( s1, s2, current_images.left_err_image, current_images.right_err_image );
          current_sound = SOUNDS.incorrect;
        end
      end
      
      current_stimuli = { s1, s2 };
      
      if ( ~is_two_targets )
        current_stimuli = current_stimuli(correct_image_index);
        use_correct_image_index = 1;
      else
        use_correct_image_index = correct_image_index;
      end
      
      if ( ~STRUCTURE.rt_show_mask_target )
        if ( strcmp(correct_direction, 'left') )
          current_stimuli = { s1 };
        else
          current_stimuli = { s2 };
        end
      end
      
      show_feedback = STRUCTURE.show_feedback;
      use_gif_rewards = STRUCTURE.use_gif_rewards;
      gif_image_sets = GIF_IMAGES.images;
      
      if ( ~isempty(gif_image_sets) )
        gif_image_set = gif_image_sets{randi(numel(gif_image_sets))};
      else
        gif_image_set = [];
      end
      
      if ( ~show_feedback )
        TIMER.set_durations( 'choice_feedback', 0 );
      end
      
      if ( use_gif_rewards )
        gif_updater = STRUCTURE.gif_updater;
        gif_reward_image = STIMULI.gif_reward_image;
        reset( gif_updater );
      end
      
      logged_feedback_onset_time = false;
      drew_stimulus = false;
      played_feedback_sound = false;
      first_entry = false;
    end

    if ( use_gif_rewards )
      if ( made_select && INTERFACE.use_sounds && ~played_feedback_sound )
        sound( current_sound.sound, current_sound.fs );
        played_feedback_sound = true;
      end
      if ( was_correct )
        should_display_gif_frame = update( gif_updater );

        if ( should_display_gif_frame )
          if ( ~isempty(gif_image_set) )
            correct_img = current_stimuli{correct_image_index};
            [cx, cy] = RectCenterd( correct_img.vertices );
            amt_shift = STIMULI.setup.gif_reward_image.shift;
            
            if ( ~isempty(amt_shift) )
              cx = cx + amt_shift(1);
              cy = cy + amt_shift(2);
            end
            
            new_verts = CenterRectOnPointd( gif_reward_image.vertices, cx, cy );
            tex_handle = next_frame( gif_image_set );

            Screen( 'DrawTexture', WINDOW.index, tex_handle, [], new_verts );
            cellfun( @(x) x.draw(), current_stimuli );
            Screen( 'flip', WINDOW.index );
          end
        end
      else
        cellfun( @(x) x.draw(), current_stimuli );
        Screen( 'flip', WINDOW.index );
      end
      if ( ~logged_feedback_onset_time )
        events.feedback_onset = TIMER.get_time( 'task' );
        logged_feedback_onset_time = true;
      end
    else
      if ( show_feedback && ~drew_stimulus )
        if ( ~made_select )
          Screen( 'BlendFunction', WINDOW.index, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
        end

        cellfun( @(x) x.draw(), current_stimuli );

        if ( ~made_select )
          mask_color = [ STIMULI.setup.no_choice_indicator.color, 125 ];

          if ( STIMULI.setup.no_choice_indicator.visible )
            Screen( 'FillRect', WINDOW.index, mask_color ...
              , current_stimuli{use_correct_image_index}.vertices );
            fprintf( '\n Drawing ... ' );
          end
        end

        Screen( 'flip', WINDOW.index );

        if ( ~made_select )
          Screen( 'BlendFunction', WINDOW.index, GL_ONE, GL_ZERO );
        end

        drew_stimulus = true;

        events.feedback_onset = TIMER.get_time( 'task' );

        if ( made_select && INTERFACE.use_sounds )
          sound( current_sound.sound, current_sound.fs );
        end
      end
    end

    if ( TIMER.duration_met(cstate) )
      cstate = 'iti';
      
      first_entry = true;
    end
  end
  
  %%  STATE self_evaluation
  if ( strcmp(cstate, 'self_evaluation') )
    if ( first_entry )
      Screen( 'flip', WINDOW.index );
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      cellfun( @(x) x.draw(), current_cues );
      
      rating_key_codes = INTERFACE.rating_keys.key_codes;
      rating_key_map = INTERFACE.rating_keys.key_code_rating_map;
      
      STIMULI.confidence_level_image1.image = IMAGES.self_evaluation.confidence_level;
      draw( STIMULI.confidence_level_image1 );
      
      Screen( 'flip', WINDOW.index );
      
      if ( STRUCTURE.require_key_press_to_exit_self_evaluation )
        self_eval_next_state = 'break_key_press_to_exit';
      else
        self_eval_next_state = 'choice_feedback';
      end
      
      first_entry = false;
    end
    
    confidence_level = get_confidence_level_from_key_press_or_null( rating_key_codes, rating_key_map );
    
    if ( ~isempty(confidence_level) )
      cstate = self_eval_next_state;
      first_entry = true;
    end
    
    if ( TIMER.duration_met(cstate) )
      cstate = self_eval_next_state;
      first_entry = true;
    end
  end
  
  %%   STATE break_display_image
  if ( strcmp(cstate, 'break_display_image') )
    if ( first_entry )
      LOG_DEBUG( cstate, 'entry', opts );
      Screen( 'flip', WINDOW.index );
      TIMER.reset_timers( cstate );
      TIMER.reset_timers( 'cycle_break_image' );
      
      if ( STRUCTURE.require_key_press_to_exit_break )
        next_state_name = 'break_key_press_to_exit';
      else
        next_state_name = NEW_TRIAL_STATE;
      end
      
      events.(cstate) = TIMER.get_time( 'task' );
      
      break_img = STIMULI.break_image1;
      current_stimuli = { break_img };
      
      first_entry = false;
      drew_stimulus = false;
      logged_onset = false;
      
      last_index = 1;
    end
    
    if ( TIMER.duration_met('cycle_break_image') )
      drew_stimulus = false;
      TIMER.reset_timers( 'cycle_break_image' );
    end
    
    if ( ~drew_stimulus )
      
      if ( STRUCTURE.show_break_images )
        last_index = configure_break_image( break_img, IMAGES, last_index );
        cellfun( @(x) x.draw(), current_stimuli );
      end
      
      if ( STRUCTURE.show_break_text )
        break_text = sprintf( 'BREAK: %d seconds.', opts.TIMINGS.time_in.(cstate) );
        w_center = WINDOW.center;
        Screen( 'DrawText', WINDOW.index, break_text, w_center(1), w_center(2) );
      end
      
      if ( STRUCTURE.show_break_images || STRUCTURE.show_break_text )
        Screen( 'flip', WINDOW.index );
      end
      
      drew_stimulus = true;
      
      if ( ~logged_onset )
        events.break_display_image_onset = TIMER.get_time( 'task' );
        logged_onset = true;
      end
      
      comm.reward( 1, REWARDS.recurring_break );
    end

    if ( TIMER.duration_met(cstate) )
      cstate = next_state_name;
      first_entry = true;
    end
  end
  
  %%  STATE break_key_press_to_exit
  if ( strcmp(cstate, 'break_key_press_to_exit') )
    if ( first_entry )
      first_entry = false;
      drew_text = false;
    end
    
    if ( ~drew_text )
      break_text = 'Press space to continue.';
      w_center = WINDOW.center;
      Screen( 'DrawText', WINDOW.index, break_text, w_center(1), w_center(2) );
      Screen( 'Flip', WINDOW.index );
      drew_text = true;
    end
    
    if ( drew_text && key_code(KbName('space')) )
      first_entry = true;
      
      if ( STRUCTURE.is_trial_by_trial_self_evaluation )
        cstate = 'choice_feedback';
      else
        cstate = NEW_TRIAL_STATE;
      end
    end
  end
end

try
  clc;
  LOG_DEBUG( sprintf('TRIAL:         %d', last_trial_n), 'param', opts );
  LOG_DEBUG( sprintf('BLOCK:         %d', last_block_n), 'param', opts );
  LOG_DEBUG( sprintf('RAND_BLOCK:    %d', last_rand_block_number), 'param', opts );
  LOG_DEBUG( sprintf('DIRECTION:     %s', last_direction), 'param', opts );
  fprintf( '\n' );
  LOG_DEBUG( sprintf('SELECTED:      %s', last_selected_direction), 'performance', opts );
  LOG_DEBUG( sprintf('WAS CORRECT:   %d', last_was_correct), 'performance', opts );
  LOG_DEBUG( sprintf('FIX ACQUIRED:  %d', last_acquired_fixation), 'performance', opts );
  LOG_DEBUG( sprintf('DID SELECT:    %d', last_made_selection), 'performance', opts );
  LOG_DEBUG( sprintf('LAST RT:       %0.3f', last_rt), 'performance', opts );
  
  print_performance( PERFORMANCE, opts );
catch err
  warning( err.message );
end

try
  Screen( 'Flip', opts.WINDOW.index );
  ShowCursor();
catch err
end

s = warning( 'off', 'all' );
TRACKER.shutdown();
warning( s );

if ( STRUCTURE.use_randomization_seed )
  rng( opts.RAND.original_state );
end

if ( INTERFACE.save )
  fname = get_data_filename( opts );
  save_p = opts.PATHS.current_data_root;
  
  shared_utils.io.require_dir( save_p );
  
  edf_file = TRACKER.edf;
  
  opts.PERFORMANCE = PERFORMANCE;
  opts.CONDITIONS = CONDITIONS;
  
  save( fullfile(save_p, fname), 'DATA', 'opts', 'edf_file', 'tracker_sync' );
end

  function common_print_performance()
    try
      LOG_DEBUG( sprintf('TRIAL:         %d', last_trial_n), 'param', opts );
      LOG_DEBUG( sprintf('BLOCK:         %d', last_block_n), 'param', opts );
      LOG_DEBUG( sprintf('RAND_BLOCK:    %d', last_rand_block_number), 'param', opts );
      LOG_DEBUG( sprintf('DIRECTION:     %s', last_direction), 'param', opts );
      fprintf( '\n' );
      LOG_DEBUG( sprintf('SELECTED:      %s', last_selected_direction), 'performance', opts );
      LOG_DEBUG( sprintf('WAS CORRECT:   %d', last_was_correct), 'performance', opts );
      LOG_DEBUG( sprintf('FIX ACQUIRED:  %d', last_acquired_fixation), 'performance', opts );
      LOG_DEBUG( sprintf('DID SELECT:    %d', last_made_selection), 'performance', opts );
      LOG_DEBUG( sprintf('LAST RT:       %0.3f', last_rt), 'performance', opts );
      
      print_performance( PERFORMANCE, opts );
    catch err
      warning( err.message );
    end
  end

end

function fname = get_data_filename(opts)

structure = opts.STRUCTURE;

trial_type_str = structure.trial_type;

if ( structure.is_masked )
  conscious_str = 'nonconscious';
else
  conscious_str = 'conscious';
end

if ( structure.is_two_targets )
  targ_str = 'two_targ';
else
  targ_str = 'one_targ';
end

date_str = strrep( datestr(now), ':', '_' );

fname = sprintf( '%s_%s_%s_%s.mat', trial_type_str, conscious_str, targ_str, date_str );

end

function assign_fixation_image(img, images)

fixation_images = images.fixation;

img_matrices = fixation_images{end};
n_img_matrices = numel( img_matrices );

ind = randi( n_img_matrices, 1 );

img.image = img_matrices{ind};

end

function ind = configure_break_image(img, images, last_index)

break_images = images.break;

img_matrices = break_images{end};
n_img_matrices = numel( img_matrices );

ind = randi( n_img_matrices, 1 );

if ( nargin > 2 )
  while ( n_img_matrices > 1 && ind == last_index )
    ind = randi( n_img_matrices, 1 );
  end  
  if ( ind > n_img_matrices )
    ind = n_img_matrices;
  end
end

img.image = img_matrices{ind};

end

function img_outs = get_rt_current_images_two_targets(images, direction, correct_direction, trial_type)

assert( strcmp(trial_type, 'congruent') ...
  , sprintf('Expected trial type to be congruent; was "%s".', trial_type) );

cues = images.cue;
cue_names = cues{:, end-1};
cue_images = cues{:, end};

cue_name = sprintf( '%s_cue', direction );
[cuel, cuel_name, cuer, cuer_name] = get_image( cue_images, cue_names, cue_name );

masks = images.mask;
mask_names = masks{:, end-1};
mask_images = masks{end};

mask_name = 'two_masks';
[mask_cuel, mask_cuel_name, mask_cuer, mask_cuer_name] = get_image( mask_images, mask_names, mask_name );

targets = images.target;
target_names = targets{:, end-1};
target_images = targets{:, end};

[targl, targl_name, ~, ~] = get_image( target_images, target_names, 'left_chest' );
[~, ~, targr, targr_name] = get_image( target_images, target_names, 'right_chest' );

success_cues = images.success;
success_cue_names = success_cues{:, end-1};
success_cue_images = success_cues{:, end};

err_cues = images.error;
err_cue_names = err_cues{:, end-1};
err_cue_images = err_cues{:, end};

if ( strcmp(correct_direction, 'left') )
  [scc_l, scc_l_name, ~, ~] = get_image( success_cue_images, success_cue_names, 'treatL' );
  scc_r = targr;
  scc_r_name = targr_name;
else
  assert( strcmp(correct_direction, 'right') );
  
  [~, ~, scc_r, scc_r_name] = get_image( success_cue_images, success_cue_names, 'treatR' );
  scc_l = targl;
  scc_l_name = targl_name;
end

if ( strcmp(correct_direction, 'left') )  
  [~, ~, err_r, err_r_name] = get_image( err_cue_images, err_cue_names, 'rt_incorrect' );
  
  err_l = targl;
  err_l_name = targl_name;
else
  assert( strcmp(correct_direction, 'right') );
  
  [err_l, err_l_name, ~, ~] = get_image( err_cue_images, err_cue_names, 'rt_incorrect' );
  
  err_r = targr;
  err_r_name = targr_name;
end

img_outs = struct();
img_outs.left_cue_image = cuel;
img_outs.right_cue_image = cuer;
img_outs.left_cue_image_name = cuel_name;
img_outs.right_cue_image_name = cuer_name;

img_outs.left_response_image = targl;
img_outs.right_response_image = targr;
img_outs.left_response_image_name = targl_name;
img_outs.right_response_image_name = targr_name;

img_outs.left_mask_cue_image = mask_cuel;
img_outs.right_mask_cue_image = mask_cuer;
img_outs.left_mask_cue_image_name = mask_cuel_name;
img_outs.right_mask_cue_image_name = mask_cuer_name;

img_outs.left_err_image = err_l;
img_outs.right_err_image = err_r;
img_outs.left_err_image_name = err_l_name;
img_outs.right_err_image_name = err_r_name;

img_outs.left_success_image = scc_l;
img_outs.right_success_image = scc_r;
img_outs.left_success_image_name = scc_l_name;
img_outs.right_success_image_name = scc_r_name;  

end

function img_outs = get_rt_current_images(images, direction, correct_direction)

cues = images.cue;
cue_names = cues{:, end-1};
cue_images = cues{:, end};

cue_name = sprintf( '%s_cue', direction );
[cuel, cuel_name, cuer, cuer_name] = get_image( cue_images, cue_names, cue_name );

targets = images.target;
target_names = targets{:, end-1};
target_images = targets{:, end};

target_name = sprintf( '%s_chest', correct_direction );
[targl, targl_name, targr, targr_name] = get_image( target_images, target_names, target_name );

masks = images.mask;
mask_names = masks{:, end-1};
mask_images = masks{end};

mask_name = 'two_masks';
[mask_cuel, mask_cuel_name, mask_cuer, mask_cuer_name] = get_image( mask_images, mask_names, mask_name );

response_name = sprintf( '%s_mask', correct_direction );
[resp_cuel, resp_cuel_name, resp_cuer, resp_cuer_name] = get_image( mask_images, mask_names, response_name );

dir_specifiers = { 'L', 'R' };

if ( ~strcmp(correct_direction, 'left') )
  assert( strcmp(correct_direction, 'right') );
  dir_specifiers = fliplr( dir_specifiers );
end

success_name = sprintf( 'treat%s', dir_specifiers{1} );
err_name = sprintf( 'wrong%s', dir_specifiers{2} );

success_cues = images.success;
success_cue_names = success_cues{:, end-1};
success_cue_images = success_cues{:, end};

[scc_l, scc_l_name, scc_r, scc_r_name] = get_image( success_cue_images, success_cue_names, success_name );

err_cues = images.error;
err_cue_names = err_cues{:, end-1};
err_cue_images = err_cues{:, end};

[err_l, err_l_name, err_r, err_r_name] = get_image( err_cue_images, err_cue_names, err_name );

img_outs = struct();
img_outs.left_cue_image = cuel;
img_outs.right_cue_image = cuer;
img_outs.left_cue_image_name = cuel_name;
img_outs.right_cue_image_name = cuer_name;

img_outs.left_response_image = resp_cuel;
img_outs.right_response_image = resp_cuer;
img_outs.left_response_image_name = resp_cuel_name;
img_outs.right_response_image_name = resp_cuer_name;

img_outs.left_target_image = targl;
img_outs.right_target_image = targr;
img_outs.left_target_image_name = targl_name;
img_outs.right_target_image_name = targr_name;

img_outs.left_mask_cue_image = mask_cuel;
img_outs.right_mask_cue_image = mask_cuer;
img_outs.left_mask_cue_image_name = mask_cuel_name;
img_outs.right_mask_cue_image_name = mask_cuer_name;

img_outs.left_err_image = err_l;
img_outs.right_err_image = err_r;
img_outs.left_err_image_name = err_l_name;
img_outs.right_err_image_name = err_r_name;

img_outs.left_success_image = scc_l;
img_outs.right_success_image = scc_r;
img_outs.left_success_image_name = scc_l_name;
img_outs.right_success_image_name = scc_r_name;

end

function img_outs = get_side_bias_current_images(images, direction)

targets = images.target;

target_names = targets{:, end-1};
targ_images = targets{end};

targ_name = sprintf( '%s_cue', direction );
[targl, targl_name, targr, targr_name] = get_image( targ_images, target_names, targ_name );

img_outs = struct();
img_outs.left_cue_image = targl;
img_outs.right_cue_image = targr;
img_outs.left_cue_image_name = targl_name;
img_outs.right_cue_image_name = targr_name;

img_outs.left_success_image = targl;
img_outs.right_success_image = targr;
img_outs.left_cue_image_name = targl_name;
img_outs.right_cue_image_name = targr_name;

img_outs.left_err_image = targl;
img_outs.right_err_image = targr;
img_outs.left_err_image_name = targl_name;
img_outs.right_err_image_name = targr_name;


end

function img_outs = get_current_images(images, direction, trial_type, is_masked)

if ( strcmp(trial_type, 'objective') )
  base_images = images.incongruent;
else
  base_images = images.(trial_type);
end

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

if ( strcmp(trial_type, 'congruent') || strcmp(trial_type, 'objective') )
  inds = [1, 2];
else
  assert( strcmp(trial_type, 'incongruent') );
  
  inds = [2, 1];
end

if ( strcmp(current_direction, 'left') )
  ind = inds(1);
else
  assert( strcmp(current_direction, 'right') );
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

function perf = update_performance(perf, was_correct, rt_type, last_rt)

ind = perf.index;
N = perf.end;

if ( ind > N )
  perf.was_correct(1:end-1) = perf.was_correct(2:end);
  perf.was_correct(end) = was_correct;
  ind = N;
else
  perf.was_correct(ind) = was_correct;
end

% update performance once N trials have ellapsed
perf.p_correct = nnz( perf.was_correct ) / ind;

perf.index = ind + 1;
perf.n_correct = perf.n_correct + double( was_correct );
perf.n_incorrect = perf.n_incorrect + double( ~was_correct );

if ( strcmp(rt_type, 'two') )
  fname = 'two_star_rt';
  stpname = 'two_star_rt_stp';
else
  fname = 'one_star_rt';
  stpname = 'one_star_rt_stp';
end

if ( isnan(last_rt) )
  return;
end

if ( isnan(perf.(fname)) )
  perf.(fname) = last_rt;
end

perf.(fname) = (perf.(fname) * perf.(stpname) + last_rt) / (perf.(stpname) + 1);
perf.(stpname) = perf.(stpname) + 1;

end

function mat = get_rt_condition_matrix(n_l, n_r, n_two)

tot = n_l + n_r + n_two;

assert( mod(tot, 2) == 0, 'N conditions must be even.' );
assert( mod(n_two, 2) == 0, 'N two starts must be even.' );

l = repmat( {'left'}, n_l, 1 );
r = repmat( {'right'}, n_r, 1 );
both = repmat( {'two'}, n_two, 1 );

both_left = repmat( {'left'}, n_two/2, 1 );
both_right = repmat( {'right'}, n_two/2, 1 );

both_directions = [ both_left; both_right ];
single_directions = repmat( {''}, n_l + n_r, 1 );

trial_types = [ l; r; both ];
directions = [ single_directions; both_directions ];

mat = [ trial_types, directions ];

end

function inds = get_rt_condition_indices(block_size, random, n_conditions, n_blocks)

import shared_utils.general.get_blocked_condition_indices

if ( ~isempty(random.state) )
  rng( random.state );
end

inds = get_blocked_condition_indices( n_blocks, block_size, n_conditions );

if ( ~isempty(random.state) )
  rng( random.original_state );
end

end

function inds = get_condition_indices(structure, random, n_blocks)

import shared_utils.general.get_blocked_condition_indices

if ( ~isempty(random.state) )
  rng( random.state );
end

block_size = structure.randomization_block_size;
n_conditions = 2;

inds = get_blocked_condition_indices( n_blocks, block_size, n_conditions );

if ( ~isempty(random.state) )
  rng( random.original_state );
end

end

function print_performance(PERFORMANCE, opts)

if ( ~isnan(PERFORMANCE.p_correct) )
  LOG_DEBUG( sprintf('P. CORRECT:   %0.2f', PERFORMANCE.p_correct), 'performance', opts );
else
  LOG_DEBUG( 'P. CORRECT:          nan', 'performance', opts );
end

LOG_DEBUG( sprintf('N CORRECT:     %d', PERFORMANCE.n_correct), 'performance', opts );
LOG_DEBUG( sprintf('N INCORRECT:   %d', PERFORMANCE.n_incorrect), 'performance', opts );
LOG_DEBUG( sprintf('N INITIATED:   %d', PERFORMANCE.n_initiated), 'performance', opts );
LOG_DEBUG( sprintf('N UNINITIATED: %d', PERFORMANCE.n_uninitiated), 'performance', opts );
LOG_DEBUG( sprintf('N SELECTED:    %d', PERFORMANCE.n_selected), 'performance', opts );
LOG_DEBUG( sprintf('N UNSELECTED:  %d', PERFORMANCE.n_unselected), 'performance', opts );
LOG_DEBUG( sprintf('ONE_STAR_RT:   %0.3f', PERFORMANCE.one_star_rt), 'performance', opts );
LOG_DEBUG( sprintf('TWO_STAR_RT:   %0.3f', PERFORMANCE.two_star_rt), 'performance', opts );

end

function response = get_confidence_level_from_key_press_or_null(key_codes, key_code_map)

key_state = ptb.util.are_keys_down( key_codes );

first_down = find( key_state, 1 );

if ( isempty(first_down) )
  response = [];
  return
end

response_key = key_codes(first_down);
response = key_code_map(response_key);

end