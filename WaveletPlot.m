%function takes in wavelet data and makes a pretty looking plot of
%the original signal, the power spectra with significance contours and cone
%of influence, as well as the global wavelet spectrum
function[] =  WaveletPlot(wellData, i)
    
        tempSignal = wellData.waveData(i).normalizedSignal;
        signalLength = length(tempSignal);
        power = wellData.waveData(i).power;
        period = wellData.period;
        coi = wellData.coi;
        scales = wellData.scales
        global_ws = wellData.waveData(i).globalWS;
        global_signif = wellData.waveData(i).globalSig;
        scale_avg = wellData.waveData(i).scaleAvg;
        scaleavg_signif = wellData.waveData(i).scaleAvgSig;
        time  = wellData.times;
        time = time(1:length(tempSignal));
        xlim(1) = time(200);xlim(2) = time(850);
        peaks1 = wellData.waveData(i).powerPeaks;
        peaks1 = cat (1, peaks1.Centroid);
        
        
        
        period = period (1:450);power = power (1:450, :);
        
        
        %get significance criteria
        [tempSignif, ~] = wave_signif (1.0, time(2)-time(1), ...
            scales(1:450), 0, .72 ,...
            .97, -1, 'Morlet');
        
        % expand tempSignif --> (J+1)x(N) array
        sigArray = (tempSignif')*(ones(1,length(time)));
        significance = power./sigArray;
        
        %--- Plot time series of signal for comparison
        %subplot('position',[0.1 0.75 0.65 0.2])
        subplot (2,1,1)
        plot(time, tempSignal)
        set(gca,'XLim',xlim(:), 'FontSize', 16);
        set (gca, 'YLim', [-1.5, 1.5]);
        xlabel('Time From Starvation (minutes)')
        ylabel('Intensity (AU)')
        title('a) Signal from Video')
        hold off
        
        %subplot('position',[0.1 0.37 0.65 0.28])
        subplot (2,1,2)
        %define levels of countour based on parameters of power
        levels = linspace(min(min(log2(power)))...
            ,max(max(log2(power))), 10);
        %define y tick marks
        Yticks = 2.^(fix(log2(min(period))):fix(log2(max(period))));
        %plot powerspectrum as a contour plot
        imagesc(time, log2(period), power)%,levels);

        colormap jet;h = colorbar;
        ylabel (h, 'Power (AU)')
        xlabel('Time (minutes)')
        ylabel('Period (minutes)')
        title('b) Wavelet Power Spectrum')
        set(gca,'XLim',xlim(:), 'FontSize', 16)
        set(gca,'YLim',log2([min(period),max(period)]),'YDir','reverse', ...
            'YTick',log2(Yticks(:)), 'YTickLabel',Yticks)
        
        hold on;
        plot (peaks1(:,1), log2(peaks1(:,2)), 'k+', 'LineWidth', 7);
%         
%    % 95% significance contour, levels at -99 (fake) and 1 (95% signif
%         hold on
%         contour(time,log2(period)...
%             ,significance, [-99 1] ,'c', 'LineWidth', 3);
%         hold on
%         %plot cone of influence
%         plot (time, log2(coi),'k', 'LineWidth', 3);
%         hold off
%                 %plot peaks
%         hold on;
%         if~isempty (peaks1)
%         plot (peaks1(:,1), log2(peaks1(:,2)), 'k+', 'LineWidth', 7)
%         end
%         hold off;
%  
% 
%         %--- Plot global wavelet spectrum
%         subplot('position',[0.77 0.37 0.2 0.28])
%         plot(global_ws,log2(period))
%         hold on
%         plot(global_signif,log2(period),'--')
%         hold off
%         xlabel('Power (AU)')
%         title('c) Global Wavelet Spectrum')
%         set(gca,'YLim',log2([min(period),max(period)]), ...
%             'YDir','reverse', ...
%             'YTick',log2(Yticks(:)), ...
%             'YTickLabel','')
%         set(gca,'XLim',[0,1.25*max(global_ws)])
%         
%         %--- Plot scale-average time series
%         subplot('position',[0.1 0.07 0.65 0.2])
%         plot(1:signalLength,scale_avg)
%         set(gca,'XLim',xlim(:))
%         xlabel('Time (frames)')
%         ylabel('Avg variance (gray scale au^2)')
%         title('d) Scale Avg Time Scale ')
%         hold on
%         plot(xlim,scaleavg_signif+[0,0],'--')
%         hold off
%         
%         
% end