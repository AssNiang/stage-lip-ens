function simulate_2stas(distanceAp1Ap2, rate, simulationDuration)
    
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
    % numNodes = 4;
    numAPs = 2;
    numSTAs = 2;

    % Nodes Positions
    distAp1Ap2 = str2double("" + distanceAp1Ap2); % Distance between AP1 and AP2 in meters
    apPositions = [0 0 0; distAp1Ap2 0 0];
    staPositions = [0 10 0; distAp1Ap2 10 0];

    disp(apPositions);



    % Nodes Configuration
    apConfig = wlanDeviceConfig(Mode="AP", ...
        MCS=1, ...
        ChannelBandwidth=20000000, ...
        TransmissionFormat="HT-Mixed", ...
        TransmitPower=16.02, ...
        TransmitQueueSize=bufferSize); % AP device configuration
    staConfig = wlanDeviceConfig(Mode="STA", ...
        MCS=1, ...
        ChannelBandwidth=20000000, ...
        TransmissionFormat="HT-Mixed", ...
        TransmitPower=16.02, ...
        TransmitQueueSize=bufferSize);    % STA device configuration
    
    % Create Nodes
    apNodes = wlanNode(Name="AP"+(1:numAPs), Position=apPositions, DeviceConfig=apConfig, PHYAbstractionMethod=PHYAbstractionMethod, MACFrameAbstraction=MACFrameAbstraction);
    staNodes = wlanNode(Name="STA"+(1:numSTAs), Position=staPositions, DeviceConfig=staConfig, PHYAbstractionMethod=PHYAbstractionMethod, MACFrameAbstraction=MACFrameAbstraction);
             
    % Create WLAN Network
    nodes = [apNodes staNodes];

    % Verify configuration
    hCheckWLANNodesConfiguration(nodes);

    % Associate Stations
    % associateStations(apNode, staNodes);
    for i = 1:numSTAs
        associateStations(apNodes(i), staNodes(i));
    end

    % --[Configure External Application Traffic]--
    for i = 1:numSTAs
        % Uplink (STA to AP)
        trafficUP = networkTrafficOnOff( ...
            DataRate=(arrivalRate * packetSize * 8)/1000, ...
            PacketSize=packetSize, ...
            OnTime=Inf, OffTime=0);
        addTrafficSource(staNodes(i), trafficUP, DestinationNode=apNodes(i), AccessCategory=0);
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
                    'TransmitReceiveDistance',10,...
                    'LargeScaleFadingEffect','None', ...    % 'None' (default) | 'Pathloss' | 'Shadowing' | 'Pathloss and shadowing'
                    'EnvironmentalSpeed', 0);   % Speed of the scatterers (diffuseurs : batiments, vehicules, etc.) in km/h
    
    % channel = hSLSTGaxMultiFrequencySystemChannel(nodes, tgnChan);
    % Définir un modèle logarithmique personnalisé
    % PL = PL_0 + 10 * n * log10(d/d_0), avec PL_0 à d_0 = 1 m
    customPathLoss = @(sig, rxInfo) customLogarithmicPathLoss(sig, rxInfo);
    % Ecart-type du shadowfading
    shadowFadingStd = 0; % default : 0

    % Renseigner les paramètres du canal
    channel = hSLSTGaxMultiFrequencySystemChannel(nodes, tgnChan, ...
        ShadowFadingStandardDeviation=shadowFadingStd, ...
        PathLossModel='custom', ... % default : free-space
        PathLossModelFcn=customPathLoss);

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
    apStats = statistics(apNodes);
    stasStats = statistics(staNodes);

    % Retrieve Performance Metrics
    avgLatency = performancePlotObj.getAveragePacketLatency();
    throughput = performancePlotObj.getThroughput();

    % Store Results
    resultRows = [
        [
            arrivalRate, ...
            simulationTime, ...
            "STA1->AP1", ...
            "" + stasStats(1).App.TransmittedPackets, ...
            "" + apStats(1).App.ReceivedPackets, ...
            avgLatency(1,2), ... % latency at AP
            throughput(3,2) ...- % throughput of STA1 (traffic STA1->AP1)
        ]; ...
        [
            arrivalRate, ...
            simulationTime, ...
            "STA2->AP2", ...
            "" + stasStats(2).App.TransmittedPackets, ...
            "" + apStats(2).App.ReceivedPackets, ...
            avgLatency(1,2), ... % latency at AP
            throughput(4,2) ...- % throughput of STA2 (traffic STA2->AP2)
        ]
    ];

    for i = 1:numSTAs
        resultRow = resultRows(i,:);
        % disp(resultRow);

        % Define Output File
        filename = '~/Documents/digital_twins/metrics/matlab_results_2stas.csv';
        
        % Check if file exists, append data or create with headers
        if isfile(filename)
            writematrix(resultRow, filename, 'WriteMode', 'append');
        else
            headers = ["Arrival Rate (pps)", "Simulation Duration (s)", "Flow Direction", "Packets Sent", "Packets Received", "Average Delay (s)", "Throughput"];
            writematrix([headers; resultRow], filename);
        end
    end

    disp(['Simulation completed for Arrival Rate: ', num2str(arrivalRate)]);

    % Fonction personnalisée pour un modèle logarithmique
    function pl = customLogarithmicPathLoss(sig, rxInfo)
        d = norm(sig.TransmitterPosition - rxInfo.Position); % Distance en mètres
        d_0 = 1; % Distance de référence (1 m)
        PL_0 = 46.677; % Perte de référence à d_0 = 1 m (comme sur ns-3)
        n = 3.0; % Exposant de perte (comme sur ns-3)
        
        % Modèle logarithmique : PL = PL_0 + 10 * n * log10(d/d_0)
        pl = PL_0 + 10 * n * log10(d/d_0);
        % disp(['Perte logarithmique appliquée : ', num2str(pl), ' dB']);
    end
end


