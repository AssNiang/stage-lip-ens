function simulate_simple(staPosition, rate, simulationDuration)
    
    % --[Check if the Comm Toolbox is installed]--
    wirelessnetworkSupportPackageCheck;

    % --[Configure Simulation Parameters]--

    % Set the seed to 1 : affects backoff counter selection (L2), packet reception success (L1)
    rng(1, "combRecursive");

    % Set the arrival rate
    arrivalRate = str2double(rate + "");

    % Set the simulation time (in seconds)
    simulationTime = str2double(simulationDuration + "");

    % Visualization flags
    enablePacketVisualization = true;
    enableNodePerformancePlot = true;

    % Modeling full MAC and PHY processing
    MACFrameAbstraction = false;
    PHYAbstractionMethod = "none";

    % Packet Capture for analysis
    capturePacketsFlag = false;

    % Packet Size
    packetSize = 1500; % in bytes

    % Buffer Size
    bufferSize = 500;

    % --[Configure WLAN Scenario]--
    networkSimulator = wirelessNetworkSimulator.init;

    % Number of Nodes
    numNodes = 2;
    numSTAs = numNodes - 1;

    % Nodes Positions
    apPosition = [0 0 0];
    % staPositions = [((30/numSTAs) .* (1:numSTAs))', ((30/numSTAs) .* (numSTAs:-1:1))', zeros(numSTAs,1)];
    staPositions = staPosition;
    disp(staPositions(1))

    % Nodes Configuration
    apConfig = wlanDeviceConfig(Mode="AP", ...
        MCS=1, ...
        ChannelBandwidth=20000000, ...
        TransmitQueueSize=bufferSize); % AP device configuration
    staConfig = wlanDeviceConfig(Mode="STA", ...
        MCS=1, ...
        ChannelBandwidth=20000000, ...
        TransmissionFormat="HT-Mixed", ...
        TransmitPower=16.02, ...
        TransmitQueueSize=bufferSize);    % STA device configuration
    
    % Create Nodes
    apNode = wlanNode(Name="AP", Position=apPosition, DeviceConfig=apConfig, PHYAbstractionMethod=PHYAbstractionMethod, MACFrameAbstraction=MACFrameAbstraction);
    staNodes = wlanNode(Name="STA"+(1:numSTAs), Position=staPositions, DeviceConfig=staConfig, PHYAbstractionMethod=PHYAbstractionMethod, MACFrameAbstraction=MACFrameAbstraction);
        
    % Create WLAN Network
    nodes = [apNode staNodes];

    % Verify configuration
    hCheckWLANNodesConfiguration(nodes);

    % Associate Stations
    associateStations(apNode, staNodes);

    % --[Configure External Application Traffic]--
    for i = 1:numSTAs
        % Uplink (STA to AP)
        trafficDown = networkTrafficOnOff( ...
            DataRate=(arrivalRate * packetSize * 8)/1000, ...
            PacketSize=packetSize, ...
            OnTime=Inf, OffTime=0);
        addTrafficSource(apNode, trafficDown, DestinationNode=staNodes(i), AccessCategory=0);
    end

    % Wireless Channel
        % The 802.11n channel object uses a filtered Gaussian noise model in which 
        % ...the path delays, powers, angular spread, angles of arrival, and angles of departure 
        % ...are determined empirically. The specific modeling approach is described in [1]. 
        % TransmitReceiveDistance is used to compute the path loss, and to determine whether the channel has 
        % ...a line of sight (LOS) or non line of sight (NLOS) condition. The path loss 
        % ...and standard deviation of shadow fading loss depend on the separation between the transmitter and the receiver.
        % Model-A : d_BP = 5m -> path_loss exponent = 3.5, shadow_fading std = 4 max_delay=0ns
        % ...ref: https://fr.mathworks.com/help/wlan/ref/wlantgnchannel-system-object.html
    tgnChan = wlanTGnChannel('DelayProfile','Model-A', ...
                    'TransmitReceiveDistance',staPositions(1),...
                    'LargeScaleFadingEffect','Pathloss', ...    % 'None' (default) | 'Pathloss' | 'Shadowing' | 'Pathloss and shadowing'
                    'ChannelFiltering', false, ...
                    'NumSamples', 80, ...
                    'EnvironmentalSpeed', 0);   % Speed of the scatterers (diffuseurs : batiments, vehicules, etc.) in km/h
    channel = hSLSTGaxMultiFrequencySystemChannel(nodes, tgnChan);
    addChannelModel(networkSimulator, channel.ChannelFcn);


    % --[Packet Capture]--
    if capturePacketsFlag
        capturePacketsObj = hExportWLANPackets(nodes);
    end

    % --[Simulation and Results]--
    if enablePacketVisualization
        packetVisObj = hPlotPacketTransitions(nodes, simulationTime, FrequencyPlotFlag=false);
    end

    if enableNodePerformancePlot
        performancePlotObj = hVisualizePerformance(nodes, simulationTime);
    end

    % Run the simulator
    addNodes(networkSimulator, nodes);
    run(networkSimulator, simulationTime);

    % Delete PCAP objects
    if capturePacketsFlag
        delete(capturePacketsObj.PCAPObjList);
    end

    % Retrieve the APP, MAC and PHY statistics at each node
    apStats = statistics(apNode);
    stasStats = statistics(staNodes);
    nbSentPackets = "" + apStats(1).App.TransmittedPackets;
    nbReceivedPackets = "" + stasStats(1).App.ReceivedPackets;

    % Retrieve Performance Metrics
    avgLatency = performancePlotObj.getAveragePacketLatency();
    % packetLoss = performancePlotObj.getPacketLossRatio();
    throughput = performancePlotObj.getThroughput();

    % Store Results
    resultRow = [arrivalRate, simulationTime, "AP->STA1", nbSentPackets, nbReceivedPackets, avgLatency(2,2), throughput(1,2)];

    % Define Output File
    filename = '~/Documents/digital_twins/metrics/matlab_results.csv';

    % Check if file exists, append data or create with headers
    if isfile(filename)
        writematrix(resultRow, filename, 'WriteMode', 'append');
    else
        headers = ["Arrival Rate (pps)", "Simulation Duration (s)", "Flow Direction", "Packets Sent", "Packets Received", "Average Delay (s)", "Throughput"];
        writematrix([headers; resultRow], filename);
    end

    disp(['Simulation completed for Arrival Rate: ', num2str(arrivalRate)]);
end


