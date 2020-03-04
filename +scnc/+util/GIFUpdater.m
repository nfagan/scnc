classdef GIFUpdater < handle
  properties
    TargetFlipInterval = 1/60;
  end
  
  properties (Access = private)
    timer;
    last_frame;
  end
  
  methods
    function obj = GIFUpdater(interval)
      if ( nargin > 0 )
        obj.TargetFlipInterval = interval;        
      end
      
      obj.timer = tic;
      obj.last_frame = toc( obj.timer );
    end
    
    function set.TargetFlipInterval(obj, to)
      validateattributes( to, {'double'}, {'scalar', 'positive', 'finite'} ...
        , mfilename, 'TargetFlipInterval' );
      obj.TargetFlipInterval = to;
    end
    
    function reset(obj)
      obj.last_frame = toc( obj.timer );
    end
    
    function tf = update(obj)
      ct = toc( obj.timer );
      tf = ct - obj.last_frame >= obj.TargetFlipInterval;
      
      if ( tf )
        obj.last_frame = ct;
      end
    end
  end
end