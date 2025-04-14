function [bsCoordinates, ueCoordinates, ueAssociationInfo] = infrastructureGridLayout(numSite, numSectorPerSite, interSiteDistance, uePlacementFlag, numUE)
%infrastructureGridLayout Calculate base station (BS) and user equipment
%(UE) positions for the infrastructure grid
%
%   [BSCOORDINATES, UECOORDINATES, UEASSOCIATIONINFO] =
%   infrastructureGridLayout(NUMSITE, NUMSECTORPERSITE, NUMUE,
%   UEPLACEMENTFLAG, INTERSITEDISTANCE) returns the BS and UE positions for
%   the given network. The base stations are assumed to be at the center of
%   each site. The inputs are as follows:
%   NUMSITE            - Number of sites in the network. Specify numSite
%                        as a numeric positive integer.
%   NUMSECTORPERSITE   - Number of sectors per site. Specify
%                        numSectorPerSite value as 1 or 3.
%   INTERSITEDISTANCE  - Distance between two adjacent BSs (in meters).
%                        interSiteDistance as a numeric positive scalar.
%   UEPLACEMENTFLAG    - Flag to control the distribution of UEs. Value 1
%                        means that the count of UEs in each cell is numUE.
%                        Value 0 means that total count of UEs in the
%                        scenario is numUE.
%   NUMUE              - Number of UEs in the scenario depending on the
%                        uePlacementFlag. uePlacementFlag 1 means that the
%                        the total count of UEs in the scenario is
%                        numSite*numSectorPerSite*numUE. uePlacementFlag 0
%                        means that total count of UEs in the scenario is
%                        numUE. Specify numUE as a numeric positive
%                        integer.
%
%   BSCOORDINATES is a matrix of size M-by-3, where M is the total number
%   of BS. The 'i'th row BSCOORDINATES contains the Cartesian coordinates
%   of a BS.
%   UECOORDINATES is a matrix of size N-by-3, where N is the total number
%   of UEs. The 'j'th row of UECOORDINATES contains the Cartesian
%   coordinates of a UE.
%   UEASSOCIATIONINFO is a vector of size N, where N is the total number of
%   UEs. The 'k'th element of UEASSOCIATIONINFO contains the BS index to
%   which 'k'th UE is connected.

% Copyright 2023 The MathWorks, Inc.

% centerX and centerY are x and y coordinates of BSs respectively
if numSectorPerSite == 1
    centerX = [0,sqrt(3)*cosd(30:60:360),2*sqrt(3)*cosd(30:60:360),3*cosd(0:60:300)];
    centerY = [0,sqrt(3)*sind(30:60:360),2*sqrt(3)*sind(30:60:360),3*sind(0:60:300)];
    cellSide = interSiteDistance/sqrt(3);
else
    centerX = [0,3*cosd(0:60:300),6*cosd(0:60:300),3*sqrt(3)*cosd(30:60:360)];
    centerY = [0,3*sind(0:60:300),6*sind(0:60:300),3*sqrt(3)*sind(30:60:360)];
    cellSide = interSiteDistance/3;
end

% Generate the coordinates for BS
bsCoordinates = zeros(numSite, 3); % BS position initialization
for i = 1:numSite
    bsCoordinates(i,:) = cellSide*[centerX(i), centerY(i), 0];
end

% Generate the coordinates for UEs
if uePlacementFlag % If UE distribution is per cell
    ueCoordinates = zeros(numSite*numSectorPerSite*numUE, 3);
    ueAssociationInfo = zeros(numSite*numSectorPerSite*numUE,1);
    % Vertices of the polygon that forms the boundary of a cell
    vx = cellSide*cosd(0:60:360);
    vy = cellSide*sind(0:60:360);
    if numSectorPerSite == 1
        a1 = zeros(1,3);
        a2 = a1;
    else
        % Offset coordinates, if a BS is at the meeting point of 3 sectors
        a1 = cellSide*cosd(0:120:240);
        a2 = cellSide*sind(0:120:240);
    end
    count = 1;
    for i = 1:numSite
        bsPos = bsCoordinates(i,:); % BS coordinates
        for j = 1:numSectorPerSite
            % Centre coordinates of the cell
            centerX = bsPos(1)+a1(j);
            centerY = bsPos(2)+a2(j);
            % Vertex coordinates of a particular cell
            verticesXCoordinates = centerX+vx;
            verticesYCoordinates = centerY+vy;
            % Calculate UEs position and association information
            [uePos, ueAssociation] = uePlacementPerCell(bsPos, i, ...
                verticesXCoordinates, verticesYCoordinates, cellSide, numUE);
            ueCoordinates(count:count+numUE-1,:) = uePos;
            ueAssociationInfo(count:count+numUE-1) = ueAssociation;
            count = count + numUE;
        end
    end
else % If UEs are randomly placed across the grid
    [ueCoordinates, ueAssociationInfo] = uePlacementPerGrid(bsCoordinates, ...
        numSectorPerSite, numUE, cellSide);
end
end

%% Local functions
function [ueCoordinates, ueAssociationInfo] = uePlacementPerCell(bsCoordinates, bsIndex, verticesXCoordinates, verticesYCoordinates, cellSide, numUE)
%uePlacementPerCell Generate random UE positions within a cell-site
%
%   [UECOORDINATES, UEASSOCIATIONINFO] = uePLACEMENTPERCELL(BSCOORDINATES,
%   BSINDEX, VERTICESXCOODINATES, VERTICESYCOODINATES, CELLSIDE, NUMUE)
%   returns UE positions for the given cell. The inputs are as follows:
%   BSCOORDINATES       - 3D Cartesian coordinates of a base station
%   BSINDEX             - Index of the base station with bsCoordinates
%   VERTICESXCOODINATES - Vertices' x-coordinates for the given cell
%   VERTICESYCOODINATES - Vertices' y-coordinates for the given cell
%   CELLSIDE            - Side length of the given cell (in meters)
%   NUMUE               - Number of UEs connected to a BS
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
uePos = [0 0 0];
% Calculate UE's position and association information
for i = 1:numUE
    flag = 1;
    while flag
        % Calculate UE position within the cell
        r = cellSide*rand;
        theta = 360*rand;
        uePos(1) = r*cosd(theta)+bsCoordinates(1);
        uePos(2) = r*sind(theta)+bsCoordinates(2);
        % Check if the random point is inside the cell
        [in,on] = inpolygon(uePos(1), uePos(2), verticesXCoordinates, verticesYCoordinates);
        if in && ~on && ~isequal(uePos, bsCoordinates)
            flag = 0;
        end
    end
    ueCoordinates(i,:) = uePos;
end
end

function [ueCoordinates, ueAssociationInfo] = uePlacementPerGrid(bsCoordinates, numSectorPerSite, numUEs, cellSide)
%uePlacementPerGrid Generate random UE positions for the entire grid
%
%   [UECOORDINATES, UEASSOCIATIONINFO] = uePLACEMENTPERGRID(BSCOORDINATES,
%   NUMSECTORPERSITE, NUMUES, CELLSIDE) returns the UE positions for the
%   given network. The inputs are as follows:
%   BSCOORDINATES       - 3D Cartesian coordinates of a BS
%   NUMSECTORPERSITE   - Number of sectors per site
%   NUMUES              - Number of UEs in the entire network
%   CELLSIDE            - Side length of the given hexagon (in meters)
%
%   UECOORDINATES is a matrix of size M-by-3, where M is the total number
%   of UEs. The 'i'th row of UECOORDINATES contains the Cartesian
%   coordinates of a UE.
%   UEASSOCIATIONINFO is a vector of size M-by-3, where M is the total
%   number of UES. The 'j'th element of UEASSOCIATIONINFO contains the BS
%   index to which 'j'th UE is connected.

% UE position initialization
ueCoordinates = zeros(numUEs, 3);
ueAssociationInfo = zeros(numUEs,1);
numBS = size(bsCoordinates, 1);
% Vertices of the polygon that forms the boundary of a cell
vx = cellSide*cosd(0:60:360);
vy = cellSide*sind(0:60:360);
for i = 1:numUEs
    randBSIndex = randi([1 numBS]);
    if numSectorPerSite == 1
        ax = 0;
        ay = 0;
    else
        % Randomly select a sector out of three sectors
        randSector = randi([1 3]);
        angle = 120*(randSector-1);
        ax = cellSide*cosd(angle);
        ay = cellSide*sind(angle);
    end
    % Calculate the vertices coordinates for the chosen cell
    verticesXCoordinates = bsCoordinates(randBSIndex,1)+vx+ax;
    verticesYCoordinates = bsCoordinates(randBSIndex,2)+vy+ay;
    % Calculate UE's position and association information
    [ueCoordinates(i,:), ueAssociationInfo(i)] = uePlacementPerCell(bsCoordinates(randBSIndex,:), ...
        randBSIndex, verticesXCoordinates, verticesYCoordinates, cellSide, 1);
end
end