function drawopt = drawtrackresult_xi(drawopt, fno, frame, tmpl, param, pts, color_option, plotlinewidth_option)

if (isempty(drawopt))
  figure('position',[950 550 size(frame,2) size(frame,1)]); clf;         
  set(gcf,'DoubleBuffer','on','MenuBar','none');
  colormap('gray');
  drawopt.curaxis = [];
  drawopt.curaxis.frm  = axes('position', [0.00 0 1.00 1.0]);
end

sz = size(tmpl.refimg);  
curaxis = drawopt.curaxis;
axes(curaxis.frm);
imagesc(frame, [0,1]); hold on;

if (exist('pts'))
  if (size(pts,3) > 1)  plot(pts(1,:,2),pts(2,:,2),'yx','MarkerSize',10);  end;
  if (size(pts,3) > 2)  plot(pts(1,:,3),pts(2,:,3),'rx','MarkerSize',10);  end;
end
text(5, 18, num2str(fno), 'Color','y', 'FontWeight','bold', 'FontSize',18);
drawbox(sz, param.est, 'Color',color_option, 'LineWidth',plotlinewidth_option);
axis equal tight off; hold off;

drawnow;
