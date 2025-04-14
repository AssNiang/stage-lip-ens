function hCompareOFDMvsULOFDMAThroughputs(plotStoredThroughputValues)
%hCompareOFDMvsULOFDMAThroughputs Plot OFDM and uplink (UL) OFDMA
%throughputs
%
%   hCompareOFDMvsULOFDMAThroughputs(true) plots the throughputs stored
%   after simulating OFDM and UL OFDMA transmissions against varying number
%   of stations.
%
%   hCompareOFDMvsULOFDMAThroughputs(false) runs simulations and plots the
%   throughputs of OFDM and UL OFDMA transmissions against varying number
%   of stations (STAs).
% 
%   The function runs multiple OFDM and UL OFDMA simulations with one
%   access point (AP) and varying number of STAs with this configuration.
%   wlanDeviceConfig parameters at AP and STAs
%           Parameter        |        Value
%   -------------------------------------------------
%       ChannelBandwidth     |  20 MHz, upto 9 STAs
%                            |  40 MHz, 10-18 STAs
%                            |  80 MHz, 19-37 STAs
%                            |  160 MHz, > 37 STAs
%       MCS                  |  11
%       MPDUAggregationLimit |  1
%       TransmitPower        |  20 dBm
%       DisableRTS           |  true
%
%   networkTrafficOnOff parameters at STAs
%           Parameter        |        Value
%   -------------------------------------------------
%       DataRate             |        100000 Kbps
%       PacketSize           |        100 Bytes

%   Copyright 2023 The MathWorks, Inc.

if ~plotStoredThroughputValues
    % Check for Support Package Installation
    wirelessnetworkSupportPackageCheck;

    % Simulation scenario
    numStations = 5:10:140;
    numRuns = numel(numStations); % Number of simulation runs
    throughputValuesOFDM = zeros(1,numRuns);
    throughputValuesOFDMA = zeros(1,numRuns);

    ulOfdma = true;
    % To speed up the simulation, use a parfor loop. You need to install
    % Parallel Computing Toolbox(TM) to use parfor. If Parallel Computing
    % Toolbox is not installed, 'parfor' will default to the normal 'for'
    % statement.
    parfor runID = 1:numRuns
        throughputValuesOFDM(runID) = generateThroughputs(numStations(runID), ~ulOfdma);
        fprintf("OFDM throughput with %d stations: %.4f \n",numStations(runID),throughputValuesOFDM(runID));
        throughputValuesOFDMA(runID) = generateThroughputs(numStations(runID), ulOfdma);
        fprintf("OFDMA throughput with %d stations: %.4f \n",numStations(runID),throughputValuesOFDMA(runID));
    end

else
    % Stored throughput results for OFDM configuration (Mbps)
    throughputValuesOFDM = [4.3008 4.0696 3.8352 3.6896 3.5472 3.4824 3.3960 3.3008 3.2064 3.1272 3.0864 3.0224 2.9912 2.9216];

    % Stored throughput results for UL OFDMA configuration (Mbps)
    throughputValuesOFDMA = [6.3872 15.0064 20.8872 26.6064 30.2328 34.4488 37.1656 39.8824 39.5248 39.5728 39.8504 39.7624 39.0920 39.6480];
end

plotThroughputs(throughputValuesOFDM,throughputValuesOFDMA);
end

% Plot throughputs
function plotThroughputs(throughputOFDM,throughputOFDMA)
    resolution = get(0,"screensize");
    screenWidth = resolution(3);
    screenHeight = resolution(4);
    figureWidth = screenWidth*0.45;
    figureHeight = screenHeight*0.5;

    % Create figure
    figure(Name="UL OFDMA vs OFDM throughputs",Position=[screenWidth*0.2, screenHeight*0.1, figureWidth, figureHeight]);

    % Number of STAs
    numStations = 5:10:140;

    % Plot throughput obtained from OFDM simulations
    plot(numStations,throughputOFDM,Marker="o",LineWidth=1.5);

    % Retain OFDM throughput plot
    hold on;

    % Plot throughput obtained from UL OFDMA simulations
    plot(numStations,throughputOFDMA,Marker="+",LineWidth=1.5);
    grid on;
    xlabel("Number of STAs");
    ylabel("Throughput (Mbps)");
    legend({"OFDM",newline+"UL OFDMA"},Location="northeastoutside");
    title("Total Throughput of STAs");
end

% Generate throughputs
function throughput = generateThroughputs(numStations, ulOfdmaFlag)

    rng(1,"combRecursive");                           % Seed for random number generator
    simulationTime = 1;                               % Simulation time in seconds
    PHYAbstractionMethod = "tgax-mac-calibration";
    networkSimulator = wirelessNetworkSimulator.init; % Initialize network simulator

    % Number of nodes in the simulation
    numNodes = numStations+1; % Only 1 AP, remaining nodes are STAs

    % Assign positions to the nodes
    staXPositions = 0.1.*(1:numStations);
    staYPositions = 0.1.*(numStations:-1:1);
    staPositions = [staXPositions' staYPositions' zeros(numStations,1)];
    nodePositions = [0 0 0; staPositions]; % AP position is [0 0 0]

    % To allow transmissions from more users, increase the channel bandwidth
    % along with the STAs
    if numStations<=9
        channelBandwidth = 20e6;
    elseif numStations>=10 && numStations<=18
        channelBandwidth = 40e6;
    elseif numStations>=19 && numStations<=37
        channelBandwidth = 80e6;
    elseif numStations>=37
        channelBandwidth = 160e6;
    end

    % Configure the AP
    accessPointCfg = wlanDeviceConfig(Mode="AP",...
        MCS=11,DisableRTS=true,...
        ChannelBandwidth=channelBandwidth,MPDUAggregationLimit=1,...
        EnableUplinkOFDMA=ulOfdmaFlag, TransmitPower=20);

    % Configure the STA
    stationCfg = wlanDeviceConfig(Mode="STA",...
        MCS=11,DisableRTS=true,...
        ChannelBandwidth=channelBandwidth,MPDUAggregationLimit=1,...
        TransmitPower=20);

    % Create AP node
    accessPoint = wlanNode(Name="AP", ...
        Position=nodePositions(1,:), ...
        DeviceConfig=accessPointCfg,...
        PHYAbstractionMethod=PHYAbstractionMethod, ...
        MACFrameAbstraction=true);

    % Create STA nodes
    stations = wlanNode(Position=nodePositions(2:numNodes,:), ...
        DeviceConfig=stationCfg, ...
        PHYAbstractionMethod=PHYAbstractionMethod, ...
        MACFrameAbstraction=true);

    % Create a vector of the AP and STA nodes and name it as 'nodes'
    nodes = [accessPoint stations];

    % Check configuration of the created nodes
    hCheckWLANNodesConfiguration(nodes);

    % Associate the STAs to the AP
    associateStations(accessPoint,stations);

    % Configure and attach application traffic from associated STAs to the AP
    for staID=1:numNodes-1
        trafficSource(staID) = networkTrafficOnOff(DataRate=100000,PacketSize=100,OnTime=inf,OffTime=0); %#ok<AGROW>
        addTrafficSource(stations(staID),trafficSource(staID),DestinationNode=accessPoint,AccessCategory=0);
    end

    % Wireless Channel
    channel = hSLSTGaxMultiFrequencySystemChannel(nodes);

    % Add the channel model to the wireless network simulator
    addChannelModel(networkSimulator,channel.ChannelFcn);

    % Add nodes to the wireless network simulator
    addNodes(networkSimulator,nodes);

    % Run simulation
    run(networkSimulator,simulationTime);

    % Retrieve throughput from simulation results
    stats = statistics(nodes);
    macPayloadBytes = arrayfun(@(x) x.MAC.TransmittedPayloadBytes, stats(2:end), UniformOutput=true);
    throughput = sum(macPayloadBytes*8*1e-6)/simulationTime;
end