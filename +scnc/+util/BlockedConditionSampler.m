classdef BlockedConditionSampler < handle
  
  properties (GetAccess = public, SetAccess = private)
    BlockSize;
    NConditions;
    NBlocks;
  end
  
  properties (Access = private)
    condition_indices;
    condition_index;
  end
  
  methods
    function obj = BlockedConditionSampler(n_blocks, block_size, n_conditions)
      import shared_utils.general.get_blocked_condition_indices;
      
      obj.condition_indices = get_blocked_condition_indices( n_blocks, block_size, n_conditions );
      obj.condition_index = 1;
      
      obj.BlockSize = block_size;
      obj.NBlocks = n_blocks;
      obj.NConditions = n_conditions;
    end
  end
  
  methods (Access = public)
    function condition = current_condition(obj)
      
      condition = obj.condition_indices(obj.condition_index);
    end
    
    function increment_condition_index(obj)
      
      next_condition_index = obj.condition_index + 1;
      
      if ( next_condition_index > numel(obj.condition_indices) )
        next_condition_index = 1;
      end
      
      obj.condition_index = next_condition_index;
    end
  end
end