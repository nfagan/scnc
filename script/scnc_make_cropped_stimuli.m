function scnc_make_cropped_stimuli()

ext = 'png';
stim_p = fullfile( scnc.util.get_project_folder(), 'stimuli', 'archive', ext );
save_p = fullfile( stim_p, 'cropped' );

imgs = shared_utils.io.find( stim_p, sprintf('.%s', ext) );
fnames = shared_utils.io.filenames( imgs );

for i = 1:numel(imgs)
  [img_mat, color_map] = imread( imgs{i} );
  
  sz = size( img_mat );
  
  min_dim = min( sz );
  
  img_mat_l = img_mat(:, 1:min_dim);
  img_mat_r = img_mat(:, end-min_dim+1:end);
  
  shared_utils.io.require_dir( save_p );
  
  fname_l = sprintf( '%s__left.%s', fnames{i}, ext );
  fname_r = sprintf( '%s__right.%s', fnames{i}, ext );
  
  imwrite( img_mat_l, color_map, fullfile(save_p, fname_l) );
  imwrite( img_mat_r, color_map, fullfile(save_p, fname_r) );
end

end