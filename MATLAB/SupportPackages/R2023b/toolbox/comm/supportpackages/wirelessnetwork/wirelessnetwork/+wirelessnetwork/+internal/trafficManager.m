classdef trafficManager < handle
    %trafficManager Create an object to manage the network traffic objects
    %
    %   Note: This is an internal undocumented class and its API and/or
    %   functionality may change in subsequent releases
    %
    %   TRAFFICMGR = trafficManager(SOURCENODEID, SENDPACKETFCN,
    %   NOTIFICATIONFCN) creates an object to manage the network traffic
    %   objects.
    %
    %   TRAFFICMGR = trafficManager(SOURCENODEID, SENDPACKETFCN,
    %   NOTIFICATIONFCN, Name=Value) creates an object to manage the
    %   network traffic objects with the specified property Name set to the
    %   specified Value. You can specify additional name-value arguments in
    %   any order as (Name1=Value1, ..., NameN=ValueN).
    %
    %   SOURCENODEID specifies the source node identifier.
    %
    %   SENDPACKETFCN specifies the function callback that will be used to
    %   forward the generated packets to lower layer.
    %
    %   NOTIFICATIONFCN specifies the function callback that will be used
    %   to send notification to node when a packet is received from lower
    %   layer.
    %
    %   trafficManager properties (configurable through constructor):
    %
    %   DataAbstraction - Flag to pass only the packet length,
    %                     instead of payload. It is a logical scalar. The
    %                     values true and false indicate data abstraction
    %                     is enabled and disabled, respectively
    %   PacketContext   - Structure to hold the technology specific context
    %                     to be added with each packet
    %
    %   trafficManager properties (read-only):
    %
    %   SendPacketFcn   - Function callback to forward the generated packet
    %                     to lower layer
    %   NotificationFcn - Function callback to send packet reception
    %                     notification to node
    %   TrafficSources  - Cell array of network traffic objects
    %
    %   trafficManager methods:
    %
    %   addTrafficSource - Add network traffic object
    %   run              - Run the traffic manager
    %   receivePacket    - Receive the packet and notify the node
    %   statistics       - Return the statistics

    %   Copyright 2022 The MathWorks, Inc.

    properties (SetAccess = private)
        %DataAbstraction Flag to indicate if the payload (data) is
        %abstracted in the generated packet. It overrides the
        %'generatePacket' flag of traffic pattern object
        DataAbstraction = true

        %PacketContext Technology specific context to be added with each
        %packet
        PacketContext = struct()
    end

    properties (SetAccess = private)
        %SendPacketFcn Callback that will be used to send the generated
        %packet to lower layers
        SendPacketFcn = []

        %NotificationFcn Callback that will be used to send packet
        %reception notification to node
        NotificationFcn = []

        %TrafficSources Cell array of network traffic objects
        TrafficSources = cell(1, 0)
    end

    properties (Access = private)
        %TrafficSourcesCount Count of network traffic objects added in the
        %traffic manager
        TrafficSourcesCount = 0

        %TrafficSourceStatistics Statistics captured per traffic source in
        %the traffic manager
        TrafficSourceStatistics = struct()

        %TransmittedPacketsPerSource Number of packets transmitted per
        %traffic source
        TransmittedPacketsPerSource = zeros(1, 0)

        %TransmittedBytesPerSource Number of packets transmitted per
        %traffic source
        TransmittedBytesPerSource = zeros(1, 0)

        %TransmitQueueOverflowPerSource Number of packets dropped due to
        %queue overflow per traffic source
        TransmitQueueOverflowPerSource = zeros(1, 0)

        %StatReceivedPackets Number of packets received in the traffic manager
        StatReceivedPackets = 0

        %StatReceivedBytes Number of bytes received in the traffic manager
        StatReceivedBytes = 0

        %NextInvokeTime Next invoke time (in nanoseconds) of each network
        %traffic object
        NextInvokeTime = zeros(1, 0)

        %PacketIDCounter Packet ID counter for each network traffic object.
        %Incremental packet IDs will be assigned to the packets generated
        %by a traffic source
        PacketIDCounter = zeros(1, 0)

        %CustomSendPacketFcn Custom function handle of lower layer for each
        %network traffic object
        CustomSendPacketFcn = cell(1, 0)

        %CustomSendPacketFcnFlag Flag to indicate the configuration of
        %custom function handle for each network traffic object
        CustomSendPacketFcnFlag = false(1, 0)
    end

    properties (SetAccess = private, Hidden)
        %PacketInfo Array of structures where each element contains the
        %packet information associated with the added traffic object. The
        %packet information structure contains at least these fields.
        %   Packet               - Array of data bytes in integer format,
        %                          in the range [0, 255].
        %   PacketLength         - Length of data in bytes.
        %   PacketGenerationTime - Data generation time stamp (in seconds)
        %                          as a scalar.
        %   PacketID             - Packet identifier. It is an integer
        %                          scalar.
        %   SourceNodeID         - Source node identifier. It is an integer
        %                          scalar.
        PacketInfo
    end

    properties (Access = private, Constant)
        %Stats Statistics captured in the traffic manager
        Stats = struct('TransmittedPackets', 0, ...
            'TransmittedBytes', 0, ...
            'ReceivedPackets', 0, ...
            'ReceivedBytes', 0, ...
            'TrafficSources', struct());
    end

    methods
        % Constructor
        function obj = trafficManager(sourceNodeID, sendPacketFcn, notificationFcn, varargin)

            % Assign the given name-value pairs to the corresponding class
            % properties
            for i = 1:2:numel(varargin)
                obj.(char(varargin{i})) = varargin{i+1};
            end
            obj.SendPacketFcn = sendPacketFcn;
            obj.NotificationFcn = notificationFcn;
            % Define the basic packet info format that works for all
            % technologies (5G, WLAN, and Bluetooth)
            packetFormat = struct('Packet', zeros(0, 1), ...
                'PacketLength', 0, ...
                'PacketGenerationTime', 0, ... % Packet generation time stamp at origin
                'PacketID', 0, ... % Packet identifier assigned at origin
                'SourceNodeID', sourceNodeID); % Source node ID

            % Add the technology specific packet context fields for packet
            % format and traffic source statistics structure
            fields = fieldnames(obj.PacketContext);
            for fieldIdx = 1:length(fields)
                packetFormat.(fields{fieldIdx}) = ...
                    obj.PacketContext.(fields{fieldIdx});
                obj.TrafficSourceStatistics.(fields{fieldIdx}) = ...
                    obj.PacketContext.(fields{fieldIdx});
            end
            obj.PacketInfo = packetFormat;

            % Add the statistics fields for the traffic source
            % statistics structure
            statsContext = {'TransmittedPackets', 'TransmittedBytes', 'TransmitQueueOverflow'};
            for idx = 1:numel(statsContext)
                obj.TrafficSourceStatistics.(statsContext{idx}) = 0;
            end
        end

        function addTrafficSource(obj, trafficObj, packetContext, varargin)
            %addTrafficSource Add a network traffic object to the traffic
            %manager
            %
            %   addTrafficSource(OBJ, TRAFFICOBJ, PACKETCONTEXT) adds a
            %   network traffic object, TRAFFICOBJ, and the associated
            %   packet context, PACKETCONTEXT.
            %
            %   addTrafficSource(OBJ, TRAFFICOBJ, PACKETCONTEXT,
            %   CUSTOMSENDPACKETFCN) adds a network traffic object,
            %   TRAFFICOBJ, and the associated packet context,
            %   PACKETCONTEXT. It also adds CUSTOMSENDPACKETFCN function
            %   handle to send the generated packet from TRAFFICOBJ to
            %   lower layer.
            %
            %   OBJ is an object of type trafficManager.
            %
            %   TRAFFICOBJ is an object of type <a
            %   href="matlab:help('networkTrafficOnOff')">networkTrafficOnOff</a>,
            %   <a
            %   href="matlab:help('networkTrafficFTP')">networkTrafficFTP</a>,
            %   <a
            %   href="matlab:help('networkTrafficVoIP')">networkTrafficVoIP</a>,
            %   or <a href="matlab:help('<a
            %   href="matlab:help('networkTrafficVideoConference')">networkTrafficVideoConference</a>
            %   for generating data traffic.
            %
            %   PACKETCONTEXT is a structure containing the technology
            %   specific fields.
            %
            %   CUSTOMSENDPACKETFCN is a function handle to send the
            %   generated traffic from only TRAFFICOBJ to lower layer .
            %   When the generated traffic from TRAFFICOBJ needs custom
            %   processing, user specifies this kind of custom callback.
            %   When this is not provided, the generated traffic from
            %   TRAFFICOBJ will be sent to lower layer using a common
            %   function handle configured through the constructor.

            % Update the 'GeneratePacket' property of network traffic
            % object such that the packet data will be filled if data
            % abstraction flag is false and it will not be filled if data
            % abstraction flag is true
            trafficObj.GeneratePacket = ~obj.DataAbstraction;

            % Update the number of traffic sources present in the traffic
            % manager
            obj.TrafficSourcesCount = obj.TrafficSourcesCount + 1;
            trafficSourcesCount = obj.TrafficSourcesCount;

            % Add network traffic object
            obj.TrafficSources{trafficSourcesCount} = trafficObj;

            % Add custom send packet function for the specified traffic
            % source
            if nargin == 4 && ~isempty(varargin{1})
                obj.CustomSendPacketFcn{trafficSourcesCount} = varargin{1};
                obj.CustomSendPacketFcnFlag(trafficSourcesCount) = true;
            else
                obj.CustomSendPacketFcn{trafficSourcesCount} = [];
                obj.CustomSendPacketFcnFlag(trafficSourcesCount) = false;
            end

            % Setup the default packet context for the corresponding
            % network traffic object
            obj.PacketInfo(trafficSourcesCount) = obj.PacketInfo(1);
            % Initialize the corresponding statistics properties for the
            % traffic source
            obj.TransmittedPacketsPerSource(trafficSourcesCount) = 0;
            obj.TransmittedBytesPerSource(trafficSourcesCount) = 0;
            obj.TransmitQueueOverflowPerSource(trafficSourcesCount) = 0;
            obj.TrafficSourceStatistics(trafficSourcesCount) = obj.TrafficSourceStatistics(1);

            % Update the packet context and statistics structure according
            % to the specified packet context
            fields = fieldnames(packetContext);
            for fieldIdx = 1:length(fields)
                obj.PacketInfo(trafficSourcesCount).(fields{fieldIdx}) = ...
                    packetContext.(fields{fieldIdx});
                obj.TrafficSourceStatistics(trafficSourcesCount).(fields{fieldIdx}) = ...
                    packetContext.(fields{fieldIdx});
            end

            % Set the next invocation time of network traffic object to 0
            % nanoseconds
            obj.NextInvokeTime(trafficSourcesCount) = 0;
            % Set the packet ID counter for the corresponding network
            % traffic object
            obj.PacketIDCounter(trafficSourcesCount) = 0;
        end

        function nextInvokeTime = run(obj, currentTime)
            %run Run all the network traffic objects that need to generate
            %traffic at the current time, and returns the next invoke time
            %of traffic manager
            %
            %   NEXTINVOKETIME = run(OBJ, CURRENTTIME) runs all the network
            %   traffic objects that need to generate traffic at the
            %   CURRENTTIME, and returns the next invoke time of traffic
            %   manager.
            %
            %   NEXTINVOKETIME indicates the time (in nanoseconds) at which
            %   the run function should be invoked again.
            %
            %   OBJ is an object of type trafficManager.
            %
            %   CURRENTTIME is an integer indicating the current time (in
            %   nanoseconds).

            nextInvokeTime = Inf;
            % Ready to generate the next packet
            for idx = 1:obj.TrafficSourcesCount
                while obj.NextInvokeTime(idx) == currentTime
                    packetInfo = obj.PacketInfo(idx);
                    % Update the packet ID counter
                    obj.PacketIDCounter(idx) = obj.PacketIDCounter(idx) + 1;
                    % Generate packet from the application traffic source
                    [dt, packetLength, packet] = obj.TrafficSources{idx}.generate();
                    % Put data and its associated context in the packet
                    % structure
                    packetInfo.Packet = packet;
                    packetInfo.PacketLength = packetLength;
                    packetInfo.PacketGenerationTime = currentTime*1e-9; % In seconds
                    packetInfo.PacketID = obj.PacketIDCounter(idx);

                    % Update the next invoke time of network traffic object
                    obj.NextInvokeTime(idx) = currentTime + ceil(dt*1e6); % In nanoseconds

                    % Forward the generated traffic to lower layers
                    if obj.CustomSendPacketFcnFlag(idx)
                        isPacketQueued = obj.CustomSendPacketFcn{idx}(packetInfo);
                    else
                        isPacketQueued = obj.SendPacketFcn(packetInfo);
                    end

                    % Update the statistics
                    if isPacketQueued
                        obj.TransmittedPacketsPerSource(idx) = obj.TransmittedPacketsPerSource(idx) + 1;
                        obj.TransmittedBytesPerSource(idx) = obj.TransmittedBytesPerSource(idx) + packetLength;
                    else
                        obj.TransmitQueueOverflowPerSource(idx) = obj.TransmitQueueOverflowPerSource(idx) + 1;
                    end
                end

                % Next invoke time
                if obj.NextInvokeTime(idx) < nextInvokeTime
                    nextInvokeTime = obj.NextInvokeTime(idx);
                end
            end
        end

        function receivePacket(obj, packetInfo)
            %receivePacket Receive the packet from lower layer and update statistics
            %
            %   receivePacket(OBJ, PACKETINFO) receives the packet from
            %   lower layer and updates the corresponding statistics.
            %
            %   OBJ is an object of type trafficManager.
            %
            %   PACKETINFO is a structure with at least these fields.
            %       Packet        - Array of data bytes in integer format,
            %                       in the range [0, 255]. This will be
            %                       empty if the received packet is
            %                       abstracted.
            %       PacketLength  - Length of packet in bytes.

            % Update the statistics
            obj.StatReceivedPackets = obj.StatReceivedPackets + 1;
            obj.StatReceivedBytes = obj.StatReceivedBytes + packetInfo.PacketLength;

            % Notify the node about the packet reception
            obj.NotificationFcn('AppDataReceived', packetInfo);
        end

        function stats = statistics(obj)
            %statistics Return the statistics
            %
            %   STATS = statistics(OBJ) returns the statistics
            %
            %   OBJ is an object of type trafficManager.
            %
            %   STATS is a structure with these fields.
            %       TransmittedPackets  - Total packets transmitted.
            %       TransmittedBytes    - Total bytes transmitted.
            %       ReceivedPackets     - Total packets received.
            %       ReceivedBytes       - Total bytes received.
            %       TrafficSources      - Structure array where each
            %                             element holds the statistics of a
            %                             traffic source in the node. The
            %                             structure contains these fields:
            %                             TransmittedPackets,
            %                             TransmittedBytes,
            %                             TransmitQueueOverflow, and some
            %                             technology specific context.

            stats = obj.Stats;
            stats.TransmittedPackets = sum(obj.TransmittedPacketsPerSource);
            stats.TransmittedBytes = sum(obj.TransmittedBytesPerSource);
            stats.ReceivedPackets = obj.StatReceivedPackets;
            stats.ReceivedBytes = obj.StatReceivedBytes;
            if obj.TrafficSourcesCount == 0
                stats.TrafficSources = [];
                return;
            end
            for idx = 1:obj.TrafficSourcesCount
                obj.TrafficSourceStatistics(idx).TransmittedPackets = obj.TransmittedPacketsPerSource(idx);
                obj.TrafficSourceStatistics(idx).TransmittedBytes = obj.TransmittedBytesPerSource(idx);
                obj.TrafficSourceStatistics(idx).TransmitQueueOverflow = obj.TransmitQueueOverflowPerSource(idx);
            end
            stats.TrafficSources = obj.TrafficSourceStatistics;
        end
    end
end