%% GEV Fit for Block Maxima
%% Load in data
clearvars
stn_nm = 'seattle/';

dir_nm = '../COOPS_tides/';

fol_loc = strcat(dir_nm, stn_nm);
% Load predictions
pre = load(strcat(fol_loc,'seattle_tide_predictions'));

%Load verified tides
ver_t = load(strcat(fol_loc,'seattle_6minV'));

ver.time = ver_t.tide.time;
ver.wl = ver_t.tide.WL_VALUE;
ver.stn_id = ver_t.tide.STATION_ID;
ver.lat = ver_t.tide.latitude;
ver.lon = ver_t.tide.longitude;

clear ver_t


tides = struct();

tides.lat = ver.lat;
tides.lon = ver.lon;
tides.datum = 'NAVD88';
tides.stn_id = ver.stn_id;

tides.ver_time = ver.time;
%tides.raw_time = raw.time;
tides.pre_time = pre.time;

tides.ver_wl = ver.wl;
%tides.raw_wl = raw.WL_VALUE;
tides.pre_wl = pre.wl;

                        

%% Find yearly max
yr_vec = year(tides.ver_time(1)):year(tides.ver_time(end)); %make a year vec, -10 because of NaNs
maxima = NaN(length(yr_vec),1); %create vector to house all of the block maxima
for i = 1:length(yr_vec)
    yr_ind = find(year(tides.ver_time) == yr_vec(i));
    % If there is more than 50% of the hours missing for that year, I will
    % skip it
    if length(yr_ind) < 8760 * .5
        maxima(i) = NaN;
    else
    %max_val = max(wndspd(yr_ind));a
        maxima(i) = max(tides.ver_wl(yr_ind));
    end
end

nan_ind = isnan(maxima); % Find any nans and get rid of them
maxima(nan_ind) = [];


%nan_ind = find(maxima > 40);
%maxima(nan_ind) = [];


clear j yr_ind

% Get GEV statistics about the data
[paramEsts, paramCIs] = gevfit(maxima);
%----------------Results from GEV-------------------------------
% % % kMLE = paramEsts(1);        % Shape parameter
% % % sigmaMLE = paramEsts(2);    % Scale parameter
% % % muMLE = paramEsts(3);       % Location parameter
%% Plot the GEV
% I tinkered with GEV_Test and found a plot that I like better than current
% version below
% Modified from example from link below
%https://www.mathworks.com/help/stats/examples/modelling-data-with-the-generalized-extreme-value-distribution.html
clf
%lowerBnd = paramEsts(3)-paramEsts(2)./paramEsts(1);
lowerBnd = 0;
x = maxima;  
xmax = 1.1*max(x);
bins = floor(lowerBnd):ceil(xmax);

% plot the hist with GEV line
subplot(2,2,[1 3])
h = bar(bins,histc(x,bins)/length(x),'histc');
h.FaceColor = [.8 .8 .8];
xgrid = linspace(lowerBnd,xmax,100);
line(xgrid,gevpdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)));
xlim([lowerBnd xmax]);
plot_tit = sprintf('GEV - PDF - %s', station_name);
title(plot_tit)

ax = gca;  % Play with the Axes 
ax.XLim = [8 xmax*1.1];

% Add GEV parameters to the plot
tbox = sprintf('mu = %4.2f \nsigma = %4.2f \nk = %4.2f \nn: %d',...
    paramEsts(1),paramEsts(2),paramEsts(3), length(maxima));
%text(10,0.25, tbox)

% Add box around the text
dim = [.3 .35 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');



xlabel('Max Hourly Wind Speed Obs [m/s]')
ylabel('Probability Density')
%legend('Hourly','Six-Hr Avg.','Location','NorthEast')
box on

% Calculate the CDF - CDF will give me the probability of values 
cdf = 1 - gevcdf(xgrid,paramEsts(1),paramEsts(2),paramEsts(3)); % create CDF from GEV PDF


% ----------Notes-----------
% - PDF sums to 1, represents probability density
% - CDF is the cumulative PDF, represents probability
% - CDF is the probability of the random variable being less than X

%% Calculate Recurrence Interval

%-------Note-----------%
%RI = 1/Probability
%Knowing CDF and thus the probability, I can calculate the Recurrence

RI = 1./cdf;
subplot(2,2,[2 4])
plot(xgrid, RI)
ylim([0 100])
plot_tit = sprintf('Recurrence Interval - %s', station_name);
title(plot_tit)
xlabel('Wind Speed [m/s]')
ylabel('Time [years]')


ax = gca;
set(gca,'XMinorTick','on')  %add minor tick marks on x-axis

box on 
grid on


% Generate specific values for recurrence levels

R100MLE = gevinv(1-1./100,paramEsts(1),paramEsts(2),paramEsts(3));
R50MLE = gevinv(1-1./50,paramEsts(1),paramEsts(2),paramEsts(3));
R25MLE = gevinv(1-1./25,paramEsts(1),paramEsts(2),paramEsts(3));
R10MLE = gevinv(1-1./10,paramEsts(1),paramEsts(2),paramEsts(3));
R5MLE = gevinv(1-1./5,paramEsts(1),paramEsts(2),paramEsts(3));
R2MLE = gevinv(1-1./2,paramEsts(1),paramEsts(2),paramEsts(3));

% Add GEV parameters to the plot
tbox = sprintf('100 yr: %4.2f m/s\n50 yr: %4.2f m/s\n25 yr: %4.2f m/s\n10 yr: %4.2f m/s\n5 yr: %4.2f m/s\n2 yr: %4.2f m/s'...
    ,R100MLE, R50MLE, R25MLE, R10MLE, R5MLE, R2MLE);
%text(6,60, tbox)

dim = [.62 .3 .3 .3];
annotation('textbox',dim,'String',tbox,'FitBoxToText','on');

%%
% Save the Plot
cd('../../Matlab_Figures/GEV/Updated')

outname = sprintf('GEV_%s',station_nm);
hFig = gcf;
hFig.PaperUnits = 'inches';
hFig.PaperSize = [8.5 11];
hFig.PaperPosition = [0 0 7 7];
print(hFig,'-dpng','-r350',outname) %saves the figure, (figure, filetype, resolution, file name)
close(hFig)

cd('../../../matlab/Climatology')
