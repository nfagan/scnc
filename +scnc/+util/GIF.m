classdef GIF < handle
  properties
    Frames;
  end
  
  properties (Access = private)
    current_frame_index = 1;
  end
  
  methods
    function obj = GIF(frames)
      obj.Frames = frames;
    end
    
    function set.Frames(obj, to)
      validateattributes( to, {'cell'}, {}, mfilename, 'Frames' );
      
      for i = 1:numel(to)
        validateattributes( to{i}, {'numeric'}, {}, mfilename, 'Frames' );
      end
      
      obj.Frames = to;
    end
    
    function mat = next_frame(obj)
      if ( isempty(obj.Frames) )
        mat = [];
      else
        mat = obj.Frames{obj.current_frame_index};
        
        obj.current_frame_index = obj.current_frame_index + 1;
        if ( obj.current_frame_index > numel(obj.Frames) )
          obj.current_frame_index = 1;
        end
      end
    end
  end
end