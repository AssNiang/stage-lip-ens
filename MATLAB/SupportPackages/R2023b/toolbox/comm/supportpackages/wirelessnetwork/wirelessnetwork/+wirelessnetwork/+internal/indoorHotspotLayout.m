function [bsCoordinates, ueCoordinates, ueAssociationInfo, cellRadius]= indoorHotspotLayout(floorLength, floorBreadth, numBSRow, numBSColumn, uePlacementFlag, numUE)
%indoorHotspotLayout Calculate base station (BS) and user equipment (UE)
%positions for the indoor hotspot scenario
%
%   [BSCOORDINATES, UECOORDINATES, UEASSOCIATIONINFO, CELLRADIUS] =
%   indoorHotspotLayout(FLOORLENGTH, FLOORBREADTH, NUMBSROW, NUMBSCOLUMN,
%   NUMUE, UEPLACEMENTFLAG) returns the BS and UE positions for the given
%   indoor hotspot configurations. The inputs are as follows:
%   FLOORLENGTH         - Length of the indoor floor (in meters). Specify
%                         floorLength as a numeric positive scalar.
%   FLOORBREADTH        - Breadth of the indoor floor (in meters). Specify
%                         floorBreadth as a numeric positive scalar.
%   NUMBSROW            - Number of BS along X-axis. Specify numBSRow as a
%                         numeric positive integer.
%   NUMBSCOLUMN         - Number of BS along Y-axis. Specify numBSColumn
%                         as a numeric positive integer.
%   UEPLACEMENTFLAG     - Flag to control the distribution of UEs. Value 1
%                         means that the count of UEs in each cell is numUE.
%                         Value 0 means that the total count of UEs in the
%                         scenario is numUE.
%   NUMUE               - Number of UEs in the scenario depending on the
%                         uePlacementFlag. uePlacementFlag 1 means that the
%                         the total count of UEs in the scenario is
%                         numBSRow*numBSColumn*numUE. uePlacementFlag 0
%                         means that total count of UEs in the scenario is
%                         numUE. Specify numUE as a numeric positive
%                         integer.
%
%   BSCOORDINATES is a matrix of size N-by-3, where N is the total number
%   of BS i.e., NUMBSROW*NUMBSCOLUMN. The 'i'th row of BSCOORDINATES
%   contains the Cartesian coordinates of a BS.
%   UECOORDINATES is a matrix of size M-by-3, where M is the total number
%   of UEs. The 'j'th row of UECOORDINATES contains the Cartesian
%   coordinates of a UE.
%   UEASSOCIATIONINFO is a vector of size M, where M is the total number of
%   UEs. The 'k'th element of UEASSOCIATIONINFO contains the BS index to
%   which 'k'th UE is connected.
%   CELLRADIUS - Radius of each cell (in meters).

% Copyright 2023 The MathWorks, Inc.

% Calculate intersite distance (ISD) along X and Y axes
isdRow = floorLength;
isdColumn = floorBreadth;
if numBSRow > 1 % When BSs are placed in rows
    isdRow = floorLength/numBSRow;
end

% Left and right margins (distance between the vertical floor wall and the
% outer BS)
xDistOffset = isdRow/2;
if numBSColumn > 1 % When BSs are placed in columns
    isdColumn = floorBreadth/numBSColumn;
end
% Minimum of horizontal and vertical ISDs
isdColumn = min(isdRow, isdColumn);
% Top and bottom margins (distance between the horizontal floor wall and
% the outer BS)
yDistOffset = floorBreadth-((floorBreadth-(numBSColumn-1)*isdColumn)/2);

% BS position initialization
numBS = numBSRow*numBSColumn;
bsCoordinates = zeros(numBS, 3);
for rowIdx = 1:numBSColumn
    for colIdx = 1:numBSRow
        index = (rowIdx-1)*numBSRow+colIdx;
        % Assign Z-coordinate as BS antenna height (m), as per ITU-R, Guidelines for
        % evaluation of radio interface technologies for IMT-2020
        zCoordinate = 3;
        % Row-wise placement of BS starting from top left
        pos = [xDistOffset+(colIdx-1)*isdRow, yDistOffset-(rowIdx-1)*isdColumn, zCoordinate];
        bsCoordinates(index, :) = pos;
    end
end

% Generate the coordinates for UEs
cellRadius = isdColumn/2;
if uePlacementFlag % If UEs distribution is per cell
    ueCoordinates = zeros(numBS*numUE, 3);
    ueAssociationInfo = zeros(numBS*numUE, 1);
    count = 1;
    for bsIdx=1:numBS
        bsCoord = bsCoordinates(bsIdx,:); % 3D BS coordinates
        % Random position generation for UEs connected to a BS
        [pos, ueAssociation] = uePlacementPerCell(bsCoord, bsIdx, cellRadius, numUE);
        ueCoordinates(count:count+numUE-1,:) = pos;
        ueAssociationInfo(count:count+numUE-1) = ueAssociation;
        count = count+numUE;
    end
else % If UEs are randomly placed across the floor
    [ueCoordinates, ueAssociationInfo] = uePlacementPerGrid(bsCoordinates, numUE, cellRadius);
end
end

%% Local functions
function [ueCoordinates, ueAssociationInfo] = uePlacementPerCell(bsCoordinates, bsIndex, cellRadius, numUE)
%uePlacementPerCell Generate random UE position within a cell radius
%
%   [UECOORDINATES, UEASSOCIATIONINFO] = uePlacementPerCell(BSCOORDINATES,
%   BSIndex, CELLRADIUS, NUMUE) returns UE positions for the given indoor
%   hotspot scenario. The inputs are as follows:
%   BSCOORDINATES  - 3D Cartesian coordinates of a BS
%   BSINDEX        - Index of the BS with BSCoordinates
%   CELLRADIUS     - Radius of the given cell (in meters)
%   NUMUE          - Number of UEs connected to a BS
%
%   UECOORDINATES is a matrix of size N-by-3, where N is the total number
%   of UEs connected to a BS. The 'i'th row of UECOORDINATES contains the
%   Cartesian coordinates of a UE.
%   UEASSOCIATIONINFO is a vector of size N, where N is the total number of
%   UEs connected to a BS. The 'j'th element of UEASSOCIATIONINFO contains
%   the BS index to which 'j'th UE is connected.

% UE position initialization
ueCoordinates = zeros(numUE, 3);
ueAssociationInfo = repmat(bsIndex,1,numUE);

% Define the circular area for a cell
bsTheta = 0:pi/60:2*pi;
xv = cellRadius*cos(bsTheta)+bsCoordinates(1);
yv = cellRadius*sin(bsTheta)+bsCoordinates(2);
for i = 1:numUE
    flag = 1;
    % Random position of a UE
    while flag
        % Calculate UE position within the cell
        ueTheta = 360*rand;
        r = cellRadius*rand;
        uePos(1) = bsCoordinates(1)+r*cos(ueTheta);
        uePos(2) = bsCoordinates(2)+r*sin(ueTheta);
        % Assign Z-coordinate as UE antenna height (m), as per ITU-R, Guidelines for
        % evaluation of radio interface technologies for IMT-2020
        uePos(3) = 1.5;
        % Check if the random point is inside the cell
        [in,on] = inpolygon(uePos(1), uePos(2), xv, yv);
        if in && ~on && ~isequal(uePos, bsCoordinates)
            flag = 0;
        end
    end
    ueCoordinates(i,:) = uePos;
end
end

function [ueCoordinates, ueAssociationInfo] = uePlacementPerGrid(bsCoordinates, numUE, cellRadius)
%uePlacementPerGrid Generate random UE positions for the entire indoor floor
%
%   [UECOORDINATES, UEASSOCIATIONINFO] = uePLACEMENTPERGRID(BSCOORDINATES,
%   NUMUE, CELLRADIUS) returns the UE positions for the given scenario. The
%   inputs are as follows:
%   BSCOORDINATES  - 3D Cartesian coordinates of a BS
%   NUMUE          - Number of UEs in the scenario
%   CELLRADIUS     - Radius of the given cell (in meters)
%
%   UECOORDINATES is a matrix of size M-by-3, where M is the total number
%   of UEs. The 'i'th row of UECOORDINATES contains the Cartesian
%   coordinates of a UE.
%   UEASSOCIATIONINFO is a vector of size M-by-3, where M is the total
%   number of UES. The 'j'th element of UEASSOCIATIONINFO contains the BS index
%   to which 'j'th UE is connected.

% UE position initialization
ueCoordinates = zeros(numUE, 3);
ueAssociationInfo = zeros(numUE,1);
numBS = size(bsCoordinates, 1);
for i = 1:numUE
    randBSIndex = randi([1 numBS]);
    % Calculate UE position and association information
    [ueCoordinates(i,:), ueAssociationInfo(i)] = uePlacementPerCell(bsCoordinates(randBSIndex,:), ...
        randBSIndex, cellRadius, 1);
end
end