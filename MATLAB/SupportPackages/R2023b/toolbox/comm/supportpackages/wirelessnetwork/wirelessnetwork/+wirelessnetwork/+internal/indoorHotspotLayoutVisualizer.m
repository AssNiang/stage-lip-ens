function indoorHotspotLayoutVisualizer(bsCoordinates, ueCoordinates, cellRadius, floorLength, floorBreadth, varargin)
%indoorHotspotLayoutVisualizer Visualize the network for the given indoor
%hotspot configuration
%
%   indoorHotspotLayoutVisualizer(BSCOORDINATES, UECOORDINATES, CELLRADIUS,
%   FLOORLENGTH, FLOORBREADTH) creates an indoor hotspot layout in a new
%   figure according to the user specified configurations.
%
%   indoorHotspotLayoutVisualizer(BSCOORDINATES, UECOORDINATES, CELLRADIUS,
%   FLOORLENGTH, FLOORBREADTH, BSTAG, UETAG, AXES) creates an indoor
%   hotspot layout on the 'AXES' according to the user specified
%   configurations.
%
%   The inputs are as folllows:
%   BSCOORDINATES  - 3D Cartesian coordinates of base station (BS)
%   UECOORDINATES  - 3D Cartesian coordinates of user equipment (UE)
%   CELLRADIUS     - Radius of each cell (in meters)
%   FLOORLENGTH    - Length of the indoor floor (in meters)
%   FLOORBREADTH   - Breadth of the indoor floor (in meters)
%   BSTAG          - Tag values corresponding to BSs
%   UETAG          - Tag values corresponding to UEs
%   AXES           - Cartesian axes to visualize the network

% Copyright 2023 The MathWorks, Inc.

narginchk(5, 8);
numBS = size(bsCoordinates,1);
numUE = size(ueCoordinates,1);
if isempty(varargin) % Create a new figure
    % Using the screen width and height, calculate the figure width and height
    resolution = get(0, 'ScreenSize');
    screenWidth = resolution(3);
    screenHeight = resolution(4);
    figureWidth = screenWidth * 0.75;
    figureHeight = screenHeight * 0.75;
    fig = uifigure('Name', 'Network Layout Visualization', 'Position', [screenWidth * 0.05 screenHeight * 0.05 figureWidth figureHeight]);
    % Use desktop theme to support dark theme mode
    matlab.graphics.internal.themes.figureUseDesktopTheme(fig);
    g = uigridlayout(fig, [1 1]);
    ax = uiaxes('Parent',g);
    bsTag = "gNB"+(1:numBS);
    ueTag = "UE"+(1:numUE);
else % Set the required values from input arguments
    bsTag = varargin{1};
    ueTag = varargin{2};
    ax = varargin{3};
end

colors = ["--mw-graphics-colorOrder-2-primary", "--mw-graphics-colorOrder-1-primary"];
import matlab.graphics.internal.themes.specifyThemePropertyMappings

ax.DataAspectRatio = [1 1 1];
ax.XLabel.String = 'Meters';
ax.YLabel.String = 'Meters';

hold (ax,'on');
% Plot the network
for i = 1:numBS
    bx = bsCoordinates(i,1); % BS X-coordinate
    by = bsCoordinates(i,2); % BS Y-coordinate
    % Plot the circle representing each cell
    th = 0:pi/60:2*pi;
    x = cellRadius*cos(th)+bx;
    y = cellRadius*sin(th)+by;
    cellBoundary = plot(ax,x,y,Tag="Cell"+(i));
    specifyThemePropertyMappings(cellBoundary,Color="--mw-graphics-borderColor-axes-primary");

    % Plot BS
    bs = plot(ax,bx,by,Marker="^",MarkerSize=8,Tag=bsTag(i));
    % Specify BS color mapping for the current theme
    specifyThemePropertyMappings(bs,MarkerFaceColor=colors(1));
    specifyThemePropertyMappings(bs,MarkerEdgeColor=colors(1));
end

for idx = 1:numUE
    px = ueCoordinates(idx,1); % UE X-coordinate
    py = ueCoordinates(idx,2); % UE Y-coordinate
    ue = plot(ax,px,py,Marker="o",MarkerSize=4,Tag=ueTag(idx));
    % Specify UE color mapping for the current theme
    specifyThemePropertyMappings(ue,MarkerFaceColor=colors(2));
    specifyThemePropertyMappings(ue,MarkerEdgeColor=colors(2));
end

% Set axes limits
set(ax,'XLim',[0 floorLength],'YLim',[0 floorBreadth]);
hold (ax,'off');
end