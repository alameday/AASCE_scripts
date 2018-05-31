%-----------------------------------------------------
%RMS 2018
%Script to read deep water OBS ranging locations from excel spreadsheet,
%and estimate location of OBS on the sea floor.
%-----------------------------------------------------

%-----------------------------------------------------
%This version uses MATLAB's fminsearch function to find the optimal location
%for a grid search over seafloor depth. It obtains the same results as the
%grid search version but is much faster. Note that the fminunc function
%could also be used and it might be worth investigating the 
%-----------------------------------------------------

format long
clear all
close all

%-----------------------------------------------------
%NOTE: Longitude column in speadsheet must be negative
%The function vdist.m should be in the current directory

% To find optimum depth
% - set remove_circles=Y
% - set intervals
% - run program
% - save the circles figure 
% - report optimum depth 

%-----------------------------------------------------
%Edit these lines
instrument='LD38'; %instrument ID number
sheet_number=21 %sheet number in OBS ranging locations.xls
sheet='OBS Ranging Location_rms2.xlsx'; %should be in this directory
depth=4053; %instrument depth in meters
remove_circles='Y' %do we want try to remove bad ranging points to improve the accuracy of the 
%final location? This doesn't change the location much but reduces the uncertainty
depthvary=50; %range of depth variation 
depthvaryinterval=1; %interval of depth variation

%options for optimization
options = optimset('TolX',1e-4,'TolFun',1e-4,'Display','final');
%-----------------------------------------------------

%location of transducer relative to the GPS reference point
x0 = 23.146; 
y0 = 3.903;

%lon, lat and range vectors
insheet = xlsread(sheet,sheet_number);
lats=insheet(2:end,5);
lons=insheet(2:end,6);
range=insheet(2:end,7);

%drop location and heading information if available.
%ensure that the heading column is filled in correctly! 
if sheet_number > 3
    heading=insheet(2:end,8).*(pi/180);
    droplat=insheet(1,11);
    droplon=insheet(1,12);
else
    droplat=insheet(1,10);
    droplon=insheet(1,11);
    heading=nan(length(lats),1);
end

heading=nan(length(lats),1);

R2dist=111319.9; %conversion from 1 degree of latitude to distance
%at roughly the latitude of SE Alaska

%Find distance to site from each of the ship points, using vdost function
%-----------------------------------------------------
for i = 1:length(lats)
     lat = lats(i);
     lon = lons(i);
     if lat ~= 0
         
         ranging_lats(i) = lat;
         ranging_lons(i) = lon;
         
         if isnan(heading(i))
             
             dy = vdist(droplat,droplon,lat,droplon);
             if lat < droplat
                 dy = -dy;
             end
             yy(i) = dy;
             
             dx = vdist(droplat,droplon,droplat,lon);
             if lon < droplon
                 dx = -dx;
             end
             xx(i) = dx;
             
         else
             dy = vdist(droplat,droplon,lat,droplon) + x0*cos(heading(i)) + y0*sin(heading(i));
             if lat < droplat
                 dy = -dy;
             end
             yy(i) = dy;
             
             dx = vdist(droplat,droplon,droplat,lon) - y0*cos(heading(i)) + x0*sin(heading(i));
             if lon < droplon
                 dx = -dx;
             end
             xx(i) = dx;
             
             %yy(i) = (lat-droplat)*R2dist + x0*cos(heading(i)) + y0*sin(heading(i));
             %xx(i) = (lon-droplon)*R2dist*cos(droplat*pi/180) - y0*cos(heading(i)) + x0*sin(heading(i));           
         end
         IR(i) = range(i);
     end
end
%-----------------------------------------------------

%Generate figure
f = figure(1);
p1 = plot(xx,yy,'o');
hold on
axis('square')

%Generate matrices of all points on circles
kk=1:360;
kk=kk*pi/180;
circlesx = zeros(length(kk),length(xx));
circlesy = zeros(length(kk),length(xx));

%-----------------------------------------------------

%%% Minimize an objective function to see if we get a similar set of
%%% results

%%% Function to minimize
f = @(pos,circlesx,circlesy)sum(min(((circlesx-pos(1)).^2 + (circlesy-pos(2)).^2).^(1/2)));
% Starting location for optimization 
pos0 = [0,0];

%vector of depths to test
dp = [depth-depthvary:depthvaryinterval:depth+depthvary];
fvals = zeros([1,length(dp)]);
posopts = zeros([length(dp),2]);

%-----------------------------------------------------

for i = 1:length(dp)

    depth = dp(i);
    rr=sqrt(IR.^2-depth^2);

    for j=1:length(xx)
        circlesx(:,j) = xx(j)+cos(kk)*rr(j);
        circlesy(:,j) = yy(j)+sin(kk)*rr(j);
    end

    fun = @(pos)f(pos,circlesx,circlesy);

    %Do optimization for the set of loci we just generated
    [posopt,fval] = fminsearch(fun,pos0);
    posopts(i,:) = posopt;
    fvals(i) = fval;

end

[M,I] = min(fvals(:));
optpoint = posopts(I,:);
xp = optpoint(1);
yp = optpoint(2);
depth = dp(I);
sprintf('Optimum depth found: %f',depth)

%-----------------------------------------------------

if remove_circles == 'Y'
    
   rr=sqrt(IR.^2-depth^2);
   
   for j=1:length(xx)
    circlesx(:,j) = xx(j)+cos(kk)*rr(j);
    circlesy(:,j) = yy(j)+sin(kk)*rr(j);
   end

  %Determine how close each circle comes to the point
  circle_closest_points = zeros([1,length(xx)]);

  for i = 1:length(circle_closest_points)
    circle_closest_points(i) = min(((circlesx(:,i)-xp).^2 + (circlesy(:,i)-yp).^2).^(1/2));
  end

  mean_distance = mean(circle_closest_points);
  crit_dist = mean_distance;

  %find indices of the circles to remove and remake the vectors needed
  %for the grid search
  j=1;
  k=1;
  for i = 1:length(circle_closest_points)
      if (circle_closest_points(i) > crit_dist)
         circles_to_remove(j) = i;
         j = j + 1;
      else
        IR_2(k) = IR(i);
        xx_2(k) = xx(i);
        yy_2(k) = yy(i);
        k = k + 1;
      end
  end

  %plot the circles to remove in a distinct way. It should be obvious
  %that these are bad ranging points

  for j=1:length(circles_to_remove)
    index = circles_to_remove(j);
    plot(circlesx(:,index),circlesy(:,index),'k--');
  end
  
  IR = IR_2;
  xx = xx_2;
  yy = yy_2;
  
end

%%% -------------------------------------------------------
%%% Final optimization stage - we've varied the depth and removed bad
%%% points, now run the optimization again and plot the final figure
%%% -------------------------------------------------------

rr=sqrt(IR.^2-depth^2);

for j=1:length(xx)
    circlesx(:,j) = xx(j)+cos(kk)*rr(j);
    circlesy(:,j) = yy(j)+sin(kk)*rr(j);
    plot(circlesx(:,j),circlesy(:,j),'g');
end

fun = @(pos)f(pos,circlesx,circlesy);

[posopt,fval] = fminsearch(fun,pos0,options);

%This is a measure of error - its the sum of the minimum distances to the
%loci at the optimum point, divided by the number of circles
mean_dist = fval/length(xx);

%Determine offset in meters
x_offset = posopt(1);
y_offset = posopt(2);

%Determine lat and lon of settle location
settle_lat = y_offset/R2dist + droplat;
settle_lon = x_offset/(R2dist*cos(droplat*pi/180)) + droplon;

sprintf('Calculated offset is %.4f m (X) ,%.4f m (Y) from drop location',x_offset,y_offset)
sprintf('Calculated settle location: %03f/%03f',settle_lon,settle_lat)
         
%plot measure of uncertainty as a circle
p2 = plot(xp+cos(kk)*mean_dist,yp+sin(kk)*mean_dist,'k-');
text(500,500,sprintf("Error radius: %.1f m",mean_dist))

%Plot the optimal point
p3 = plot(x_offset,y_offset,'ro');
xlabel("W-E distance relative to drop location (m)");
ylabel("S-N distance relative to drop location (m)");
legend([p1,p2,p3],'Ranging location','Uncertainty','OBS location')
title(sprintf('Seafloor location relative to %s drop, meters. Depth %d m',instrument,depth))

%Can change axis if neccesary to fit all of the circles
axis([-2000 2000 -2000 2000])
grid()
      
%Make geographical map. May not work with Matlab < 2017b
hold off
figure(2)
ranging_lats(length(ranging_lats)+1) = settle_lat;
ranging_lons(length(ranging_lons)+1) = settle_lon;
type = zeros([1,length(ranging_lons)]);
type(end) = 1;
type = categorical(type);
gb = geobubble(ranging_lats,ranging_lons,1,type); 




