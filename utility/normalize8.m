% The function adjusts the dynamic range of the grey scale image to the interval [0,255] or [0,1]
% 
% PROTOTYPE
%       Y=normalize8(X,mode);
% 
% USAGE EXAMPLE(S)
% 
%     Example 1:
%       X=imread('sample_image.bmp');
%       Y=normalize8(X);
%       figure,imshow(X);
%       figure,imshow(uint8(Y));
% 
%     Example 2:
%       X=imread('sample_image.bmp');
%       Y=normalize8(X,1);
%       figure,imshow(X);
%       figure,imshow(uint8(Y));
% 
%     Example 3:
%       X=imread('sample_image.bmp');
%       Y=normalize8(X,0);
%       figure,imshow(X);
%       figure,imshow((Y),[]);
%
%
% INPUTS:
% X                     - a grey-scale image of arbitrary size
% mode                  - the parameter indicates the ernage of the target
%                         interval, if "mode=1", the output is mapped to [0,
%                         255], if "mode=0" the output is mapped to [0,1]
%
% OUTPUTS:
% Y                     - a grey-scale image with its dynamic range
%                         adjusted to span the entire 8-bit interval, i.e.,
%                         the intensity values lie in the range [0 255] or
%                         the interval [0,1]
%
% NOTES / COMMENTS
% This function is needed by a few other function actually performing
% photometric normalization. It remapps the intensity values of the images
% from its original span to the interval [0, 255] or [0,1] depending on the 
% value of the input parameter "mode". If the parameter mode is not
% provided it is assumed that the target interval equals [0,255].
%
% The function was tested with Matlab ver. 7.5.0.342 (R2007b).
% 
% 
% ABOUT
% Created:        19.8.2009
% Last Update:    19.8.2009
% Revision:       1.0
% 
%
% WHEN PUBLISHING A PAPER AS A RESULT OF RESEARCH CONDUCTED BY USING THIS CODE
% OR ANY PART OF IT, MAKE A REFERENCE TO THE FOLLOWING PUBLICATIONS:
%
% 1. Štruc V., Pavešiæ, N.:Performance Evaluation of Photometric Normalization 
% Techniques for Illumination Invariant Face Recognition, in: Y.J. Zhang (Ed), 
% Advances in Face Image Analysis: Techniques and Technologies, IGI Global, 
% 2010.      
% 
% 2. Štruc, V., Žibert, J. in Pavešiæ, N.: Histogram remapping as a
% preprocessing step for robust face recognition, WSEAS transactions on 
% information science and applications, vol. 6, no. 3, pp. 520-529, 2009.
% (BibTex available from: http://luks.fe.uni-lj.si/sl/osebje/vitomir/pub/WSEAS.bib)
% 
%
% Copyright (c) 2009 Vitomir Štruc
% Faculty of Electrical Engineering,
% University of Ljubljana, Slovenia
% http://luks.fe.uni-lj.si/en/staff/vitomir/index.html
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files, to deal
% in the Software without restriction, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in 
% all copies or substantial portions of the Software.
%
% The Software is provided "as is", without warranty of any kind.
% 
% August 2009

function Y=normalize8(X,mode);

%% Parameter check
if nargin==1
    mode = 1;
end

%% Init. operations
X=double(X);
[a,b]=size(X);

%% Adjust the dynamic range to the 8-bit interval
max_v_x = max(max(X));
min_v_x = min(min(X));

if mode == 1
    Y=ceil(((X - min_v_x*ones(a,b))./(max_v_x*(ones(a,b))-min_v_x*(ones(a,b))))*255);
elseif mode == 0
    Y=(((X - min_v_x*ones(a,b))./(max_v_x*(ones(a,b))-min_v_x*(ones(a,b)))));
else
    disp('Wrong value of parameter "mode". Please provide either 0 or 1.')
end
    



