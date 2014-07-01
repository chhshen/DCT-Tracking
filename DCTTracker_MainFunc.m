%
% Matlab code for the paper
% ``Incremental learning of 3D-DCT compact representations for robust visual tracking.''
% by X. Li, A. Dick, C. Shen, A. van den Hengel, H. Wang. TPAMI 2013.
%
% Copyright by the authors 2013.
%




clc; clear all;  close all;
addpath('./utility');


%
% run a demo on the `animal' video sequence
%
title = 'animal';



switch (title)
    case 'animal';
        %
        % Tracker bounding box initialization
        %
        p = [309 1 130 75 0]; % [top-left-x top-right-y width height]
    otherwise;  error(['unknown title ' title]);
end
p(1)=p(1)+0.5*p(3); p(2)=p(2)+0.5*p(4);


%% Tracker parameter initialization
opt = []; param = []; pts = [];
randn('state',0);
DatasetImagePath = './Datasets/';

switch (title)
    case 'animal';
        opt.tmplsize = [20 20];  % opt.tmplsize = [16 16]; opt.tmplsize = [32 32]; ... Use different configuations for different videos
        IsNorm = 0; % image intensity normalization indicator
        frame = imread(sprintf('%s%s%s%04d.jpg', DatasetImagePath, title, '/imgs/frame_', 1));
        KNN = 7;
        alpha = 0.1;
        opt.affsig = [30, 30, .03,.002,.02,.001]; % opt.affsig = [10,10,.03,.002,.02,.001]; opt.affsig = [20,20,.03,.002,.02,.001]; ... Use different configurations for different videos.
        opt.numsample = 100; %opt.numsample = 200;  opt.numsample = 300; ...
        FrameRange = 1:1:71;
        color_option = [1 0 0];
    otherwise;  error(['unknown title ' title]);
end
param0 = [p(1), p(2), p(3)/opt.tmplsize(1), p(5), p(4)/p(3), 0];
param0 = affparam2mat(param0);
param.est = param0;


if ndims(frame)==3
    frame = double(rgb2gray(frame))/256;
else
    frame = double(frame)/256;
end
tmpl.refimg = warpimg(frame, param0, opt.tmplsize);
sz = size(tmpl.refimg);  N = sz(1)*sz(2);
param.wimg = tmpl.refimg;


%% Tracking buffer
TrackParam = {};
BufPool = [];
TemplateImgs = [];
GlobalTemplateImgs = [];
SignMatrix = [1 -1 1 -1 0 0 1 -1;
              1 -1 0 0 1 -1 -1 1];
MaxBufSize = 500;

%% Draw initial tracking window
plotlinewidth_option = 1.5;
drawopt = drawtrackresult_xi([], 0, frame, tmpl, param, pts, color_option, plotlinewidth_option);


%% create tracking folder
if ~isdir(['results/' title])
    mkdir('results/', title);
end

for f = FrameRange
    switch (title)
        case 'animal';
            frame = imread(sprintf('%s%s%s%04d.jpg', DatasetImagePath, title, '/imgs/frame_', f));
        otherwise;  error(['unknown FrameRange ' title]);
    end

    if ndims(frame)==3
        frame = double(rgb2gray(frame))/256;
    else
        frame = double(frame)/256;
    end

    %% particle searching
    param.param = repmat(affparam2geom(param.est(:)), [1,opt.numsample]);
    RndGen = randn(6,opt.numsample);
    param.param = param.param + RndGen.*repmat(opt.affsig(:),[1,opt.numsample]);
    param.param(4,:) = 0;


    ParticleShape = [param.param(3,:).*sz(2); param.param(5,:).*param.param(3,:).*sz(2)];
    ParticleCriteriaPlus = param.param(1:2,:) + 0.5*ParticleShape;
    ParticleCriteriaMinus = param.param(1:2,:) - 0.5*ParticleShape;

    BufParam = param.param;
    Pidx1 = find(ParticleCriteriaPlus(1,:)>size(frame,2));
    if ~isempty(Pidx1)
        BufParam(1,Pidx1) = (size(frame,2) - 0.5*ParticleShape(1,Pidx1)); %
    end

    Pidx2 = find(ParticleCriteriaPlus(2,:)>size(frame,1));
    if ~isempty(Pidx2)
        BufParam(2,Pidx2) = (size(frame,1) - 0.5*ParticleShape(2,Pidx2));%
    end

    Midx1 = find(ParticleCriteriaMinus(1,:)<0);
    if ~isempty(Midx1)
        BufParam(1,Midx1) = 0.5*ParticleShape(1,Midx1); %
    end

    Midx2 = find(ParticleCriteriaMinus(2,:)<0);
    if ~isempty(Midx2)
        BufParam(2,Midx2) = 0.5*ParticleShape(2,Midx2); %
    end
    param.param = BufParam;
    wimgs = warpimg(frame, affparam2mat(param.param), sz);


    %% DCT learning
    BufPool = [BufPool f]; %buffer frames index array
    TmplNum = length(BufPool);
    if f==FrameRange(1)
        %Positive sample selection
        tmp = param.wimg;
        if IsNorm==1
            tmp = normalize8(tmp,0);
        end
        TemplateImgs = log(tmp + 1); %logarithm mapping

        %Negative sample selection
        CState = affparam2geom(param.est(:));
        CPShape = [CState(3).*sz(2); CState(5).*CState(3).*sz(2)];
        NegParam = repmat(CState, [1,8]);
        NegSig = [0.5*CPShape(1),0.5*CPShape(2),.0,.0,.0,.0]';
        NegParam(1:2,:) = NegParam(1:2, :) + repmat(NegSig(1:2,:), [1 8]).*SignMatrix;
        GlobalTemplateImgs = warpimg(frame, affparam2mat(NegParam), sz);

        for i=1:size(GlobalTemplateImgs, 3)
            if IsNorm==1
                GlobalTemplateImgs(:,:,i) = normalize8(GlobalTemplateImgs(:,:,i), 0);
            end
            GlobalTemplateImgs(:,:,i) = log(GlobalTemplateImgs(:,:,i) + 1);
        end

    else
        TmplNum = size(TemplateImgs, 3);
        NegTmplNum = size(GlobalTemplateImgs, 3);
        LikiScoreBuf = [];

        for i=1:opt.numsample
            SubImg = wimgs(:,:,i);
            if IsNorm==1
                SubImg = normalize8(SubImg,0);
            end
            SubImg = log(SubImg + 1);

           %% Positive
            if TmplNum>=10 %Maintain the minimum positive buffer size to be 10
                Dist = sum(sum((repmat(SubImg, [1 1 TmplNum]) - TemplateImgs).^2, 1), 2);
                [sortval,sortidx] = sort(Dist,'ascend');
                Buf = cat(3, TemplateImgs(:,:,sortidx(1:KNN)), SubImg); % KNN search
            else
                Buf = cat(3, TemplateImgs, SubImg);
            end

            LDim = 10; % dct coefficient dimension
            Jpos = mirt_dctn(Buf);
            Jpos(:,LDim:end) = 0;
            Kpos = mirt_idctn(Jpos);

            error_diff = abs((Kpos(:,:,end) - Buf(:,:,end)));
            error_diff = error_diff(:);

            Idx = find(error_diff>0.1);
            error_diff(Idx) = 0.1;
            score = exp(-mean(error_diff.^2));


           %% Negative
            NegDist = sum(sum((repmat(SubImg, [1 1 NegTmplNum]) - GlobalTemplateImgs).^2, 1), 2);
            NegDist = NegDist(:);
            [sortval,sortidx] = sort(NegDist,'ascend');
            NegBuf = cat(3, GlobalTemplateImgs(:,:,sortidx(1:8)), SubImg);

            Jneg = mirt_dctn(NegBuf);
            Jneg(:, LDim:end) = 0;
            Kneg = mirt_idctn(Jneg);

            error_diff = (Kneg(:,:,end) - NegBuf(:,:,end)).^2;
            [err_val,err_idx] = sort(error_diff(:),'ascend');
            negscore = exp(-mean(err_val(err_idx(1:floor(0.8*length(err_val)))))); % robust reconstruction likelihood

            LikiScoreBuf = [LikiScoreBuf score - alpha*negscore];
        end
        %Map estimation
        [prob,idx] = sort(LikiScoreBuf,'descend');
        param.est = affparam2mat(param.param(:,idx(1)));


        %Positive sample selection
        SubImg = wimgs(:,:,idx(1));
        if IsNorm==1
            SubImg = normalize8(SubImg);
        end
        SubImg = log(SubImg + 1);
        TemplateImgs = cat(3, TemplateImgs, SubImg);


        %Negative sample selection
        CState = affparam2geom(param.est(:));
        CPShape = [CState(3).*sz(2); CState(5).*CState(3).*sz(2)];
        NegParam = repmat(CState, [1,8]);
        NegSig = [0.3*CPShape(1),0.3*CPShape(2),.0,.0,.0,.0]'; %Negative offset variance from the tracker location
        NegParam(1:2,:) = NegParam(1:2, :) + repmat(NegSig(1:2,:), [1 8]).*SignMatrix;
        NegImgs = warpimg(frame, affparam2mat(NegParam), sz);

        for i=1:size(NegImgs, 3)
            if IsNorm==1
                NegImgs(:,:,i) = normalize8(NegImgs(:,:,i));
            end
            NegImgs(:,:,i) = log(NegImgs(:,:,i) + 1);
        end
        GlobalTemplateImgs = NegImgs;
    end

    %% save results
    param_frm.est = param.est;
    TrackParam = [TrackParam; param_frm];
    drawopt = drawtrackresult_xi(drawopt, f, frame, tmpl, param_frm, pts, color_option, plotlinewidth_option);
    %
    %% Uncomment this to save the tracking results of each frame
    %
    % imwrite(frame2im(getframe(gca)),sprintf('results/%s/%s.%04d.png',title, title,f));
    %
    %
    f
end


%
%% store results
%  the tracked bounding box is stored in the `results/results*.mat' file.
%
strFileName = sprintf('results/result_%s.mat', title);
save(strFileName, 'TrackParam');



