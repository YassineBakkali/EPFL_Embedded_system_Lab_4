
 % @file    PNG2PPM.m
 % @brief   Converts an image in PNG format to a 32 bit RGB565 format
 % @note    Dimensions : 240W x 320H

 close all; clc;
 
%=========================================================================%
% Module constants.                                                       %
%=========================================================================%

IMG_WIDTH_OUT = 320;
IMG_HEIGHT_OUT = 240;
ASPECT_RATIO_OUT = IMG_WIDTH_OUT/IMG_HEIGHT_OUT;
 
input_file = 'image.png';
output_file = 'image.bin';

%=========================================================================%
% Main script.                                                            %
%=========================================================================%

% We first need to resize the image
img = imread(input_file);
[height, width, ~] = size(img);

aspect_ratio = width/height;

if aspect_ratio > ASPECT_RATIO_OUT
    img = imresize(img, [IMG_HEIGHT_OUT, NaN]);
else
    img = imresize(img, [NaN, IMG_WIDTH_OUT]);
end

[resized_height, resized_width, ~] = size(img);

img = imcrop(img, [(resized_width - IMG_WIDTH_OUT)/2, (resized_height - IMG_HEIGHT_OUT)/2,...
                   IMG_WIDTH_OUT, IMG_HEIGHT_OUT]);
               
img = imresize(img, [IMG_HEIGHT_OUT, IMG_WIDTH_OUT]);

imshow(img);

% Then, we convert it to RGB565 format
img = permute(img, [3 2 1]);
img = img(:);

rgb_image = zeros(IMG_HEIGHT_OUT*IMG_WIDTH_OUT,1);
pRed = (img(1:3:end));
pGreen = (img(2:3:end)); 
pBlue = (img(3:3:end)); 

for i = 1:1:IMG_HEIGHT_OUT*IMG_WIDTH_OUT
    pRed(i) = bitshift(pRed(i), -3);
    pGreen(i) = bitshift(pGreen(i), -2);
    pBlue(i) = bitshift(pBlue(i), -3);
    rgb_image(i) = bitor(bitor((bitshift(uint16(bitand(pRed(i), 0x1f)),11)),...
        (bitshift(uint16(bitand(pGreen(i), 0x3f)),5))),(uint16(bitand(pBlue(i),0x1f))));
end

bin_image = fopen(output_file, 'w');
fwrite(bin_image, rgb_image, 'uint32');
fclose(bin_image);