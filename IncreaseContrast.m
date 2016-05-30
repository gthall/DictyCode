function [Image1] = IncreaseContrast(Image1)
    Image1 = Image1-min(min(Image1)); Image1 = Image1./max(max(Image1));
end 