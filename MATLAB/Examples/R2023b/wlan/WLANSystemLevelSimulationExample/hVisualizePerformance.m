classdef hVisualizePerformance < handle
%hVisualizePerformance Plots the packet loss ratio, throughput, and
%latency for the nodes
%
%   hVisualizePerformance(NODES,SIMULATIONTIME) plots the packet loss
%   ratio, throughput, and average application packet latency for the
%   Bluetooth and WLAN nodes specified.
%
%   NODES is a normal array or a cell array of objects of type
%   bluetoothNode, bluetoothLENode, wlanNode, or helperCoexNode.
%
%   SIMULATIONTIME is a finite positive scalar indicating the simulation
%   time in seconds.

%   Copyright 2023 The MathWorks, Inc.

    properties (SetAccess=private)
        %WLANNodes List of WLAN nodes for visualization
        WLANNodes = wlanNode.empty()

        %BluetoothNodes List of Bluetooth nodes for visualization
        BluetoothNodes

        %CoexNodes List of coexistence nodes for visualization
        CoexNodes

        %SimulationTime Simulation time in seconds
        SimulationTime = 0

        %AveragePacketLatency This property specifies the average latency computed
        %at each node in seconds. The first column represents node ID and the
        %second column represents the latency value
        AveragePacketLatency

        %Throughput This property specifies the throughput computed at each node in
        %seconds. The first column represents node ID and the second column
        %represents the throughput value
        Throughput

        %PacketLossRatio This property specifies the packet loss ratio computed at
        %each node in seconds. The first column represents node ID and the second
        %column represents the packet loss ratio value
        PacketLossRatio
    end

    properties (Access=private)
        %pPacketLatency This property specifies the latency computed at each node
        %in seconds. The first column represents node ID and the second column
        %represents the latency value.
        pPacketLatency

        %pNumPackets This property specifies the number of application packets
        %received at each node. The first column represents node ID and the second
        %column represents the number of application packets received.
        pNumPackets
    end

    %% Constructor
    methods
        function obj = hVisualizePerformance(nodes,simulationTime)

            % Validate the simulation time
            validateattributes(simulationTime,{'numeric'},{'nonempty','scalar','positive','finite'},mfilename,"simulationTime");

            % Return if no nodes are available
            if isempty(nodes)
                return;
            end

            % Validate the nodes
            if iscell(nodes)
                for idx = 1:numel(nodes)
                    validateattributes(nodes{idx},["bluetoothLENode","bluetoothNode","wlanNode","helperCoexNode"],{'scalar'},mfilename,"nodes");
                end
            else
                validateattributes(nodes(1),["bluetoothLENode","bluetoothNode","wlanNode","helperCoexNode"],{'scalar'},mfilename,"nodes");
                nodes = num2cell(nodes);
            end

            % Store the nodes
            numBluetoothNodes = 0; numWLANNodes=0; numCoexNodes = 0;
            for idx = 1:numel(nodes)
                if isa(nodes{idx},"helperCoexNode")
                    numCoexNodes = numCoexNodes+1;
                    obj.CoexNodes{numCoexNodes} = nodes{idx};
                    addlistener(nodes{idx},"AppDataReceived",@(srcNode,eventData) calculatePacketLatency(obj,srcNode,eventData));
                elseif isa(nodes{idx},"bluetoothNode") || isa(nodes{idx},"bluetoothLENode")
                    numBluetoothNodes = numBluetoothNodes+1;
                    obj.BluetoothNodes{numBluetoothNodes} = nodes{idx};
                    if isa(nodes{idx},"bluetoothNode")
                        addlistener(nodes{idx},"AppDataReceived",@(srcNode,eventData) calculatePacketLatency(obj,srcNode,eventData));
                    end
                else
                    numWLANNodes = numWLANNodes+1;
                    obj.WLANNodes(numWLANNodes) = nodes{idx};
                    addlistener(nodes{idx},"AppDataReceived",@(srcNode,eventData) calculatePacketLatency(obj,srcNode,eventData));
                end
            end
            numNodes = numWLANNodes+numBluetoothNodes+numCoexNodes;

            % Store the configurations
            obj.SimulationTime = simulationTime;

            % Initialize the throughput and latency
            obj.pPacketLatency = zeros(numNodes,3);
            for idx = 1:numBluetoothNodes
                obj.pPacketLatency(idx,1) = obj.BluetoothNodes{idx}.ID;
            end
            for idx = 1:numWLANNodes
                obj.pPacketLatency(numBluetoothNodes+idx,1) = obj.WLANNodes(idx).ID;
            end
            % Attach ID and packet type for coexistence nodes
            countDevices = 1;
            for idx = 1:numCoexNodes
                if ~isempty(obj.CoexNodes{idx}.BluetoothDevice.DeviceName)
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,1) = obj.CoexNodes{idx}.ID;
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,3) = 4;
                    countDevices = countDevices+1;
                end
                if ~isempty(obj.CoexNodes{idx}.BluetoothLEDevice.DeviceName)
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,1) = obj.CoexNodes{idx}.ID;
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,3) = 3;
                    countDevices = countDevices+1;
                end
                if ~isempty(obj.CoexNodes{idx}.WLANDevice.DeviceName)
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,1) = obj.CoexNodes{idx}.ID;
                    obj.pPacketLatency(numBluetoothNodes+numWLANNodes+countDevices,3) = 1;
                    countDevices = countDevices+1;
                end
            end
            obj.AveragePacketLatency = obj.pPacketLatency;
            obj.Throughput = obj.pPacketLatency;
            obj.PacketLossRatio = obj.pPacketLatency;
            obj.pNumPackets = obj.pPacketLatency;

            % Schedule action to perform at the end of simulation
            networkSimulator = wirelessNetworkSimulator.getInstance;
            scheduleAction(networkSimulator,@(varargin) plotNetworkStats(obj),[],simulationTime);
        end
    end

    %% Figure Based Methods
    methods (Access=private)
        function plotNetworkStats(obj)
            %plotNetworkStats Plot throughput (in Mbps), average packet latency (in
            %seconds), and packet loss ratio at each node

            % Calculate and plot the graph for Bluetooth Nodes
            if numel(obj.BluetoothNodes)>0
                [nodeNames,plr,throughput,latency] = calculateStats(obj,obj.BluetoothNodes);
                figHandle = plotBarGraph(obj,nodeNames,plr,throughput,latency,"Kbps",[0 ones(1,numel(obj.BluetoothNodes))],"Node Name");
                figHandle.Tag = "Bluetooth Performance";
                sgtitle("Performance of Bluetooth Nodes");
            end

            % Calculate and plot the graph for WLAN Nodes
            if numel(obj.WLANNodes)>0
                [nodeNames,plr,throughput,latency] = calculateStats(obj,num2cell(obj.WLANNodes));
                figHandle = plotBarGraph(obj,nodeNames,plr,throughput,latency,"Mbps",[0 ones(1,numel(obj.WLANNodes))],"Node Name");
                figHandle.Tag = "WLAN Performance";
                sgtitle("Performance of WLAN Nodes");
            end

            % Calculate and plot the graph for coexistence Nodes
            if numel(obj.CoexNodes)>0
                nodeNames = []; plr = []; throughput = []; latency = [];
                numDevices = zeros(numel(obj.CoexNodes)+1,1);
                for idx = 1:numel(obj.CoexNodes)
                    [stackNames,stackPLR,stackThroughput,stackLatency] = calculateStatsCoex(obj,obj.CoexNodes{idx});
                    nodeNames = [nodeNames stackNames]; %#ok<*AGROW>
                    plr = [plr stackPLR];
                    throughput = [throughput stackThroughput];
                    latency = [latency stackLatency];
                    numDevices(idx+1) = sum(obj.CoexNodes{idx}.NumDevicesType);
                end
                figHandle = plotBarGraph(obj,nodeNames,plr,throughput,latency,"Mbps",numDevices,"Device Name");
                figHandle.Tag = "Coexistence node Performance";
                sgtitle("Performance of Coexistence Nodes");
            end
        end

        function figHandle = plotBarGraph(~,nodeNames,plr,throughput,latency,throughputUnits,numDevices,xlabelVal)
            %plotBarGraph Plots the bar graph

            % Get screen resolution and create figure
            resolution = get(0,"screensize");
            figHandle = figure;
            numNodes = numel(nodeNames);
            if numNodes>15
                xTickAngleVal = 90;
            else
                xTickAngleVal = 20;
            end

            % Calculate how the bars need to be grouped. Same node device bars will be
            % spaced nearer
            xValue = zeros(sum(numDevices),1);
            xValueCount = 0;
            for idx = 2:numel(numDevices)
                xValue(xValueCount+1:xValueCount+numDevices(idx),:) = (1:numDevices(idx))+sum(numDevices(1:idx-1));
                xValueCount = xValueCount+numDevices(idx);
                numDevices(idx) = numDevices(idx)+0.5;
            end

            % Plot the throughput
            s1 = subplot(3,1,1);
            bar(s1,xValue,throughput,"BarWidth",0.95);
            title("Throughput at Each Node");
            xlabel(xlabelVal);
            xticklabels(nodeNames);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            ylabel('Throughput ('+ string(throughputUnits) + ')');

            % Plot the Packet Loss Ratio
            s2 = subplot(3,1,2);
            bar(s2,xValue,plr,"BarWidth",0.95);
            title("Packet Loss at Each Node");
            xlabel(xlabelVal);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            xticklabels(nodeNames);
            ylabel("Packet Loss Ratio");

            % Plot the Average Application Packet Latency
            s3 = subplot(3,1,3);
            bar(s3,xValue,latency,"BarWidth",0.95);
            title("Average Packet Latency at Each Node");
            xlabel(xlabelVal);
            xticks(xValue)
            xtickangle(xTickAngleVal);
            xticklabels(nodeNames);
            ylabel("Latency (s)");
        end
    end

    %% Standard Based Methods
    methods (Access=private)
        function calculatePacketLatency(obj,srcNode,eventData)
            %calculatePacketLatency Calculate average packet latency

            notificationData = eventData.Data;
            % Find the node index in the stored aggregate packet latency
            nodeIdx = find(srcNode.ID==obj.pPacketLatency(:,1));
            if numel(nodeIdx)>1
                if isfield(notificationData,"PacketType")
                    nodeIdx = nodeIdx(obj.pPacketLatency(nodeIdx,3)==notificationData.PacketType);
                else
                    nodeIdx = nodeIdx(obj.pPacketLatency(nodeIdx,3)==4);
                end
            end

            % Aggregate the packet latency
            obj.pPacketLatency(nodeIdx,2) = obj.pPacketLatency(nodeIdx,2)+ ...
                notificationData.CurrentTime-notificationData.PacketGenerationTime;

            % Increment the number of App packets received
            obj.pNumPackets(nodeIdx,2) = obj.pNumPackets(nodeIdx,2)+1;

            % Calculate the average packet latency
            obj.AveragePacketLatency(nodeIdx,2) = obj.pPacketLatency(nodeIdx,2)/obj.pNumPackets(nodeIdx,2);
        end

        function [nodeNames,packetLossRatio,throughput,averageAppPacketLatency] = calculateStats(obj,nodes)
            %calculateStats Calculate packet loss ratio, throughput, and average
            %application packet latency for the nodes specified

            % Initialize
            numNodes = numel(nodes);
            nodeIdxes = zeros(1,numNodes);
            packetLossRatio = zeros(1,numNodes);
            throughput = zeros(1,numNodes);
            averageAppPacketLatency = zeros(1,numNodes);
            count = 1;
            nodeNames = "";

            % Plot the performance of all the nodes
            for idx = 1:numNodes
                % Get the index at the packet latency for the node
                nodeIdxes(idx) = find(nodes{idx}.ID==obj.pPacketLatency(:,1));
                nodeNames(idx) = nodes{idx}.Name;

                % Get the node name and statistics of the node
                stats = statistics(nodes{idx});

                % Calculate throughput and packet loss ratio
                if isa(nodes{idx},"wlanNode")
                    techName = "WLAN";
                elseif isa(nodes{idx},"bluetoothNode")
                    techName = "BREDR";
                elseif isa(nodes{idx},"bluetoothLENode")
                    techName = "LE";
                    obj.AveragePacketLatency(nodeIdxes(idx),2) = stats.App.AveragePacketLatency;
                end
                packetLossRatio(count) = calculatePLR(obj,techName,stats);
                throughput(count) = calculateThroughput(obj,techName,stats,obj.SimulationTime);

                % Retrieve the average app packet latency only for the specified nodes
                averageAppPacketLatency(count) = obj.AveragePacketLatency(nodeIdxes(idx),2);
                obj.PacketLossRatio(nodeIdxes(idx),2) = packetLossRatio(count)';
                obj.Throughput(nodeIdxes(idx),2) = throughput(count)';
                count = count+1;
            end
        end

        function [nodeNames,packetLossRatio,throughput,averageAppPacketLatency] = calculateStatsCoex(obj,nodes)
            %calculateStatsCoex Calculate statistics of coexistence nodes

            % Initialize
            numNodes = numel(nodes);
            packetLossRatio = zeros(1,numNodes);
            throughput = zeros(1, numNodes);
            averageAppPacketLatency = zeros(1, numNodes);
            count = 1;
            nodeNames = "";

            % Get the node name and statistics of the node
            statsNode = statistics(nodes);

            for idx = 1:3
                % Get the index at the packet latency for the node
                nodeIdxes = find(nodes.ID==obj.pPacketLatency(:,1));
                packetType = idx;
                if idx>1
                    packetType = packetType+1;
                end
                nodeIdx = nodeIdxes(obj.pPacketLatency(nodeIdxes,3)==packetType);
                techName = string.empty();
                % Calculate throughput and packet loss ratio
                if isfield(statsNode,"WLANDevice") && packetType==1
                    stats = statsNode.WLANDevice;
                    techName = "WLAN";
                elseif isfield(statsNode,"BluetoothDevice") && packetType==4
                    stats = statsNode.BluetoothDevice;
                    techName = "BREDR";
                elseif isfield(statsNode,"BluetoothLEDevice") && packetType==3
                    stats = statsNode.BluetoothLEDevice;
                    techName = "LE";
                end
                if ~isempty(techName)
                    packetLossRatio(count) = calculatePLR(obj,techName,stats);
                    throughput(count) = calculateThroughput(obj,techName,stats,obj.SimulationTime);
                    if contains(nodes.Name,techName)
                        nodeNames(count) = nodes.Name;
                    else
                        nodeNames(count) = strjoin([nodes.Name techName]);
                    end

                    % Retrieve the average app packet latency only for the specified nodes
                    averageAppPacketLatency(count) = obj.AveragePacketLatency(nodeIdx,2);
                    obj.PacketLossRatio(nodeIdx,2) = packetLossRatio(count)';
                    obj.Throughput(nodeIdx,2) = throughput(count)';
                    count = count+1;
                end
            end
        end

        function packetLossRatio = calculatePLR(~,techName,stats)
            %calculatePLR Calculate the packet loss ratio based on the technology

            switch techName
                case "WLAN"
                    packetLossRatio = sum(([stats.MAC.RetransmittedDataFrames])/[stats.MAC.TransmittedDataFrames]);
                case "BREDR"
                    transmittedDataPackets = 0; retransmittedDataPackets = 0;
                    for peripheralIdx = 1:numel(stats.Baseband.ConnectionStats)
                        statsConn = stats.Baseband.ConnectionStats(peripheralIdx);
                        transmittedDataPackets = transmittedDataPackets+statsConn.TransmittedACLPackets+ ...
                            statsConn.TransmittedDVPackets;
                        retransmittedDataPackets = retransmittedDataPackets+statsConn.RetransmittedACLPackets+ ...
                            statsConn.DVWithRetransmittedData;
                    end
                    packetLossRatio = retransmittedDataPackets/(transmittedDataPackets+retransmittedDataPackets);
                case "LE"
                    for peripheralIdx = 1:numel(stats.LL)
                        statsConn = stats.LL(peripheralIdx);
                        transmittedDataPackets = statsConn.TransmittedDataPackets;
                        retransmittedDataPackets = statsConn.RetransmittedDataPackets;
                    end
                    packetLossRatio = retransmittedDataPackets/(transmittedDataPackets+retransmittedDataPackets);
            end
        end
        

        function throughput = calculateThroughput(~,techName,stats,simulationTime)
            %calculateThroughput Calculate the throughput based on the technology

            switch techName
                case "WLAN"
                    throughput = (sum([stats.MAC.TransmittedPayloadBytes])*8*1e-6)/simulationTime;
                case "BREDR"
                    transmittedPayloadBytes = 0;
                    for peripheralIdx = 1:numel(stats.Baseband.ConnectionStats)
                        statsConn = stats.Baseband.ConnectionStats(peripheralIdx);
                        transmittedPayloadBytes = transmittedPayloadBytes+statsConn.TransmittedDataBytes;
                    end
                    throughput = transmittedPayloadBytes*8*1e-6/simulationTime;
                case "LE"
                    for peripheralIdx = 1:numel(stats.LL)
                        statsConn = stats.LL(peripheralIdx);
                        transmittedPayloadBytes = statsConn.TransmittedPayloadBytes;
                    end
                    throughput = transmittedPayloadBytes*8*1e-6/simulationTime;
            end
        end
    end
end