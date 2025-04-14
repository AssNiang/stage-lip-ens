classdef wlanNode < comm.internal.ConfigBase & wirelessnetwork.internal.wirelessNode
%wlanNode WLAN node
%   NODEOBJ = wlanNode creates a default WLAN node object.
%
%   NODEOBJ = wlanNode(Position=Value) creates one or more similar WLAN
%   node objects. Value of the "Position" property defines the number of
%   nodes created. 'Position' must be an N-by-3 matrix where N(>=1) is the
%   number of nodes, and each row must contain three numeric values
%   representing the [X, Y, Z] position of the node in meters. The output,
%   NODEOBJ, is an array of wlanNode objects containing N nodes.
%
%   You can optionally supply multiple names for the "Name" property
%   corresponding to the number of nodes created. Multiple names must be
%   supplied either as an array of strings or cell array of character
%   vectors. If the name is not set then the default name "NodeX" is given
%   to the node, where 'X' is the ID of the node. Assuming 'N' nodes are
%   created and 'M' names are supplied, then if (M>N) then the trailing
%   (M-N) names are ignored, and if (N>M) then the trailing (N-M) nodes are
%   set to default names.
%
%   NODEOBJ = wlanNode(Name=Value) creates one or more similar WLAN node
%   objects with the specified property Name set to the specified Value.
%   You can specify additional name-value arguments in any order as
%   (Name1=Value1, ..., NameN=ValueN).
%
%   wlanNode properties (configurable through N-V pair as well as public settable):
%
%   Name                    - Name of the node
%   Position                - Position of the node
%
%   wlanNode properties (configurable through N-V pair only):
%
%   MACFrameAbstraction     - Flag indicating MAC frame is abstracted
%   PHYAbstractionMethod    - PHY abstraction method
%   DeviceConfig            - Device configuration
%
%   wlanNode properties (read-only):
%
%   ID                      - Node identifier
%
%   wlanNode methods:
%
%   associateStations       - Associate stations to WLAN node
%   addTrafficSource        - Add data traffic source to WLAN node
%   addMeshPath             - Add mesh path to WLAN node
%   update                  - Update configuration of WLAN node
%   statistics              - Get the statistics of WLAN node
%   addMobility             - Add random waypoint mobility model to WLAN node
%
%   % Example 1:
%   %   Create a wlanNode object with the name "MyNode".
%
%   myNode = wlanNode(Name="MyNode");
%   disp(myNode)
%
%   % Example 2:
%   %   Create an access point (AP) node with packet transmission format 
%   %   set to "VHT" and modulation and coding scheme (MCS) value set to 7.
%
%   deviceCfg = wlanDeviceConfig(Mode="AP", ...
%                                TransmissionFormat="VHT", ...
%                                MCS=7);
%   apNode = wlanNode(DeviceConfig=deviceCfg);
%
%   % Example 3:
%   %   Create three station (STA) nodes operating on 5 GHz band and 
%   %   channel number 44.
%
%   % 3 positions for 3 STA nodes
%   staPositions = [0 0 0; 10 0 0; 20 0 0];
%   % Set band and channel
%   deviceCfg = wlanDeviceConfig(Mode="STA", BandAndChannel=[5 44]);
%   % Create an array of 3 STA node objects
%   staNodes = wlanNode(Position=staPositions, DeviceConfig=deviceCfg);
%
%   % Example 4:
%   %   Create, Configure, and Simulate Wireless Local Area Network with one
%   %   AP and one STA.
% 
%   % Check if the 'Communications Toolbox (TM) Wireless Network Simulation
%   % Library' support package is installed. If the support package is not 
%   % installed, MATLAB(R) returns an error with a link to download and 
%   % install the support package.
%   wirelessnetworkSupportPackageCheck;
% 
%   % Initialize wireless network simulator
%   networksimulator = wirelessNetworkSimulator.init;
% 
%   % Create a WLAN node with AP device configuration
%   apDeviceCfg = wlanDeviceConfig(Mode="AP");
%   apNode = wlanNode(Name="AP",DeviceConfig=apDeviceCfg);
% 
%   % Create a WLAN node with STA device configuration
%   staDeviceCfg = wlanDeviceConfig(Mode="STA");
%   staNode = wlanNode(Name="STA",DeviceConfig=staDeviceCfg);
% 
%   % Associate the STA to the AP and configure downlink full buffer traffic
%   associateStations(apNode,staNode,FullBufferTraffic="DL");
% 
%   % Add nodes to the simulation
%   addNodes(networksimulator,[apNode,staNode]);
% 
%   % Run simulation for 1 second
%   run(networksimulator,1);
% 
%   % Retrieve and display statistics of AP and STA
%   apStats = statistics(apNode);
%   staStats = statistics(staNode);
%   disp(apStats)
%   disp(staStats)
%
%   See also wlanDeviceConfig

%   Copyright 2022-2023 The MathWorks, Inc.

    properties(SetAccess = private)
        %MACFrameAbstraction MAC frame abstraction
        %   Set this property to true to indicate MAC frame is abstracted. After
        %   the object is created this property is read-only. If this property is
        %   set to true, MAC frame bits are not generated and a structure with MAC
        %   frame information is passed in the packet from transmitting node to
        %   receiving node. If this property is set to false, MAC frame bits are
        %   generated and the frame bits are passed in the packet from transmitting
        %   node to receiving node. The default value is true.
        MACFrameAbstraction (1, 1) logical = true;

        %PHYAbstractionMethod PHY abstraction method
        %   Specify the PHY abstraction method as
        %   "tgax-evaluation-methodology", "tgax-mac-calibration", or
        %   "none". After the object is created this property is read-only.
        %   The value "tgax-evaluation-methodology" corresponds to the
        %   abstraction mentioned in the Appendix-1 of IEEE
        %   802.11-14/0571r12 TGax evaluation methodology document and
        %   "tgax-mac-calibration" corresponds to the abstraction mentioned
        %   in the IEEE 802.11-14/0980r16 TGax simulation scenarios
        %   document. The value "none" corresponds to the full physical
        %   layer processing. The default value is
        %   "tgax-evaluation-methodology".
        PHYAbstractionMethod = "tgax-evaluation-methodology";

        %DeviceConfig Device configuration
        %   Specify the device configuration as a scalar object of type
        %   <a href="matlab:help('wlanDeviceConfig')">wlanDeviceConfig</a>, or a vector of objects when you want to configure
        %   multiple devices in the node. After the object is created this
        %   property is read-only. When multiple devices are provided, the <a href="matlab:help('wlanDeviceConfig/Mode')">Mode</a>
        %   property of any object in the vector must not be set to "STA". The
        %   default value is an object of type wlanDeviceConfig with default
        %   parameters.
        DeviceConfig (1, :) wlanDeviceConfig;
    end

    events(Hidden)
        %TransmissionStatus is triggered after decoding the response frames
        % or after waiting for response timeout and determining the transmission
        % status of RTS/MU-RTS and data frames. This event is triggered for each
        % user in the transmission. TransmissionStatus passes the event
        % notification along with this structure as input to the registered
        % callback:
        %   DeviceID           - Scalar representing device identifier.
        %   CurrentTime        - Scalar representing current simulation
        %                        time in seconds.
        %   FrameType          - String representing frame type as one of
        %                        "QoS Data", "RTS", or "MU-RTS".
        %   ReceiverNodeID     - Scalar representing ID of the node to
        %                        which frame is transmitted
        %   MPDUSuccess        - Logical scalar when transmitted frame is
        %                        an MPDU and vector when it is an A-MPDU.
        %                        Each element represents transmission
        %                        status as:
        %                          'true'  - Transmission success
        %                          'false' - Transmission failure
        %   MPDUDiscarded      - Logical scalar when transmitted frame
        %                        is an MPDU and vector when it is an
        %                        A-MPDU. Each element represents whether
        %                        the MPDU is discarded:
        %                          'true'  - MPDU discarded
        %                          'false' - MPDU not discarded
        %                        When FrameType is "RTS" or "MU-RTS",
        %                        MPDUDiscarded flag indicates the status of
        %                        discard of data packets from transmission
        %                        queues.
        %   TimeInQueue        - Scalar when transmitted frame is an
        %                        MPDU and vector when it is an A-MPDU. Each
        %                        element represents time in seconds spent
        %                        by packet in MAC queue. This is applicable
        %                        for MPDUs whose MPDUDiscarded flag is set
        %                        to true.
        %   AccessCategory     - Scalar when transmitted frame is an
        %                        MPDU and vector when it is an A-MPDU. Each
        %                        element represents access category of the
        %                        MPDU, where 0, 1, 2 and 3 represents
        %                        Best-Effort, Background, Video and Voice
        %                        respectively. When FrameType is "RTS" or
        %                        "MU-RTS", it indicates the access category
        %                        of the corresponding "QoS Data".
        %   ResponseRSSI       - Scalar value representing the signal
        %                        strength of the received response in the
        %                        form of an Ack frame, a Block Ack frame,
        %                        or a CTS frame.
        TransmissionStatus;

        %MPDUGenerated is triggered on generation of an MPDU in the MAC
        % layer. This event is triggered only in case of full MAC frame generation.
        % For A-MPDUs, this is triggered when all MPDU(s) in the A-MPDU are
        % generated. MPDUGenerated passes the event notification along with this
        % structure as input to the registered callback:
        %   DeviceID    - Scalar representing device identifier.
        %   CurrentTime - Scalar representing current simulation time in seconds.
        %   MPDU        - Cell array of MPDU(s) where each element is a vector
        %                 containing MPDU bytes in decimal format.
        %   Frequency   - Scalar representing transmitting frequency in Hz.
        MPDUGenerated;

        %MPDUDecoded is triggered on decoding of an MPDU in the MAC layer.
        % For A-MPDUs, this is triggered when all MPDU(s) in the A-MPDU are
        % decoded. MPDUDecoded passes the event notification along with this
        % structure as input to the registered callback:
        %   DeviceID    - Scalar representing device identifier.
        %   CurrentTime - Scalar representing current simulation time in seconds.
        %   MPDU        - Cell array of MPDU(s) where each element is a vector
        %                 containing MPDU bytes in decimal format.
        %   FCSFail     - Flag representing frame check sequence (FCS) failure.
        %                 In case of multiple MPDUs, it is a vector with values for
        %                 each MPDU.
        %   Frequency   - Scalar representing receiving frequency in Hz.
        MPDUDecoded;

        %AppDataReceived is triggered after the decoded packet is received
        % by the application from the MAC layer. AppDataReceived passes the event
        % notification along with this structure as input to the registered
        % callback:
        %   Packet               - Vector of data bytes. When MAC packet is
        %                          abstracted, Data contains empty value.
        %   PacketLength         - Length of the packet in bytes.
        %   PacketID             - Unique identifier for the packet assigned by
        %                          the source node, to identify the packet.
        %   PacketGenerationTime - Timestamp of the packet generation in seconds.
        %   SourceNodeID         - Source transmitter node identifier.
        %   AccessCategory       - Scalar representing access category of
        %                          transmitted frame. This value can be 0, 1, 2, or
        %                          3 representing Best-Effort, Background, Video,
        %                          or Voice respectively. Applicable only when
        %                          'FrameType' is 'QoS Data'.
        %   CurrentTime          - Scalar representing the current simulation
        %                          time in seconds.
        AppDataReceived

        %StateChanged is triggered on any change in the state of the device.
        % StateChanged passes the event notification along with this structure as
        % input to the registered callback:
        %   DeviceID    - Scalar representing device identifier.
        %   CurrentTime - Scalar representing current simulation time in seconds.
        %   State       - State of device specified as "Idle", "Contention",
        %                 "Transmission", or "Reception".
        %   Duration    - Scalar representing state duration.
        StateChanged;
    end

    properties (Hidden)
        %MeshBridge Mesh bridging object
        %   This property is an object of type <a
        %   href="matlab:help('wlan.internal.meshBridge')">wlan.internal.meshBridge</a>. This object
        %   contains methods and properties related to mesh forwarding.
        MeshBridge

        %Application WLAN application layer object
        %   Specify this property as an object of type <a
        %   href="matlab:help('wlan.internal.trafficManager')">wlan.internal.trafficManager</a>.
        %   This object contains methods and properties related to
        %   application layer.
        Application;

        %MAC WLAN MAC layer object
        %   This property is a vector of objects of type <a
        %   href="matlab:help('wlan.internal.edcaMAC')">wlan.internal.edcaMAC</a>.
        %   This object contains methods and properties related to WLAN MAC
        %   layer. This is a scalar when the node supports only a single
        %   device. Otherwise, this property is specified as a vector of
        %   objects.
        MAC;

        %PHYTx WLAN physical layer transmitter object
        %   This property is a vector of abstracted PHY objects <a
        %   href="matlab:help('wlan.internal.sls.phyTxAbstract')">wlan.internal.sls.phyTxAbstract</a>.
        %   This object contains methods and properties related to WLAN PHY
        %   transmitter. This is a scalar when the node supports only a
        %   single device. Otherwise, this property is specified as a
        %   vector of objects.
        PHYTx;

        %PHYRx WLAN physical layer receiver object
        %   This property is a vector of abstracted PHY objects <a
        %   href="matlab:help('wlan.internal.sls.phyRxAbstract')">wlan.internal.sls.phyRxAbstract</a>.
        %   This object contains methods and properties related to WLAN PHY
        %   receiver. This is a scalar when the node supports only a single
        %   device. Otherwise, this property is specified as a vector of
        %   objects.
        PHYRx;

        %PacketLatency Packet latency of each application packet received
        %   This property is a vector of numeric values. Each value
        %   specifies the latency computed for every packet received in
        %   microseconds.
        PacketLatency = 0;

        %PacketLatencyIdx Current index of the packet latency vector
        %   This property is a numeric value. This property specifies current index
        %   of the packet latency vector.
        PacketLatencyIdx = 0;

        %WLANSignal WLAN signal structure
        %   The WLAN signal is a structure of type <a
        %   href="matlab:help('wirelessnetwork.internal.wirelessPacket')">wirelessnetwork.internal.wirelessPacket</a>.
        WLANSignal;

        %AssociatedSTAInfo Information of associated STAs in BSS, if the node is an
        %AP
        %   This property is a cell array of size N x 3, where N is the number of
        %   associated STAs. Each row contains:
        %       - Associated STA ID
        %       - MAC address of associated STA
        %       - Device index on which AP is connected to the STA
        %   This property is applicable only when there is an AP mode device
        %   present in the node. The default is an empty cell array.
        AssociatedSTAInfo = cell(0, 3);

        %IncludeRxVector Flag indicating whether to include Rx vector in
        %MPDUDecoded event notification data
        %   Specify this property as true to include Rx vector in MPDUDecoded event
        %   notification data. The default value is false.
        IncludeRxVector = false;

        %MeshNeighbors Mesh neighbor node IDs
        %   This property is an array of the IDs of mesh nodes that are identified
        %   as neighbors.
        MeshNeighbors;
    end

    properties (Access = protected)
        %IsMeshNode Is mesh capable node
        IsMeshNode;

        %IsAPNode Is an AP node
        IsAPNode;

        %IsPHYAbstracted PHY abstraction is true
        IsPHYAbstracted = true;

        %RxInfo Receiver information
        RxInfo;

        %PacketInfo Structure containing App packet info
        PacketInfo = struct(AccessCategory=0, Packet=[], PacketLength=0, PacketID=0, PacketGenerationTime=0, SourceNodeID=1);

        %PHYIndication Structure containing the indication passed between
        %MAC and PHY
        PHYIndication;

        %EmptyDt Default value for list of next invoke times
        EmptyDt = zeros(1, 0);

        %NumAssociatedSTAs Number of associated STAs if node is an AP
        NumAssociatedSTAs = 0;

        %NumAssociatedSTAsPerDevice Number of associated STAs on each device if
        %node is an AP
        NumAssociatedSTAsPerDevice = 0;

        %NumAssociatedDevices Number of devices on which AP is associated to STAs
        NumAssociatedDevices = 0;

        %FullBufferTrafficEnabled Indicates whether full buffer traffic is enabled
        FullBufferTrafficEnabled = false;

        %FullBufferTrafficDestinationID Destination ID(s) for the full buffer
        %traffic
        FullBufferTrafficDestinationID;

        %FullBufferTrafficDestinationName Destination Name(s) for the full buffer
        %traffic
        FullBufferTrafficDestinationName;

        %PacketIDCounter Packet ID counter for full buffer traffic
        PacketIDCounter;

        %EventDataObj Object used to pass event notification data
        EventDataObj;
    end

    properties(Hidden)
        %CurrentTime Current simulation time
        CurrentTime = 0;

        % Scalar value indicating total packet latency at application layer for all
        % the applications.
        TotalPacketLatency = 0;

        %Frequencies Operating frequencies
        Frequencies;

        %MaxUsers Maximum number of users a node can support in downlink MU
        MaxUsers = 9;

        %FullBufferPacketSize Packet size for full buffer traffic
        FullBufferPacketSize = 1500;

        % Frame formats
        NonHT;
        HTMixed;
        VHT;
        HE_SU;
        HE_EXT_SU;
        HE_MU;
        HE_TB;
        EHT_SU;

        % Data is empty
        PacketTypeEmpty;

        % Data containing IQ samples (Full MAC + Full PHY)
        DataTypeIQData;

        % Data containing MAC PPDU bits (Full MAC + ABS PHY)
        DataTypeMACFrameBits;

        % Data containing MAC configuration structure (ABS MAC + ABS PHY)
        DataTypeMACFrameStruct;

        % Maximum number of STAs that can be associated on an AP device
        AssociationLimit = 2007;
    end

    properties (Hidden, Constant)
        PHYAbstractionMethod_Values = ["tgax-evaluation-methodology", "tgax-mac-calibration", "none"];
    end

    methods
        function obj = wlanNode(varargin)
            % Name-value pair check
            coder.internal.errorIf(mod(nargin,2) == 1, 'wlan:ConfigBase:InvalidPVPairs');

            % Initialize with defaults, in case user doesn't configure
            obj.MAC = wlan.internal.edcaMAC.empty;
            obj.MeshBridge = wlan.internal.meshBridge(obj.MAC);
            obj.ReceiveFrequency = zeros(1, 0);
            obj.Frequencies = zeros(1, 0);
            obj.DeviceConfig = wlanDeviceConfig;

            % Initialize constant properties
            obj.NonHT = wlan.internal.frameFormats.NonHT;
            obj.HTMixed = wlan.internal.frameFormats.HTMixed;
            obj.VHT = wlan.internal.frameFormats.VHT;
            obj.HE_SU = wlan.internal.frameFormats.HE_SU;
            obj.HE_EXT_SU = wlan.internal.frameFormats.HE_EXT_SU;
            obj.HE_MU = wlan.internal.frameFormats.HE_MU;
            obj.HE_TB = wlan.internal.frameFormats.HE_TB;
            obj.EHT_SU = wlan.internal.frameFormats.EHT_SU;
            obj.PacketTypeEmpty = wlan.internal.networkUtils.PacketTypeEmpty;
            obj.DataTypeIQData = wlan.internal.networkUtils.DataTypeIQData;
            obj.DataTypeMACFrameBits = wlan.internal.networkUtils.DataTypeMACFrameBits;
            obj.DataTypeMACFrameStruct = wlan.internal.networkUtils.DataTypeMACFrameStruct;

            numNodes = 1;
            if nargin > 0
                % Identify number of nodes user intends to create based on
                % Position value
                for idx = 1:2:nargin-1
                    % Search the presence of 'Position' N-V pair argument
                    if strcmp(varargin{idx},"Position")
                        validateattributes(varargin{idx+1}, {'numeric'}, {'nonempty', 'ncols', 3, 'finite'}, mfilename, 'Position');
                        positionValue = varargin{idx+1};
                        numNodes = size(varargin{idx+1}, 1);
                    end
                    % Search the presence of 'Name' N-V pair argument
                    if strcmp(varargin{idx},"Name")
                        nameValue = string(varargin{idx+1});
                    end
                end

                obj = repmat(obj, 1, numNodes);
                for idx = 2:numNodes
                    obj(idx) = wlanNode;
                end

                % Set the configuration of nodes as per the N-V pairs
                for idx = 1:2:nargin-1
                    name = varargin{idx};
                    value = varargin{idx+1};
                    switch (name)
                        case 'Position'
                            % Set position for nodes
                            for j = 1:numNodes
                                obj(j).Position = positionValue(j, :);
                            end
                        case 'Name'
                            % Set name for nodes. If name is not supplied
                            % for all nodes, then leave the trailing nodes
                            % with default names
                            nameCount = min(numel(nameValue), numNodes);
                            for j=1:nameCount
                                obj(j).Name = nameValue(j);
                            end
                        otherwise
                            % Make all the nodes identical by setting same
                            % value for all the configurable properties,
                            % except position and name
                            [obj.(char(name))] = deal(value);
                    end
                end
            end

            % Validate multi-device combination
            if (numel(obj(1).DeviceConfig) > 1)
                % Multiple devices are not supported for a STA node
                coder.internal.errorIf(ismember("STA", [obj(1).DeviceConfig(:).Mode]), 'wlan:wlanNode:UnsupportedMultiDeviceCombo');
                % Two devices in the same node cannot operate in the same frequency
                for idx = 1:numel(obj(1).DeviceConfig)-1
                    bandAndChannels = [obj(1).DeviceConfig(idx+1:end).BandAndChannel];
                    coder.internal.errorIf(any((obj(1).DeviceConfig(idx).BandAndChannel(1) == bandAndChannels(1:2:end-1)) & (obj(1).DeviceConfig(idx).BandAndChannel(2) == bandAndChannels(2:2:end))), 'wlan:wlanNode:UnsupportedMultiDeviceFreq');
                end
            end

            for idx = 1:numNodes
                % Application
                notificationFcn = @(eventName, eventData) triggerEvent(obj(idx), eventName, eventData); % Callback for event notification
                sendPacketFcn = @(packet) pushData(obj(idx), packet);                                   % Callback for pushing packets from App into MAC
                appPacket = struct(AccessCategory=0, DestinationNodeID=0, DestinationNodeName=""); % App packet context fields
                obj(idx).Application = wirelessnetwork.internal.trafficManager(obj(idx).ID, sendPacketFcn, ...
                    notificationFcn, PacketContext=appPacket, DataAbstraction=obj(idx).MACFrameAbstraction); %#ok<*AGROW>

                % Create object to pass event notification data
                obj(idx).EventDataObj = wirelessnetwork.internal.nodeEventData;

                % Validate the configuration
                setFrequencies(obj(idx));

                % Mode flags
                obj(idx).IsMeshNode = any([obj(idx).DeviceConfig(:).IsMeshDevice]);
                obj(idx).IsAPNode = any([obj(idx).DeviceConfig(:).IsAPDevice]);

                if strcmpi(obj(idx).PHYAbstractionMethod, 'none')
                    obj(idx).IsPHYAbstracted = false;
                    obj(idx).PHYTx = wlan.internal.sls.phyTx.empty;
                    obj(idx).PHYRx = wlan.internal.sls.phyRx.empty;
                else
                    obj(idx).PHYTx = wlan.internal.sls.phyTxAbstract.empty;
                    obj(idx).PHYRx = wlan.internal.sls.phyRxAbstract.empty;
                end

                % Initialize
                init(obj(idx));
            end
        end

        function set.PHYAbstractionMethod(obj, value)
            value = validateEnumProperties(obj, 'PHYAbstractionMethod', value);
            obj.PHYAbstractionMethod = value;
        end

        function set.IncludeRxVector(obj, value)
            obj.IncludeRxVector = value;
            updateMACParameter(obj, "IncludeRxVector", value);
        end
    end

    methods
        function associateStations(obj, associatedSTAs, varargin)
        %associateStations Associate stations to WLAN node
        %
        %   associateStations(OBJ,ASSOCIATEDSTAS) associates the list of stations
        %   given in ASSOCIATEDSTAS to the AP node represented by the OBJ.
        %
        %   OBJ is an object of type <a
        %   href="matlab:help('wlanNode')">wlanNode</a>. The Mode must be set to "AP"
        %   within the DeviceConfig property of this object. When multiple devices
        %   are configured for this node object, at least one object in the
        %   DeviceConfig property must have Mode set to "AP".
        %
        %   ASSOCIATEDSTAS is a scalar or a vector of objects corresponding to
        %   STA(s) in the BSS. Each object is of type wlanNode. The Mode must be
        %   set to "STA" within the DeviceConfig property of each of these objects.
        %
        %   associateStations(...,Name=Value) specifies additional name-value
        %   arguments described below. When a name-value argument is not specified,
        %   the function uses its default value.
        %
        %   BandAndChannel        - Band and channel to be used for communication
        %                           between the AP and station nodes. Specify the
        %                           value as a row vector containing 2 elements.
        %                           First element represents band and accepted
        %                           values are 2.4, 5 and 6 (GHz). Second element
        %                           represents any valid channel number in the
        %                           specified band. The default value is
        %                           automatically determined by the node by finding
        %                           the common band and channel between the AP and
        %                           stations. The AP node and the station nodes
        %                           must have a common band and channel.
        %
        %   FullBufferTraffic     - Set full buffer traffic between the AP and
        %                           the given list of stations. Following are the
        %                           allowed values for this parameter:
        %                           "off"   - Full buffer traffic is disabled.
        %                           "on"    - Configures two-way full buffer
        %                                     traffic between the given AP and
        %                                     stations.
        %                           "DL"    - Configures full buffer downlink
        %                                     traffic from AP to stations.
        %                           "UL"    - Configures full buffer uplink
        %                                     traffic from stations to the AP.
        %                           When full buffer traffic is enabled, the packet
        %                           size is 1500 and the access category is 0. If
        %                           full buffer traffic is enabled, custom traffic
        %                           source cannot be added for access category 0
        %                           through <a
        %                           href="matlab:help('wlanNode.addTrafficSource')">addTrafficSource</a>. The default value is
        %                           "off".

            narginchk(2, 6);
            validateattributes(obj, {'wlanNode'}, {'scalar'}, mfilename, 'obj');
            coder.internal.errorIf(~obj.IsAPNode, 'wlan:wlanNode:MustBeAP');
            validateattributes(associatedSTAs, {'wlanNode'}, {}, mfilename, '', 2);
            coder.internal.errorIf(any(arrayfun(@(x) x.IsAPNode || x.IsMeshNode, associatedSTAs, UniformOutput=true)), 'wlan:wlanNode:NonSTAInSTAList');

            numSTA = numel(associatedSTAs);
            numDevices = numel(obj.DeviceConfig);
            associationNVParams = validateAssociationParams(obj, varargin);
            setFullBufferTraffic(obj, associationNVParams.FullBufferTraffic, associatedSTAs);

            if isempty(associationNVParams.BandAndChannel)
                apDeviceIdx = zeros(1, numSTA);
                for staIdx = 1:numSTA
                    staNode = associatedSTAs(staIdx);
                    assert(isscalar(staNode.ReceiveFrequency))
                    % Find the common device for each STA
                    deviceIdx = find(obj.ReceiveFrequency == staNode.ReceiveFrequency, 1);
                    coder.internal.errorIf(isempty(deviceIdx), 'wlan:wlanNode:BSSConfigureChannelNotFound2', obj.Name, staNode.Name);
                    coder.internal.errorIf(obj.MAC(deviceIdx).IsMeshDevice, 'wlan:wlanNode:BSSConfigureMeshConflict2', obj.Name, num2str(obj.DeviceConfig(deviceIdx).BandAndChannel(1)), obj.DeviceConfig(deviceIdx).BandAndChannel(2), staNode.Name);
                    apDeviceIdx(staIdx) = deviceIdx;
                end
            else
                % Name-value pair check
                bandAndChannel = associationNVParams.BandAndChannel;
                % Validate the frequency
                frequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));
                deviceIdx = find(obj.ReceiveFrequency == frequency, 1);
                % Given frequency not found in AP configuration
                coder.internal.errorIf(isempty(deviceIdx), 'wlan:wlanNode:BSSConfigureChannelNotFound1', obj.Name, num2str(bandAndChannel(1)), bandAndChannel(2));
                coder.internal.errorIf(obj.MAC(deviceIdx).IsMeshDevice, 'wlan:wlanNode:BSSConfigureMeshConflict1', obj.Name, num2str(bandAndChannel(1)), bandAndChannel(2));
                apDeviceIdx = repmat(deviceIdx, 1, numSTA);
            end

            associatedSTAIDs = zeros(numSTA, numDevices);
            associatedSTAAddresses = repmat('0', numSTA, 12, numDevices);

            % Configure information of AP at associated STA and vice-versa
            for staIdx = 1:numSTA
                staNode = associatedSTAs(staIdx);
                % Check if STA is already associated
                existingAssociation = any((staNode.ID == [obj.AssociatedSTAInfo{:, 1}]) & strcmp(staNode.MAC.MACAddress, obj.AssociatedSTAInfo(:, 2))' & (apDeviceIdx(staIdx) == [obj.AssociatedSTAInfo{:, 3}]));
                coder.internal.errorIf(existingAssociation, 'wlan:wlanNode:ExistingAssociation', staNode.Name, obj.Name);

                % Check if association limit exceeded at AP
                coder.internal.errorIf(obj.NumAssociatedSTAsPerDevice(apDeviceIdx(staIdx)) + 1 > obj.AssociationLimit, 'wlan:wlanNode:AssociationLimitExceeded', staNode.Name, obj.Name, obj.AssociationLimit);

                % Set BSSID property at AP MAC
                obj.MAC(apDeviceIdx(staIdx)).BSSID = obj.MAC(apDeviceIdx(staIdx)).MACAddress;

                % If the specified frequency is not found in STA configuration
                coder.internal.errorIf((staNode.ReceiveFrequency ~= obj.ReceiveFrequency(apDeviceIdx(staIdx))), 'wlan:wlanNode:BSSConfigureChannelNotFound2', obj.Name, staNode.Name);

                % Store associated STA ID and assigned AID at AP MAC
                obj.NumAssociatedSTAsPerDevice(apDeviceIdx(staIdx)) = obj.NumAssociatedSTAsPerDevice(apDeviceIdx(staIdx)) + 1;
                obj.MAC(apDeviceIdx(staIdx)).AssociatedSTAs = [obj.MAC(apDeviceIdx(staIdx)).AssociatedSTAs; staNode.ID];
                obj.MAC(apDeviceIdx(staIdx)).AssociatedAIDs = [obj.MAC(apDeviceIdx(staIdx)).AssociatedAIDs; ...
                    obj.NumAssociatedSTAsPerDevice(apDeviceIdx(staIdx))];

                % Add connection info to the station node (BSSID and Basic
                % rates)
                bssid = obj.MAC(apDeviceIdx(staIdx)).MACAddress;
                basicRates = obj.MAC(apDeviceIdx(staIdx)).BasicRates;
                bssColor = obj.MAC(apDeviceIdx(staIdx)).BSSColor;
                aid = obj.NumAssociatedSTAsPerDevice(apDeviceIdx(staIdx));
                addConnection(staNode.MAC, bssid, basicRates, bssColor, aid);

                % Store the associated STA ID, STA MAC address and device to be used for STA
                obj.NumAssociatedSTAs = obj.NumAssociatedSTAs + 1;
                [obj.AssociatedSTAInfo{obj.NumAssociatedSTAs, :}] = ...
                    deal(staNode.ID, staNode.MAC.MACAddress, apDeviceIdx(staIdx));

                associatedSTAIDs(staIdx, apDeviceIdx(staIdx)) = staNode.ID;
                associatedSTAAddresses(staIdx, :, apDeviceIdx(staIdx)) = staNode.MAC.MACAddress;

                % If UL OFDMA is enabled at AP, assume that all the stations in BSS would
                % support trigger based transmissions. Indicate the stations that AP is
                % configured to trigger UL OFDMA transmissions.
                if obj.MAC(apDeviceIdx(staIdx)).ULOFDMAEnabled
                    staNode.MAC.ULOFDMAEnabledAtAP = true;
                end
            end

            % Configure association information at mesh bridge of AP to handle
            % forwarding from AP
            meshBridgeObj = obj.MeshBridge;
            for idx = 1:numDevices
                if obj.DeviceConfig(idx).IsAPDevice
                    obj.NumAssociatedDevices = obj.NumAssociatedDevices + 1;
                    [meshBridgeObj.AssociationInfo{obj.NumAssociatedDevices, :}] = ...
                        deal(idx, associatedSTAIDs(:, idx), associatedSTAAddresses(:, :, idx));
                end
            end
        end

        function addTrafficSource(obj, trafficSource, varargin)
        %addTrafficSource Add data traffic source to WLAN node
        %
        %   addTrafficSource(OBJ,TRAFFICSOURCE) adds a data source object,
        %   TRAFFICSOURCE, to the node, OBJ, that generates broadcast traffic.
        %
        %   TRAFFICSOURCE is an object of type <a
        %   href="matlab:help('networkTrafficOnOff')">networkTrafficOnOff</a>,
        %   <a href="matlab:help('networkTrafficFTP')">networkTrafficFTP</a>, <a
        %   href="matlab:help('networkTrafficVideoConference')">networkTrafficVideoConference</a> or <a href="matlab:help('networkTrafficVoIP')">networkTrafficVoIP</a>.
        %   "GeneratePacket" property of TRAFFICSOURCE object is not applicable
        %   and is overridden according to the "MACFrameAbstraction" value of the 
        %   node, OBJ.
        %
        %   OBJ is an object of type <a
        %   href="matlab:help('wlanNode')">wlanNode</a>.
        %
        %   addTrafficSource(...,Name=Value) specifies additional name-value
        %   arguments described below. When a name-value argument is not specified,
        %   the function uses its default value.
        %
        %   DestinationNode       - Specify the destination node of the traffic
        %                           as an object of type <a
        %                           href="matlab:help('wlanNode')">wlanNode</a>. If you do
        %                           not specify this argument, the source
        %                           node broadcasts its traffic.
        %
        %   AccessCategory        - Access category of the generated traffic,
        %                           specified as an integer in the range [0, 3].
        %                           The four possible values respectively
        %                           correspond to the Best Effort, Background,
        %                           Video, and Voice access categories.
        %                           The default value is 0.

            validateattributes(obj, {'wlanNode'}, {'scalar'}, mfilename, 'obj');
            % Validate the traffic parameters
            upperLayerDataInfo = validateTrafficParams(obj, trafficSource, varargin);

            % Do not allow custom traffic if full buffer traffic is enabled
            coder.internal.errorIf(obj.FullBufferTrafficEnabled && (upperLayerDataInfo.AccessCategory == 0), 'wlan:wlanNode:FullBufferEnabled', obj.Name);

            % Add the traffic source to the application traffic manager
            for idx = 1:numel(upperLayerDataInfo)
                addTrafficSource(obj.Application, trafficSource, upperLayerDataInfo(idx));
            end
        end

        function addMeshPath(obj, destinationNode, varargin)
        %addMeshPath Add mesh path to WLAN node
        %
        %   addMeshPath(OBJ,DESTINATIONNODE) specifies that the destination node,
        %   DESTINATIONNODE, is an immediate mesh receiver for the source node,
        %   OBJ.
        %
        %   OBJ is an object of type <a href="matlab:help('wlanNode')">wlanNode</a>.
        %
        %   DESTINATIONNODE is an object of type <a href="matlab:help('wlanNode')">wlanNode</a>.
        %
        %   addMeshPath(OBJ,DESTINATIONNODE,MESHPATHNODE) specifies the mesh node,
        %   MESHPATHNODE, to which the source node, OBJ, sends the packets in an
        %   attempt to communicate with the destination node, DESTINATIONNODE.
        %
        %   MESHPATHNODE is an object of type <a href="matlab:help('wlanNode')">wlanNode</a>, specifying one of these
        %   roles:
        %       * Next hop node - If the destination node is a mesh node, then this
        %         input specifies the next hop node. The next hop node refers to an
        %         immediate mesh receiver to which the source node forwards the
        %         packets.
        %
        %       * Proxy mesh gate - If the destination node is a non-mesh node,
        %         then this input specifies the proxy mesh gate. The proxy mesh
        %         gate refers to any mesh node that can forward packets to a
        %         non-mesh node.
        %
        %   addMeshPath(...,Name=Value) specifies additional name-value arguments
        %   described below. When a name-value argument is not specified, the
        %   function uses its default value.
        %
        %   SourceBandAndChannel       - Band and channel on which the source
        %                                node must transmit packets to the next hop
        %                                node. Specify this input as a vector of
        %                                two values. The first value must be 2.4,
        %                                5, or 6 and the second value must be a
        %                                valid channel number in the band.
        %
        %                                The input uses this default configuration:
        %                                * If the mesh path node is the next hop
        %                                  node, the function selects the common
        %                                  band and channel between the source node
        %                                  and next hop node. If there are multiple
        %                                  common band-channel pairs, you must
        %                                  specify a value for this input.
        %                                * If the mesh path node is the proxy mesh
        %                                  gate, the function selects the band and
        %                                  channel belonging to a mesh device. If
        %                                  there are multiple mesh devices, you
        %                                  must specify a value for this input.
        %
        %   MeshPathBandAndChannel     - Band and channel on which the mesh path
        %                                node must receive the packets. Specify
        %                                this input as a vector of two values. The
        %                                first value must be 2.4, 5, or 6 and the
        %                                second value must be a valid channel
        %                                number in the band.
        %
        %                                The input uses this default configuration:
        %                                * If the mesh path node is the next hop
        %                                  node, the function selects the common
        %                                  band and channel between the source node
        %                                  and next hop node.
        %                                * If the mesh path node is the proxy mesh
        %                                  gate, the function selects the band and
        %                                  channel belonging to a mesh device. If
        %                                  there are multiple mesh devices, you
        %                                  must specify a value for this input.
        %
        %   DestinationBandAndChannel  - Band and channel on which the destination
        %                                node should receive the packets. Specify
        %                                this input as a vector of two values. The
        %                                first value must be 2.4, 5, or 6 and the
        %                                second value must be a valid channel
        %                                number in the band.
        %
        %                                The input uses this default configuration:
        %                                * If the destination node is a mesh node,
        %                                  the function selects the band and
        %                                  channel belonging to a mesh device. If
        %                                  there are multiple mesh devices, you
        %                                  must specify a value for this input.
        %                                * If the destination node is a non-mesh
        %                                  node and only one device is present, the
        %                                  function selects the band and channel of
        %                                  that device in the node. If there are
        %                                  multiple devices, you must specify a
        %                                  value for this input.

            narginchk(2, 9);

            validateattributes(obj, {'wlanNode'}, {'scalar'}, mfilename, 'obj');
            % Validate the input parameters
            [meshPathNode, params] = validateMeshPathParams(obj, nargin, destinationNode, varargin{:});
            [sourceDeviceID, meshPathDevID, destDevID] = findDeviceIDs(obj, destinationNode, meshPathNode, params);

            destinationID = destinationNode.ID;
            destinationAddress = wlan.internal.nodeID2MACAddress([destinationNode.ID destDevID]);
            destinationAddress = reshape(dec2hex(destinationAddress, 2)', 1, []);
            meshPathAddress = wlan.internal.nodeID2MACAddress([meshPathNode.ID meshPathDevID]);
            meshPathAddress = reshape(dec2hex(meshPathAddress, 2)', 1, []);

            if destinationNode.IsMeshNode % Forwarding information
                % Add next hop (meshPathAddress) information
                addPath(obj.MeshBridge, destinationID, destinationAddress, meshPathAddress, sourceDeviceID);
                setBiDirectionalPaths(obj, destinationNode, meshPathNode, sourceDeviceID, destDevID, meshPathDevID);
            else % Proxy information
                % Add proxy mesh (meshPathAddress) information
                addProxyInfo(obj.MeshBridge, destinationID, destinationAddress, meshPathAddress);
            end
        end

        function update(obj, deviceID, varargin)
        %update Update configuration of WLAN Node
        %
        %   update(OBJ,Name=Value) updates the configuration of the node. You can
        %   update the following properties through this method.
        %
        %   CWMin     - Minimum range of contention window for the four
        %               access categories (ACs), specified as a vector of
        %               four integers in the range [1, 1023]. The four 
        %               entries are the minimum ranges for the Best Effort,
        %               Background, Video, and Voice ACs, respectively.
        %
        %   CWMax     - Maximum range of contention window for the four ACs,
        %               specified as a vector of four integers in the range
        %               [1, 1023]. The four entries are the maximum ranges
        %               for the Best Effort, Background, Video, and Voice
        %               ACs, respectively.
        %
        %   AIFS      - Arbitrary interframe space values for the four ACs,
        %               specified as a vector of four integers in the range
        %               [2, 15]. The entries of the vector represent the AIFS
        %               values, in slots, for the Best Effort, Background,
        %               Video, and Voice ACs, respectively.
        %
        %   update(OBJ, DEVICEID, Name=Value) updates the configuration for the
        %   specified device ID, DEVICEID. DEVICEID specifies the array index in
        %   the DeviceConfig property of the OBJ. If DEVICEID is not specified, the
        %   default value is 1.

            validateattributes(obj, {'wlanNode'}, {'scalar'}, mfilename, 'obj');
            coder.internal.errorIf((nargin == 1), 'wlan:wlanNode:NoUpdate');

            if mod(nargin, 2) == 1
                nvPairs = [{deviceID}, varargin];
                deviceID = 1;
            else
                nvPairs = varargin;
                validateattributes(deviceID, {'numeric'}, {'scalar', 'integer', 'positive', '<=', numel(obj.DeviceConfig)}, '', 'device ID');
            end

            for idx = 1:2:numel(nvPairs)
                switch nvPairs{idx}
                    case {'CWMin', 'CWMax', 'AIFS'}
                        obj.DeviceConfig(deviceID).(nvPairs{idx}) = nvPairs{idx+1};
                        obj.MAC(deviceID).(nvPairs{idx}) = nvPairs{idx+1};
                    otherwise
                        coder.internal.errorIf(true, 'wlan:wlanNode:InvalidUpdateParameter');
                end
            end
        end

        function stats = statistics(obj, varargin)
        %statistics Returns statistics of WLAN Node
        %
        %   [STATISTICS] = statistics(OBJ) returns the statistics as a structure
        %   for the given node object, OBJ. If the input OBJ is an array, the
        %   output is an array of structures corresponding to statistics of each
        %   node.
        %
        %   STATISTICS is a structure containing the statistics of the node. If 
        %   the input OBJ is an array of nodes, STATISTICS is an array of 
        %   structures corresponding to the array of nodes. For information on 
        %   fields in the structure, see <a href="matlab:helpview(fullfile(docroot,'toolbox','wlan','helptargets.map'),'wlanNodeStatistics')">WLAN Node Statistics</a>.

            stats = repmat(struct, 1, numel(obj));
            option = [];
            if ~isempty(varargin)
                option = validatestring(varargin{1}, "all", mfilename, '');
            end
            % Calculate the number of unique frequencies
            for idx = 1:numel(obj)
                node = obj(idx);

                % Initialize
                mac = node.MAC;
                phyTx = node.PHYTx;
                phyRx = node.PHYRx;
                meshBridge = node.MeshBridge;

                % App statistics in App sub-structure
                stats(idx).Name = node.Name;
                stats(idx).ID = node.ID;
                stats(idx).App = getAppStats(node, option);

                for deviceID = 1:obj(idx).NumDevices
                    % MAC statistics in MAC sub-structure
                    stats(idx).MAC(deviceID) = statistics(mac(deviceID), option);

                    % PHY statistics in PHY sub-structure. Merge the PHYTx and
                    % PHYRx statistics structures into one structure
                    phyTxStats = statistics(phyTx(deviceID));
                    phyRxStats = statistics(phyRx(deviceID));
                    stats(idx).PHY(deviceID) = cell2struct([struct2cell(phyTxStats); struct2cell(phyRxStats)], [fieldnames(phyTxStats); fieldnames(phyRxStats)]);

                    % Mesh statistics in Mesh sub-structure
                    stats(idx).Mesh(deviceID) = statistics(meshBridge, deviceID);
                end
            end
        end
    end

    methods(Hidden)
        function nextInvokeTime = run(obj, currentTime)
            %run Runs the WLAN node
            %
            %   NEXTINVOKETIME = run(OBJ, CURRENTTIME) runs the
            %   functionality of WLAN node and returns the time at which
            %   this node should be run again.
            %
            %   NEXTINVOKETIME is the time in seconds at which the run
            %   function must be invoked again. The simulator may invoke
            %   this function earlier than this time if required, for
            %   example when a packet is added to the receive buffer of
            %   this node.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('wlanNode')">wlanNode</a>.
            %
            %   CURRENTTIME is the current simulation time in seconds.

            % Initialize
            nextInvokeTimes = obj.EmptyDt;
            nextIdx = 1;

            % Update simulation time
            timeInMicroseconds = round(currentTime*1e6, 3);

            obj.CurrentTime = timeInMicroseconds;

            if obj.FullBufferTrafficEnabled
                fillTrafficBuffer(obj);
                nextAppInvokeTime = Inf;
            else
                % Run the application layer
                nextAppInvokeTime = run(obj.Application, round(currentTime*1e9));
            end

            for deviceIdx = 1:obj.NumDevices
                % Rx buffer has data to be processed
                if obj.ReceiveBufferIdx(deviceIdx) ~= 0
                    rxBuffer = obj.ReceiveBuffer{deviceIdx, 1};
                    for idx = 1:obj.ReceiveBufferIdx(deviceIdx)
                        % Process the received data
                        deviceInvokeTime = runLayers(obj, deviceIdx, currentTime, rxBuffer{idx});
                        nextInvokeTimes(nextIdx:nextIdx+1) = deviceInvokeTime;
                        % Increment the nextInvokeTimes vector index by 2 to
                        % fill MAC and PHY invoke times in next iteration.
                        nextIdx = nextIdx+2;
                    end
                    obj.ReceiveBufferIdx(deviceIdx) = 0;
                else % Rx buffer has no data to process
                    % Update the time to the MAC and PHY layers
                    deviceInvokeTime = runLayers(obj, deviceIdx, currentTime, []);
                    nextInvokeTimes(nextIdx:nextIdx+1) = deviceInvokeTime;
                    nextIdx = nextIdx+2;
                end
            end

            % Get the next invoke time
            nextInvokeTime = min([nextInvokeTimes(1:nextIdx-1) nextAppInvokeTime]);
            nextInvokeTime = round(nextInvokeTime/1e9, 9);
        end

        function init(obj)
            %init Initialize and setup the node stack

            % Extract node ID
            nodeIdx = obj.ID;

            % MAC frame abstraction is allowed only when PHY is abstracted
            coder.internal.errorIf((strcmp(obj.PHYAbstractionMethod, 'none') && obj.MACFrameAbstraction), 'wlan:wlanNode:InvalidMACandPHYCombination');

            % Full MAC frame generation and decoding is not supported for
            % multiuser transmission
            coder.internal.errorIf(~obj.MACFrameAbstraction && any(strcmp([obj.DeviceConfig(:).TransmissionFormat], "HE-MU-OFDMA")), 'wlan:wlanNode:UnsupportedMACFrameAbstractionForOFDMA');

            % When TransmissionFormat is set to "EHT-SU", only abstracted
            % MAC frames are supported
            coder.internal.errorIf(~obj.MACFrameAbstraction && any(strcmp([obj.DeviceConfig(:).TransmissionFormat], "EHT-SU")), 'wlan:wlanNode:UnsupportedMACFrameAbstractionEHT');

            % Number of devices in the node
            numDevices = numel(obj.DeviceConfig);
            % Configure and add the devices with MAC and PHY layers
            for devIdx = 1:numDevices
                % Configure the rate control algorithm at MAC for DL transmissions from the device
                rateControlAlgorithm = obj.DeviceConfig(devIdx).RateControl;
                if isa(rateControlAlgorithm, 'wlan.internal.rateControlFixed')
                    rateControlAlgorithm.MCS = obj.DeviceConfig(devIdx).MCS;
                    rateControlAlgorithm.NumSpaceTimeStreams = obj.DeviceConfig(devIdx).NumSpaceTimeStreams;
                end
                % Fill the base class 'wlan.internal.rateControl' properties
                rateControlAlgorithm.TransmissionFormat = obj.DeviceConfig(devIdx).TransmissionFormat;
                rateControlAlgorithm.BasicRates = obj.DeviceConfig(devIdx).BasicRates;

                % Configure the rate control algorithm at MAC for UL transmissions triggered by the device
                ulRateControlAlgorithm = wlan.internal.rateControlFixed(MCS=obj.DeviceConfig(devIdx).MCS, ...
                    NumSpaceTimeStreams=obj.DeviceConfig(devIdx).NumSpaceTimeStreams);

                % Configure the power control algorithm at MAC
                powerControl = obj.DeviceConfig(devIdx).PowerControl;
                assert(strcmp(powerControl, 'FixedPower'));
                powerControlAlgorithm = wlan.internal.powerControlFixed(Power=obj.DeviceConfig(devIdx).TransmitPower);

                % Initialize the scheduler, if it is not provided as input
                macScheduler = wlan.internal.schedulerRoundRobin;

                % Determine whether UL OFDMA is enabled
                ulOFDMAEnabled = false;
                % EnableUplinkOFDMA flag is applicable only for an AP when the
                % TransmissionFormat is either HE-SU or HE-MU-OFDMA
                if strcmp(obj.DeviceConfig(devIdx).Mode, "AP") && any(strcmp(obj.DeviceConfig(devIdx).TransmissionFormat, ["HE-SU", "HE-MU-OFDMA"])) && ...
                        obj.DeviceConfig(devIdx).EnableUplinkOFDMA
                    ulOFDMAEnabled = true;
                    % Full MAC frame generation and decoding is not supported for triggered
                    % multiuser transmissions
                    coder.internal.errorIf(~obj.MACFrameAbstraction && obj.DeviceConfig(devIdx).EnableUplinkOFDMA, ...
                        'wlan:wlanNode:UnsupportedMACFrameAbstractionForOFDMA');
                end

                % MAC layer
                mac = wlan.internal.edcaMAC(NodeID=nodeIdx, ...
                        DeviceID=devIdx, ...
                        ChannelBandwidth=obj.DeviceConfig(devIdx).ChannelBandwidth/1e6, ...
                        TransmissionFormat=wlan.internal.networkUtils.getFrameFormatConstant(obj.DeviceConfig(devIdx).TransmissionFormat), ...
                        MPDUAggregation=HasMPDUAggregation(obj, devIdx), ...
                        DisableAck=obj.DeviceConfig(devIdx).DisableAck, ...
                        CWMin=obj.DeviceConfig(devIdx).CWMin, ...
                        CWMax=obj.DeviceConfig(devIdx).CWMax, ...
                        AIFS=obj.DeviceConfig(devIdx).AIFS, ...
                        NumTransmitAntennas=obj.DeviceConfig(devIdx).NumTransmitAntennas, ...
                        DisableRTS=obj.DeviceConfig(devIdx).DisableRTS, ...
                        RTSThreshold=obj.DeviceConfig(devIdx).RTSThreshold,...
                        ShortRetryLimit=obj.DeviceConfig(devIdx).ShortRetryLimit, ...
                        Use6MbpsForControlFrames=obj.DeviceConfig(devIdx).Use6MbpsForControlFrames, ...
                        BasicRates=obj.DeviceConfig(devIdx).BasicRates, ...
                        RateControl=rateControlAlgorithm, ...
                        PowerControl=powerControlAlgorithm, ...
                        FrameAbstraction=obj.MACFrameAbstraction, ...
                        IsMeshDevice=obj.DeviceConfig(devIdx).IsMeshDevice, ...
                        IsAPDevice=obj.DeviceConfig(devIdx).IsAPDevice, ...
                        Scheduler=macScheduler, ...
                        MaxMUStations=obj.DeviceConfig(devIdx).MaxMUStations, ...
                        DLOFDMAFrameSequence=obj.DeviceConfig(devIdx).DLOFDMAFrameSequence, ...
                        ULOFDMAEnabled=ulOFDMAEnabled, ...
                        ULRateControl=ulRateControlAlgorithm, ...
                        MaxSubframes=obj.DeviceConfig(devIdx).MPDUAggregationLimit, ...
                        MaxQueueLength=obj.DeviceConfig(devIdx).TransmitQueueSize, ...
                        SIFSTime=16e3, ...
                        IncludeRxVector=obj.IncludeRxVector, ...
                        BSSColor=obj.DeviceConfig(devIdx).BSSColor, ...
                        OBSSPDThreshold =obj.DeviceConfig(devIdx).OBSSPDThreshold);

                if strcmp(obj.PHYAbstractionMethod,'none')
                    phyTx = wlan.internal.sls.phyTx(NodeID=nodeIdx, ...
                        NodePosition=obj.Position, ...
                        IsNodeTypeAP=obj.DeviceConfig(devIdx).IsAPDevice, ...
                        TxGain=obj.DeviceConfig(devIdx).TransmitGain, ...
                        DeviceID=devIdx);
                    phyRx = wlan.internal.sls.phyRx(NodeID=nodeIdx, ...
                        EDThreshold=obj.DeviceConfig(devIdx).EDThreshold, ...
                        RxGain=obj.DeviceConfig(devIdx).ReceiveGain, ...
                        NoiseFigure=obj.DeviceConfig(devIdx).NoiseFigure, ...
                        ChannelBandwidth=obj.DeviceConfig(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx);
                else
                    % Physical layer transmitter
                    phyTx = wlan.internal.sls.phyTxAbstract(NodeID=nodeIdx, ...
                        NodePosition=obj.Position, ...
                        IsNodeTypeAP=obj.DeviceConfig(devIdx).IsAPDevice, ...
                        TxGain=obj.DeviceConfig(devIdx).TransmitGain, ...
                        MaxSubframes=obj.DeviceConfig(devIdx).MPDUAggregationLimit, ...
                        ChannelBandwidth=obj.DeviceConfig(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx);

                    % Physical layer receiver
                    phyRx = wlan.internal.sls.phyRxAbstract(NodeID=nodeIdx, ...
                        EDThreshold=obj.DeviceConfig(devIdx).EDThreshold, ...
                        RxGain=obj.DeviceConfig(devIdx).ReceiveGain, ...
                        AbstractionType=obj.PHYAbstractionMethod, ...
                        NoiseFigure = obj.DeviceConfig(devIdx).NoiseFigure, ...
                        SubcarrierSubsampling = 4, ...
                        MaxSubframes=obj.DeviceConfig(devIdx).MPDUAggregationLimit, ...
                        ChannelBandwidth=obj.DeviceConfig(devIdx).ChannelBandwidth/1e6, ...
                        DeviceID=devIdx, ...
                        BSSColor=obj.DeviceConfig(devIdx).BSSColor, ...
                        OBSSPDThreshold=obj.DeviceConfig(devIdx).OBSSPDThreshold);
                end

                % Callback at MAC for handling MSDUs after MAC processing
                mac.HandleReceivePacketFcn = @(deviceID, packetToApp, isMeshDevice, macAddress) ...
                    handleReceivedPacket(obj, deviceID, packetToApp, isMeshDevice, macAddress);
                % Callback at MAC for handling PHY mode change
                mac.SetPHYModeFcn = @(phyMode)phyRx.setPHYMode(phyMode);
                % Callback at MAC for handling PHY CCA reset request
                mac.ResetPHYCCAFcn = @phyRx.resetPHYCCA;
                % Callback for event notification
                eventNotificationFcn = @(eventName, eventData) triggerEvent(obj, eventName, eventData);
                mac.EventNotificationFcn = eventNotificationFcn;
                phyTx.EventNotificationFcn = eventNotificationFcn;
                phyRx.EventNotificationFcn = eventNotificationFcn;
                % Callback at MAC to send Trigger request to phy Rx
                if obj.DeviceConfig(devIdx).EnableUplinkOFDMA || strcmp(obj.DeviceConfig(devIdx).TransmissionFormat, "HE-MU-OFDMA")
                    mac.SendTrigRequestFcn = @(expiryTime)phyRx.handleTrigRequest(expiryTime);
                end

                % Add the device
                addDevice(obj, devIdx, obj.DeviceConfig(devIdx).BandAndChannel, mac, phyTx, phyRx);
            end

            % Mesh bridge
            obj.MeshBridge = wlan.internal.meshBridge(obj.MAC, ...
                                MeshTTL=obj.DeviceConfig(1).MeshTTL);

            maxSubframes = obj.MAC(1).MaxSubframes;

            % Fields present per user in Tx/Rx vector
            perUserFields = struct(MCS=0, ...
                                Length=0, ...
                                NumSpaceTimeStreams=0, ...
                                StationID=0, ...
                                TxPower=0);

            % Structure representing Tx/Rx vector

            % RUAllocation: Represents allocation index in HE_MU Tx vector and
            % represents array of RU size and index in HE_MU Rx vector and
            % HE_TB Tx vector
            %
            % LSIGLength: Represents length of the LSIG field when
            % 'TriggerMethod' is 'TriggerFrame' and UL data symbols when
            % 'TriggerMethod' is 'TRS'
            %
            % PerUserInfo: This will be dynamic array of structures based on
            % number of users
            vector = struct(PPDUFormat=wlan.internal.frameFormats.NonHT, ... % Fields common in Tx and Rx vectors
                        ChannelBandwidth=20, ...
                        AggregatedMPDU=false, ...
                        BSSColor=0, ...
                        RUAllocation=0, ...
                        NumTransmitChains=0, ...
                        TriggerMethod='TriggerFrame' , ... % Fields in Tx vector
                        LSIGLength=0, ...
                        NumHELTFSymbols=0, ...
                        LowerCenter26ToneRU=false, ...
                        UpperCenter26ToneRU=false, ...
                        RSSI=0, ... % Fields in Rx vector
                        PerUserInfo=perUserFields); % Fields present per user

            metadata = struct(Vector=vector, ...
                        PayloadInfo=repmat(struct(OverheadDuration = 0, Duration = 0, NumOfBits = 0), [1,maxSubframes]), ...
                        PreambleDuration=0, ...
                        HeaderDuration=0, ...
                        PayloadDuration=0, ...
                        NumSubframes=zeros(obj.MaxUsers, 1), ...
                        SubframeLengths=zeros(obj.MaxUsers, maxSubframes), ...
                        SubframeIndices=zeros(obj.MaxUsers, maxSubframes), ...
                        NumHeaderAndPreambleBits=0, ...
                        MACDataType=obj.DataTypeMACFrameBits, ...
                        MPDUSequenceNumber=zeros(maxSubframes, obj.MaxUsers), ...
                        PacketGenerationTime=zeros(maxSubframes, obj.MaxUsers), ...
                        PacketID=zeros(maxSubframes, obj.MaxUsers));

            wlanSignal = wirelessnetwork.internal.wirelessPacket;
            wlanSignal.Metadata = metadata;
            obj.PHYIndication = struct(MessageType=0, Vector=vector);

            for idx = 1:numDevices
                % Generate a separate address for each device in the node
                macAddressDec = wlan.internal.nodeID2MACAddress([obj.ID idx]);
                macAddressHex = reshape(dec2hex(macAddressDec, 2)', 1, []);
                obj.MAC(idx).MACAddress = macAddressHex;
            end

            % Initialize the transmitting and receiving buffers for each
            % device within the node by mapping with its operating frequency
            obj.ReceiveBuffer = cell(numDevices, 1);
            obj.ReceiveBufferIdx = zeros(1, numDevices);
            obj.Frequencies = obj.ReceiveFrequency;

            % Initialize receiver information
            obj.RxInfo = struct(ID=0, Position=[0 0 0], Velocity=[0 0 0]);

            % Initialize association information
            obj.NumAssociatedSTAsPerDevice = zeros(numDevices, 1);
        end

        function [flag, rxInfo] = isPacketRelevant(obj, packet)
        %isPacketRelevant Return flag to indicate if the input packet
        %is relevant for this node
        %
        %   [FLAG, RXINFO] = isPacketRelevant(OBJ, PACKET) checks
        %   whether the packet, PACKET, is relevant for this node,
        %   before applying channel model. If the output FLAG is true,
        %   the packet is of interest and the RXINFO specifies the
        %   receiver information needed for applying channel on the
        %   incoming packet, PACKET.
        %
        %   FLAG is a logical scalar value indicating whether to invoke
        %   channel or not.
        %
        %   The object function returns the output, RXINFO, and is
        %   valid only when the FLAG value is 1 (true). The structure
        %   of this output contains these fields:
        %
        %   ID       - Node identifier of the receiver
        %   Position - Current receiver position in Cartesian coordinates,
        %              specified as a real-valued vector of the form [x y
        %              z]. Units are in meters.
        %   Velocity - Current receiver velocity (v) in the x-, y-, and
        %              z-directions, specified as a real-valued vector of
        %              the form [vx vy vz]. Units are in meters per second.
        %
        %   OBJ is an object of type <a
        %   href="matlab:help('wlanNode')">wlanNode</a>.
        %
        %   PACKET is the packet received from the channel. This is a
        %   structure of type <a
        %   href="matlab:help('wlanNode/WLANSignal')">WLANSignal</a>.

            % Initialize
            flag = false;
            rxInfo = obj.RxInfo;

            % If it is self-packet (transmitted by this node) do not get this
            % packet
            if packet.TransmitterID == obj.ID
                return;
            end

            % This packet can be received by this node if it is sent on any
            % one of the node's operating frequencies
            for deviceID = 1:obj.NumDevices
                if isFrequencyOverlapping(obj, packet, deviceID)
                    flag = true;
                    break;
                end
            end
            if flag
                rxInfo.ID = obj.ID;
                rxInfo.Position = obj.Position;
                rxInfo.Velocity = obj.Velocity;
                rxInfo.NumReceiveAntennas = obj.MAC(deviceID).NumTransmitAntennas;
            end
        end

        function pushReceivedData(obj, packet)
            %pushReceivedData Push the received packet to node
            %
            % OBJ is an object of type wlanNode, nrGNB, nrUE,
            % bluetoothLENode, bluetoothNode, or any other node type
            % derived from this class.
            %
            % PACKET is the received packet. It is a structure of the
            % format <a href="matlab:help('wirelessnetwork.internal.wirelessPacket')">wirelessPacket</a>

            if isempty(packet)
                return;
            end

            % Copy the received packet to the device (network interface)
            % buffers of the node
            for deviceID = 1:obj.NumDevices
                if isFrequencyOverlapping(obj, packet, deviceID)
                    rxBufIdx = obj.ReceiveBufferIdx(deviceID);
                    obj.ReceiveBuffer{deviceID, 1}{rxBufIdx+1} = packet;
                    obj.ReceiveBufferIdx(deviceID) = obj.ReceiveBufferIdx(deviceID) + 1;
                end
            end
        end

        function sendPacketToMAC(obj, packet)
        %sendPacketToMAC Send a packet received from user to MAC queue
            pushData(obj, packet);
        end

        function updateMACParameter(obj, parameter, value)
            for idx = 1:numel(obj.MAC)
                obj.MAC(idx).(parameter) = value;
            end
        end
    end

    methods (Access = protected)
        function addDevice(obj, deviceID, bandAndChannel, mac, phyTx, phyRx)
            %addDevice Add a device to the node
            %
            %   addDevice(OBJ, DEVICEID, BANDANDCHANNEL, MAC, PHYTX,
            %   PHYRX) adds a device to the node with the given MAC and
            %   PHY objects at the specified band and channel,
            %   BANDANDCHANNEL.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('wlanNode')">wlanNode</a>
            %
            %   DEVICEID is the identifier of the device.
            %
            %   BANDANDCHANNEL is the operating band and channel number of
            %   the device. It is a cell array of vector in the format
            %   {[x, y]} where x = band, y = channel number. The value of x
            %   can be 2.4, 5, or 6. The value of y can be any valid
            %   channel number.
            %
            %   MAC is an object of type <a
            %   href="matlab:help('wlan.internal.edcaMAC')">edcaMAC</a>.
            %   This object contains methods and properties related to WLAN
            %   MAC layer.
            %
            %   PHYTX is an abstracted PHY object of type <a
            %   href="matlab:help('wlan.internal.sls.phyTxAbstract')">phyTxAbstract</a>.
            %   This object contains methods and properties related to WLAN
            %   PHY transmitter.
            %
            %   PHYRX is an abstracted PHY object of type <a
            %   href="matlab:help('wlan.internal.sls.phyRxAbstract')">phyRxAbstract</a>.
            %   This object contains methods and properties related to WLAN
            %   PHY receiver.

            % Validate the frequency
            frequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));

            % Update the device information
            mac.OperatingFrequency = frequency;
            phyTx.OperatingFrequency = frequency;
            phyRx.OperatingFrequency = frequency;
            obj.MAC(deviceID) = mac;
            obj.PHYTx(deviceID) = phyTx;
            obj.PHYRx(deviceID) = phyRx;
            obj.ReceiveBandwidth(deviceID) = obj.DeviceConfig(deviceID).ChannelBandwidth*1e6;
        end

        function isPacketQueued = pushData(obj, appPacket)
            %pushData Push application data into all the instances of the
            %MAC layer operating on different frequencies

            % Get node IDs of associated STAs if present
            associatedSTAIDs = [obj.AssociatedSTAInfo{:, 1}];

            % Update the application packet with mesh addresses
            if obj.IsMeshNode
                if obj.IsAPNode && any(appPacket.DestinationNodeID == associatedSTAIDs) % Destination is one of the associated STAs
                    % Form MAC queue packet from application packet
                    [macQueuePacket, sourceDeviceIdx] = addDestinationInfo(obj, appPacket);
                else
                    % Add mesh information to the application packet
                    [macQueuePacket, sourceDeviceIdx] = addMeshInfo(obj.MeshBridge, appPacket);
                end
            else
                [macQueuePacket, sourceDeviceIdx] = addDestinationInfo(obj, appPacket);
            end

            % Check if the destination is group address and push the data
            % into all the devices if the destination is a group address
            % (multicasting/broadcasting).
            groupAddress = isGroupAddress(obj, macQueuePacket.DestinationAddress);
            if groupAddress
                sourceDeviceIdx = 1:obj.NumDevices;
            end

            % Add packet timestamp
            bufferAvailable = false(1, numel(sourceDeviceIdx));
            ac = appPacket.AccessCategory;
            macQueuePacket.PacketGenerationTime = round(obj.CurrentTime/1e6, 9);
            for idx = 1:numel(sourceDeviceIdx)
                if sourceDeviceIdx(idx) > 0 % Further path exists
                    % Get the source MAC device to push the application packet
                    mac = obj.MAC(sourceDeviceIdx(idx));
                    bufferAvailable(idx) = ~isQueueFull(mac, macQueuePacket.ReceiverID, ac);

                    if bufferAvailable(idx)
                        % Packet origin source address
                        macQueuePacket.SourceAddress = mac.MACAddress;
                        if mac.IsMeshDevice % Packet to be sent on mesh
                            % Mesh sequence number
                            macQueuePacket.MeshSequenceNumber = getMeshSequenceNumber(obj.MeshBridge, mac.MACAddress);
                            % Packet generated at mesh STA. Assign mesh SA same as
                            % SA.
                            macQueuePacket.MeshSourceAddress = macQueuePacket.SourceAddress;
                        end
                        macQueuePacket.MACEntryTime = round(obj.CurrentTime/1e6, 9);
                        % Push the application data into the MAC queue
                        pushUpperLayerPacket(mac, macQueuePacket);
                    end
                end
            end
            % Return packet queuing status
            isPacketQueued = any(bufferAvailable);
        end

        function nextInvokeTime = runLayers(obj, deviceIdx, currentTime, rxPacket)
            %runLayers Runs the layers of the node with the received signal
            %and returns the next invoke time in microseconds

            % MAC object
            mac = obj.MAC(deviceIdx);
            % PHY Tx object
            phyTx = obj.PHYTx(deviceIdx);
            % PHY Rx object
            phyRx = obj.PHYRx(deviceIdx);

            % Invoke the PHY receiver module
            [nextPHYInvokeTime, indicationToMAC, frameToMAC] = run(phyRx, round(currentTime*1e9), rxPacket);

            % Invoke the MAC layer
            [nextMACInvokeTime, macReqToPHY, frameToPHY] = run(mac, round(currentTime*1e9), indicationToMAC, frameToMAC);

            % Invoke the PHY transmitter module (pass MAC requests to PHY)
            run(phyTx, round(currentTime*1e9), macReqToPHY, frameToPHY);

            % Update the transmitted waveform along with the metadata
            if phyTx.TransmitWaveform.Type ~= obj.PacketTypeEmpty
                obj.TransmitterBuffer = [obj.TransmitterBuffer phyTx.TransmitWaveform];
                phyTx.TransmitWaveform.Type = obj.PacketTypeEmpty;
            end

            % Return the next invoke times of PHY and MAC modules
            nextInvokeTime = [nextPHYInvokeTime nextMACInvokeTime];
        end

        function triggerEvent(obj, eventName, eventData)
            %triggerEvent Trigger the event to notify all the listeners

            if event.hasListener(obj, eventName)
                eventData.CurrentTime = round(obj.CurrentTime/1e6, 9);
                obj.EventDataObj.Data = eventData;
                notify(obj, eventName, obj.EventDataObj);
            end
        end

        function receiveAppData(obj, macPacket)
            %receiveAppData Calculate the received application packet latency

            obj.PacketLatencyIdx = obj.PacketLatencyIdx + 1;
            obj.PacketLatency(obj.PacketLatencyIdx) = round(round(obj.CurrentTime/1e6, 9) -  macPacket.PacketGenerationTime, 9); % In seconds
            % Update the packet latency
            obj.TotalPacketLatency = obj.TotalPacketLatency + obj.PacketLatency(obj.PacketLatencyIdx);
            packetInfo = obj.PacketInfo;
            packetInfo.AccessCategory = macPacket.AC;
            if ~isempty(macPacket.Data)
                packetInfo.Packet = macPacket.Data;
            end
            packetInfo.PacketLength = macPacket.MSDULength;
            packetInfo.PacketID = macPacket.PacketID;
            packetInfo.PacketGenerationTime = macPacket.PacketGenerationTime;
            packetInfo.SourceNodeID = wlan.internal.macAddress2NodeID(macPacket.SourceAddress);
            obj.Application.receivePacket(packetInfo);
        end

        function handleReceivedPacket(obj, deviceID, packetToApp, isMeshDevice, macAddress)
            %handleReceivedPacket Handle each decoded MSDU received from MAC

            % Check whether the immediate destination is group address or not
            isGroupAddr = isGroupAddress(obj, packetToApp.ReceiverAddress);
            isFourAddressFrame = packetToApp.FourAddressFrame;

            % Broadcast
            if isGroupAddr
                if isMeshDevice % Packet received on mesh
                    sourceID = wlan.internal.macAddress2NodeID(packetToApp.MeshSourceAddress);
                    % Check whether the packet is already received or not
                    isDuplicate = isDuplicateFrame(obj.MeshBridge, packetToApp.MeshSourceAddress, ...
                        packetToApp.MeshSequenceNumber, deviceID);

                    if ~isDuplicate && ~(sourceID(1) == obj.ID)
                        receiveAppData(obj, packetToApp);
                        % Forward the packet in all the MAC devices if
                        % remaining mesh forward hops are greater than 1
                        forwardAppData(obj.MeshBridge, packetToApp, deviceID, isGroupAddr);
                    end
                else
                    sourceID = wlan.internal.macAddress2NodeID(packetToApp.SourceAddress);
                    if sourceID(1) ~= obj.ID
                        % Send to app if this node is not the source of packet
                        receiveAppData(obj, packetToApp);
                    end
                end
            else
                if isFourAddressFrame && isMeshDevice % Four address frame received on mesh
                    % Check whether the packet is already received or not
                    isDuplicate = isDuplicateFrame(obj.MeshBridge, packetToApp.MeshSourceAddress, ...
                        packetToApp.MeshSequenceNumber, deviceID);
                end

                % Non-duplicate mesh packet (MSDU)
                if isFourAddressFrame && isMeshDevice && ~isDuplicate
                    % Packet reached mesh destination address (DA)
                    if strcmp(macAddress, packetToApp.MeshDestinationAddress) && ...
                            strcmp(packetToApp.DestinationAddress, packetToApp.MeshDestinationAddress)
                        % Give packet to application layer if the mesh DA is final DA
                        receiveAppData(obj, packetToApp);
                    else
                        forwardAppData(obj.MeshBridge, packetToApp, deviceID, isGroupAddr);
                    end
                elseif ~isMeshDevice % Non-mesh packet
                    if strcmp(macAddress, packetToApp.DestinationAddress)
                        % Give packet to application layer if it is destined to this node
                        receiveAppData(obj, packetToApp);
                    elseif obj.IsAPNode
                        forwardAppData(obj.MeshBridge, packetToApp, deviceID, isGroupAddr);
                    end
                end
            end
        end

        function flag = isGroupAddress(~, destinationAddress)
            %isGroupAddress Returns true when the destination address is broadcast
            %or group address of the current node

            bits = bitget(hex2dec(destinationAddress(1:2)), 1:8);
            flag = bits(1);
        end

        function flag = HasMPDUAggregation(obj, deviceIdx)
            %HasMPDUAggregation Returns true if MPDU aggregation is enabled

            flag = true;
            if strcmp(obj.DeviceConfig(deviceIdx).TransmissionFormat, 'Non-HT') || ...
                    (strcmp(obj.DeviceConfig(deviceIdx).TransmissionFormat, 'HT-Mixed') && ~obj.DeviceConfig(deviceIdx).AggregateHTMPDU)
                flag = false;
            end
        end

        function [macPacket, deviceIndex] = addDestinationInfo(obj, appPacket)
            %addDestinationInfo Generates MAC queue packet by adding final and
            %immediate destination details

            macPacket = obj.MeshBridge.MACQueuePacket;

            % Update common fields
            macPacket.MSDULength = appPacket.PacketLength;
            macPacket.AC = appPacket.AccessCategory;
            macPacket.Data = appPacket.Packet;
            macPacket.PacketID = appPacket.PacketID;

            if obj.IsAPNode
                [deviceIndex, destAddress] = destIDToDeviceMap(obj, appPacket.DestinationNodeID);

                % Fill immediate and final destination IDs and addresses
                macPacket.ReceiverID = appPacket.DestinationNodeID;
                macPacket.DestinationID = appPacket.DestinationNodeID;
                if deviceIndex ~= -1
                    macPacket.ReceiverAddress = destAddress;
                    macPacket.DestinationAddress = destAddress;
                end
            else
                [deviceIndex, destAddress] = destIDToDeviceMap(obj, appPacket.DestinationNodeID);
                % Consider receiver is same as final destination. Change if
                % necessary in case of STA in BSS
                receiverAddress = destAddress;
                receiverID = appPacket.DestinationNodeID;

                if obj.MAC(1).IsAssociatedSTA
                    % Send data to the AP as the STA is associated to an AP
                    receiverAddress = obj.MAC.BSSID;
                    receiverID = wlan.internal.macAddress2NodeID(receiverAddress);
                    receiverID = receiverID(1);
                    if receiverID == appPacket.DestinationNodeID
                        % If receiver is the final destination, assign final
                        % destination address as receiver address
                        destAddress = receiverAddress;
                    elseif appPacket.DestinationNodeID == 65535
                        % In case of broadcast, assign receiver address same as
                        % broadcast address
                        receiverAddress = destAddress;
                        receiverID = appPacket.DestinationNodeID;
                    end
                end

                % Fill immediate and final destination IDs and addresses
                macPacket.DestinationID = appPacket.DestinationNodeID;
                macPacket.DestinationAddress = destAddress;
                macPacket.ReceiverID = receiverID;
                macPacket.ReceiverAddress = receiverAddress;
            end
        end

        function [deviceIndex, destAddress] = destIDToDeviceMap(obj, destID)
            %destIDToDeviceMap Return the device on which packet has to be
            %sent to specified destination and the destination MAC address

            % Initialize
            destAddress = [];

            if obj.IsAPNode
                destIDIdx = (destID == [obj.AssociatedSTAInfo{:, 1}]);
                if any(destIDIdx) % Destination is one of associated STAs
                    destAddress = obj.AssociatedSTAInfo{destIDIdx, 2};
                    deviceIndex = obj.AssociatedSTAInfo{destIDIdx, 3};
                elseif destID == 65535
                    deviceIndex = 1:obj.NumDevices;
                    destAddress = 'FFFFFFFFFFFF'; % Broadcast address
                else
                    % Return device index as -1 if STA is not found in
                    % associated STAs list
                    deviceIndex = -1;
                end
            else
                destinationAddressDec = wlan.internal.nodeID2MACAddress([destID, 1]);
                destAddress = reshape(dec2hex(destinationAddressDec, 2)', 1, []);

                % Consider only first device in case of:
                % 1. STA in BSS - first device is the only device
                % 2. Node (neither AP nor STA) - only the first device is
                % assumed to be active and used for transmission
                deviceIndex = 1;
            end
        end

        function setFullBufferTraffic(obj, fullBufferTrafficType, associatedStations)
        %setFullBufferTraffic Set full buffer traffic

            switch fullBufferTrafficType
                case "on"
                    numStations = numel(associatedStations);
                    obj.PacketIDCounter = [obj.PacketIDCounter, zeros(1, numStations)];

                    % Downlink traffic - from AP to station nodes
                    obj.FullBufferTrafficEnabled = true;
                    for idx = 1:numStations
                        obj.FullBufferTrafficDestinationID = [obj.FullBufferTrafficDestinationID associatedStations(idx).ID]; % destinations are station nodes
                        obj.FullBufferTrafficDestinationName = [obj.FullBufferTrafficDestinationName string(associatedStations(idx).Name)]; % destinations are station nodes
                    end

                    % UL traffic - from station nodes to AP
                    for idx = 1:numStations
                        associatedStations(idx).PacketIDCounter = 0;
                        associatedStations(idx).FullBufferTrafficEnabled = true;
                        associatedStations(idx).FullBufferTrafficDestinationID = obj.ID; % destination is AP node
                        associatedStations(idx).FullBufferTrafficDestinationName = obj.Name; % destination is AP node
                    end

                case "DL"
                    numStations = numel(associatedStations);
                    obj.PacketIDCounter = [obj.PacketIDCounter, zeros(1, numStations)];

                    % Downlink traffic - from AP to station nodes
                    obj.FullBufferTrafficEnabled = true;
                    for idx = 1:numStations
                        obj.FullBufferTrafficDestinationID = [obj.FullBufferTrafficDestinationID associatedStations(idx).ID]; % destinations are station nodes
                        obj.FullBufferTrafficDestinationName = [obj.FullBufferTrafficDestinationName string(associatedStations(idx).Name)]; % destinations are station nodes
                    end

                case "UL"
                    numStations = numel(associatedStations);
                    % UL traffic - from station nodes to AP
                    for idx = 1:numStations
                        associatedStations(idx).PacketIDCounter = 0;
                        associatedStations(idx).FullBufferTrafficEnabled = true;
                        associatedStations(idx).FullBufferTrafficDestinationID = obj.ID; % destination is AP node
                        associatedStations(idx).FullBufferTrafficDestinationName = obj.Name; % destination is AP node
                    end
            end
        end

        function appPacket = appPacketForFullBuffer(obj)
        %appPacketForFullBuffer Return app packet(s) for full buffer traffic

            appPacket = struct(Packet = [], PacketID = 0, PacketLength = 0, PacketGenerationTime = 0, AccessCategory = 0, ...
                SourceNodeID = 1, DestinationNodeID = 2, DestinationNodeName = '');
            numDestinations = numel(obj.FullBufferTrafficDestinationID);
            appPacket = repmat(appPacket, 1, numDestinations);

            for idx = 1:numDestinations
                appPacket(idx).PacketLength = obj.FullBufferPacketSize;
                appPacket(idx).Packet = ones(1, appPacket(idx).PacketLength);
                appPacket(idx).PacketGenerationTime = round(obj.CurrentTime*1e-6, 9); % Packet generation time stamp at origin
                appPacket(idx).AccessCategory = 0;
                appPacket(idx).SourceNodeID = obj.ID;
                appPacket(idx).DestinationNodeID = obj.FullBufferTrafficDestinationID(idx);
                appPacket(idx).DestinationNodeName = obj.FullBufferTrafficDestinationName(idx);
            end
        end

        function fillTrafficBuffer(obj)
        %fillTrafficBuffer Fill the buffer with packets
            appPacket = appPacketForFullBuffer(obj);

            % Fill the buffer
            for idx = 1:numel(appPacket)
                deviceIndex = destIDToDeviceMap(obj, appPacket(idx).DestinationNodeID);
                mac = obj.MAC(deviceIndex);
                while ~isQueueFull(mac, appPacket(idx).DestinationNodeID, appPacket(idx).AccessCategory)
                    obj.PacketIDCounter(idx) = obj.PacketIDCounter(idx) + 1;
                    appPacket(idx).PacketID = obj.PacketIDCounter(idx);
                    pushData(obj, appPacket(idx));
                end
            end
        end

        function appStats = getAppStats(obj, varargin)
        %getAppStats Get application statistics

            appStats = statistics(obj.Application);

            perTrafficSourceStats = appStats.TrafficSources;
            appStats = rmfield(appStats, 'TrafficSources');
            % Fill Destinations sub-structure if "all" is provided in input
            if ~isempty(varargin) && strcmp(varargin{1}, "all") && ~isempty(perTrafficSourceStats)
                destinationIDs = unique([perTrafficSourceStats(:).DestinationNodeID]);
                destinationNames = unique([perTrafficSourceStats(:).DestinationNodeName]);
                numDestinations = numel(destinationIDs);
                appStats.Destinations = repmat(struct('NodeID', [], ...
                    'NodeName', [], 'TransmittedPackets', 0, ...
                    'TransmittedBytes', 0), 1, numDestinations);

                for dstIdx = 1:numDestinations
                    appStats.Destinations(dstIdx).NodeID = destinationIDs(dstIdx);
                    appStats.Destinations(dstIdx).NodeName = destinationNames(dstIdx);

                    % Loop over each traffic source and add the stats number to
                    % the corresponding destination
                    for idx=1:length(perTrafficSourceStats)
                        trafficSourceStat = perTrafficSourceStats(idx);
                        appDestinationID = trafficSourceStat.DestinationNodeID;
                        if appDestinationID == destinationIDs(dstIdx)
                            appStats.Destinations(dstIdx).TransmittedPackets = ...
                                appStats.Destinations(dstIdx).TransmittedPackets + trafficSourceStat.TransmittedPackets;
                            appStats.Destinations(dstIdx).TransmittedBytes = ...
                                appStats.Destinations(dstIdx).TransmittedBytes + trafficSourceStat.TransmittedBytes;
                        end
                    end
                end
            end

            if obj.FullBufferTrafficEnabled
                appStats.TransmittedPackets = sum(obj.PacketIDCounter);
                appStats.TransmittedBytes = appStats.TransmittedPackets*obj.FullBufferPacketSize;
                numDestinations = numel(obj.FullBufferTrafficDestinationID);
                % Fill Destinations sub-structure if "all" is provided in input
                if ~isempty(varargin) && strcmp(varargin{1}, "all")
                    appStats.Destinations = repmat(struct('DestinationNodeID', [], ...
                        'DestinationNodeName', [], 'TransmittedPackets', 0, ...
                        'TransmittedBytes', 0), 1, numDestinations);
                    for idx = 1:numDestinations
                        appStats.Destinations(idx).DestinationNodeID = obj.FullBufferTrafficDestinationID(idx);
                        appStats.Destinations(idx).DestinationNodeName = obj.FullBufferTrafficDestinationName(idx);
                        appStats.Destinations(idx).TransmittedPackets = obj.PacketIDCounter(idx);
                        appStats.Destinations(idx).TransmittedBytes = obj.PacketIDCounter(idx)*obj.FullBufferPacketSize;
                    end
                end
            end
        end

        function setFrequencies(obj)
        %setFrequencies Sets the frequencies from the given band and
        %channel values for each device config

            obj.NumDevices = numel(obj.DeviceConfig);
            for idx = 1:obj.NumDevices
                % Validate deviceConfig
                obj.DeviceConfig(idx) = validateConfig(obj.DeviceConfig(idx));
                % Calculate frequencies from band and channel
                obj.ReceiveFrequency(idx) = wlanChannelFrequency(obj.DeviceConfig(idx).BandAndChannel(2), obj.DeviceConfig(idx).BandAndChannel(1));
            end
        end

        function [sourceDeviceID, meshPathDevID, destDevID] = findDeviceIDs(obj, destinationNode, meshPathNode, params)
        %findDeviceIDs Returns the device IDs for source, destination, and
        %mesh path nodes.

            % Extract the user given parameter values (if any).
            sourceBandAndChannel = params.SourceBandAndChannel;
            destBandAndChannel = params.DestinationBandAndChannel;
            meshPathBandAndChannel = params.MeshPathBandAndChannel;

            if destinationNode.IsMeshNode % Forwarding path information
            % * Source node & mesh path node (next hop) are neighbors
            % * Destination node may or may not be neighbor of next hop node

                if isempty(sourceBandAndChannel) && isempty(meshPathBandAndChannel)
                    % Source & mesh path node band and channels are not given by the user

                    % Find common mesh operating frequency between the source and mesh path nodes
                    sourceMeshDevIDs = find(arrayfun(@(x) x.IsMeshDevice, obj.MAC));
                    meshPathMeshDevIDs = find(arrayfun(@(x) x.IsMeshDevice, meshPathNode.MAC));
                    commonFreq = intersect(obj.Frequencies(sourceMeshDevIDs), meshPathNode.Frequencies(meshPathMeshDevIDs));
                    coder.internal.errorIf(numel(commonFreq) > 1, 'wlan:wlanNode:MultipleCommonMeshBandAndChannel');
                    coder.internal.errorIf(isempty(commonFreq), 'wlan:wlanNode:NoCommonMeshBandAndChannel');
                    % Find device IDs
                    sourceDeviceID = find(commonFreq == obj.Frequencies);
                    meshPathDevID = find(commonFreq == meshPathNode.Frequencies);

                elseif isempty(meshPathBandAndChannel)
                    % Mesh path node band and channel is not given by the user, source band and
                    % channel is given by the user

                    % Find source device ID
                    sourceDeviceID = wlanNode.getDeviceID(obj, sourceBandAndChannel);
                    coder.internal.errorIf(isempty(sourceDeviceID), 'wlan:wlanNode:InvalidSourceBandAndChannel', 'source');
                    % Next hop node should receive packets on the source band and channel.
                    meshPathDevID = wlanNode.getDeviceID(meshPathNode, sourceBandAndChannel);
                    coder.internal.errorIf(isempty(meshPathDevID), 'wlan:wlanNode:InvalidSourceBandAndChannel', 'mesh path');

                elseif isempty(sourceBandAndChannel)
                    % Source band and channel is not given by the user, mesh path node band and
                    % channel is given by the user

                    % Find mesh path device ID
                    meshPathDevID = wlanNode.getDeviceID(meshPathNode, meshPathBandAndChannel);
                    coder.internal.errorIf(isempty(meshPathDevID), 'wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path');
                    % Source node should send packets on the mesh path band and channel.
                    sourceDeviceID = wlanNode.getDeviceID(obj, meshPathBandAndChannel);
                    coder.internal.errorIf(isempty(sourceDeviceID), 'wlan:wlanNode:InvalidMeshPathBandAndChannel', 'source');

                else % Source & mesh path nodes band and channel are given by the user
                    % Find source device ID
                    sourceDeviceID = wlanNode.getDeviceID(obj, sourceBandAndChannel);
                    coder.internal.errorIf(isempty(sourceDeviceID), 'wlan:wlanNode:InvalidSourceBandAndChannel', 'source');
                    % Find mesh path device ID
                    meshPathDevID = wlanNode.getDeviceID(obj, meshPathBandAndChannel);
                    coder.internal.errorIf(isempty(meshPathDevID), 'wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path');

                    % Check if source and mesh path (next hop) band and channels are the same
                    coder.internal.errorIf(~all(sourceBandAndChannel == meshPathBandAndChannel), 'wlan:wlanNode:BandAndChannelMismatch');
                end

                if isempty(destBandAndChannel)
                    % Destination band and channel is not given by the user
                    destDevID = 1;
                    if numel(destinationNode.DeviceConfig) > 1
                        if meshPathNode.ID == destinationNode.ID
                            destDevID = meshPathDevID;
                        else
                            % Find mesh device ID in the destination node if there are multiple devices
                            destDevID = find(arrayfun(@(x) x.IsMeshDevice, destinationNode.MAC));
                            if ~isempty(destDevID) && any(destinationNode.ID == meshPathNode.MeshNeighbors)
                                % If mesh and destination are neighbors, find the common mesh frequency
                                meshPathMeshDevIDs = find(arrayfun(@(x) x.IsMeshDevice, meshPathNode.MAC));
                                commonFreq = intersect(destinationNode.Frequencies(destDevID), meshPathNode.Frequencies(meshPathMeshDevIDs));
                                if ~isempty(commonFreq)
                                    [~, ~, destDevID] = intersect(commonFreq, destinationNode.Frequencies);
                                end
                            end
                            coder.internal.errorIf(numel(destDevID) ~= 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'DestinationBandAndChannel', 'destination');
                        end
                    end
                else % Destination band and channel is given by the user
                    % Find destination device ID
                    destDevID = wlanNode.getDeviceID(destinationNode, destBandAndChannel);
                    coder.internal.errorIf(isempty(destDevID), 'wlan:wlanNode:InvalidDestinationBandAndChannel');
                end

            else % Proxy mesh information
                % * Destination node is not a mesh node
                % * Mesh path node is a mesh node
                % * Destination node and mesh path node (proxy mesh node) are neighbors
                % * Source node and mesh path node may or may not be neighbors

                if isempty(sourceBandAndChannel) && isempty(meshPathBandAndChannel)
                    % Source & mesh path node band and channels are not given by the user

                    % Try to find a mesh device ID on the source node
                    sourceDeviceID = find(arrayfun(@(x) x.IsMeshDevice, obj.MAC));
                    coder.internal.errorIf(numel(sourceDeviceID) ~= 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'SourceBandAndChannel', 'source');
                    % Try to find a mesh device ID on the mesh path node
                    meshPathDevID = find(arrayfun(@(x) x.IsMeshDevice, meshPathNode.MAC));
                    coder.internal.errorIf(numel(meshPathDevID) ~= 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'MeshPathBandAndChannel', 'mesh path');

                elseif isempty(meshPathBandAndChannel)
                    % Mesh path node band and channel is not given by the user, source band and
                    % channel is given by the user

                    % Find source device ID
                    sourceDeviceID = wlanNode.getDeviceID(obj, sourceBandAndChannel);
                    coder.internal.errorIf(isempty(sourceDeviceID), 'wlan:wlanNode:InvalidSourceBandAndChannel', 'source');
                    % Try to find a mesh device ID on the mesh path node
                    meshPathDevID = find(arrayfun(@(x) x.IsMeshDevice, meshPathNode.MAC));
                    coder.internal.errorIf(numel(meshPathDevID) ~= 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'MeshPathBandAndChannel', 'mesh path');

                elseif isempty(sourceBandAndChannel)
                    % Source band and channel is not given by the user, mesh path node band and
                    % channel is given by the user

                    % Find mesh path device ID
                    meshPathDevID = wlanNode.getDeviceID(meshPathNode, meshPathBandAndChannel);
                    coder.internal.errorIf(isempty(meshPathDevID), 'wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path');
                    % Try to find a mesh device ID on the source node
                    sourceDeviceID = find(arrayfun(@(x) x.IsMeshDevice, obj.MAC));
                    coder.internal.errorIf(numel(sourceDeviceID) ~= 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'SourceBandAndChannel', 'source');

                else % Source & mesh path nodes band and channel are given by the user
                    % Find source device ID
                    sourceDeviceID = wlanNode.getDeviceID(obj, sourceBandAndChannel);
                    coder.internal.errorIf(isempty(sourceDeviceID), 'wlan:wlanNode:InvalidSourceBandAndChannel', 'source');
                    % Find mesh path device ID
                    meshPathDevID = wlanNode.getDeviceID(obj, meshPathBandAndChannel);
                    coder.internal.errorIf(isempty(meshPathDevID), 'wlan:wlanNode:InvalidMeshPathBandAndChannel', 'mesh path');
                end

                if isempty(destBandAndChannel)
                    % Destination band and channel is not given by the user
                    coder.internal.errorIf(numel(destinationNode.DeviceConfig) > 1, 'wlan:wlanNode:NeedBandAndChannelParameter', 'DestinationBandAndChannel', 'destination');
                    destDevID = 1;
                else % Destination band and channel is given by the user
                    % Find destination device ID
                    destDevID = wlanNode.getDeviceID(destinationNode, destBandAndChannel);
                    coder.internal.errorIf(isempty(destDevID), 'wlan:wlanNode:InvalidDestinationBandAndChannel');
                end
            end
        end

        function setBiDirectionalPaths(obj, destinationNode, meshPathNode, sourceDeviceID, destDevID, meshPathDevID)
        % Auto-find neighbor nodes and set bi-directional paths if a
        % path is not already set

            meshPathAddress = wlan.internal.nodeID2MACAddress([meshPathNode.ID meshPathDevID]);
            meshPathAddress = reshape(dec2hex(meshPathAddress, 2)', 1, []);

            % Add backward path for direct neighbors and one-hop
            % neighbors
            if (destinationNode.ID == meshPathNode.ID)
                % Add neighbor nodes
                if ~any(destinationNode.ID == obj.MeshNeighbors)
                    obj.MeshNeighbors(end+1) = destinationNode.ID;
                end
                if ~any(obj.ID == destinationNode.MeshNeighbors)
                    destinationNode.MeshNeighbors(end+1) = obj.ID;
                end
                % Backward path for neighbor node
                if ~any([destinationNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    addPath(destinationNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, obj.MAC(sourceDeviceID).MACAddress, destDevID);
                end
            else % Non-neighbors

                % The source node and next hop node (mesh path node)
                % are implicitly neighbors

                % Add neighbor nodes
                if ~any(meshPathNode.ID == obj.MeshNeighbors)
                    obj.MeshNeighbors(end+1) = meshPathNode.ID;
                end
                if ~any(obj.ID == meshPathNode.MeshNeighbors)
                    meshPathNode.MeshNeighbors(end+1) = obj.ID;
                end
                % Add path from source node to next hop node
                if ~any([obj.MeshBridge.ForwardTable{:, 1}] == meshPathNode.ID)
                    addPath(obj.MeshBridge, meshPathNode.ID, meshPathAddress, meshPathAddress, sourceDeviceID);
                end
                % Add path from next hop node to source node
                if ~any([meshPathNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    addPath(meshPathNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, obj.MAC(sourceDeviceID).MACAddress, meshPathDevID);
                end

                if ~any([destinationNode.MeshBridge.ForwardTable{:, 1}] == obj.ID)
                    % Check if destination and mesh path nodes are
                    % neighbors. Since mesh path node (i.e. next hop node)
                    % is implicitly a neighbor for the source node,
                    % destination is within 2 hops.
                    twoHopNeighbor = any(destinationNode.ID == meshPathNode.MeshNeighbors);

                    % If destination is a two hop neighbor, add backward
                    % path if there is no entry already
                    if twoHopNeighbor
                        addPath(destinationNode.MeshBridge, obj.ID, obj.MAC(sourceDeviceID).MACAddress, meshPathAddress, destDevID);
                    end
                end
            end
        end

        function out = validateTrafficParams(obj, trafficSource, nvPair)
        %validateNVPairAddTrafficSource validate the NV pairs for
        %addTrafficSource method

            % Validate data source object
            validateattributes(trafficSource, {'networkTrafficOnOff', 'networkTrafficFTP', 'networkTrafficVoIP', 'networkTrafficVideoConference'}, ...
                {'scalar'}, mfilename, 'traffic source');
            % Validate MSDU Size
            if isa(trafficSource, 'networkTrafficOnOff')
                validateattributes(trafficSource.PacketSize, {'numeric'}, {'scalar', 'positive', '<=', 2304}, mfilename, 'PacketSize in the traffic source');
            end

            coder.internal.errorIf(mod(numel(nvPair),2) == 1, 'wlan:ConfigBase:InvalidPVPairs');
            out = struct(DestinationNodeID=65535, DestinationNodeName="", AccessCategory=0);

            % NV pairs
            params = struct(DestinationNode=[], AccessCategory=0);
            for idx = 1:2:numel(nvPair)
                paramName = validatestring(nvPair{idx}, ["DestinationNode" "AccessCategory"], mfilename, 'parameter name');
                switch paramName
                    case 'DestinationNode'
                        paramValue = nvPair{idx+1};
                        validateattributes(paramValue, {'wlanNode'}, {'scalar'}, mfilename, paramName);
                    otherwise % 'AccessCategory'
                        paramValue = nvPair{idx+1};
                        validateattributes(paramValue, {'numeric'}, {'integer', 'scalar', '>=', 0, '<=', 3}, mfilename, paramName);
                end
                params.(paramName) = paramValue;
            end

            out.AccessCategory = params.AccessCategory;
            if ~isempty(params.DestinationNode)
                out = repmat(out, 1, numel(params.DestinationNode));
                for nodeIdx = 1:numel(params.DestinationNode)
                    % Error when source is AP and destination is not an
                    % associated station. Allow when the node has a mesh
                    % device (AP+Mesh node).
                    coder.internal.errorIf((obj.IsAPNode && ~obj.IsMeshNode) && ~any(params.DestinationNode(nodeIdx).ID == [obj.AssociatedSTAInfo{:, 1}]), 'wlan:wlanNode:APDestinationUnassociated');
                    % Error when source is STA and
                    %   * Unassociated
                    %   * Destination is not in the same BSS
                    coder.internal.errorIf(~obj.IsAPNode && ~obj.IsMeshNode && ...
                        (~obj.MAC.IsAssociatedSTA || ~any(arrayfun(@(x) strcmp(x.BSSID, obj.MAC.BSSID), params.DestinationNode(nodeIdx).MAC))), 'wlan:wlanNode:STADestinationUnassociated');
                    % Error for duplicate traffic source
                    coder.internal.errorIf(any((params.DestinationNode(nodeIdx).ID == [obj.Application.PacketInfo(:).DestinationNodeID]) & ...
                        (params.AccessCategory == [obj.Application.PacketInfo(:).AccessCategory])), 'wlan:wlanNode:DuplicateTrafficSource', params.DestinationNode(nodeIdx).Name, params.AccessCategory);
                    % Check if there is at least one common operating frequency
                    % between the source and destination node
                    numFreq = numel(obj.ReceiveFrequency);
                    commonFreqExists = false;
                    for idx = 1:numFreq
                        if any(obj.ReceiveFrequency(idx) == params.DestinationNode(nodeIdx).ReceiveFrequency)
                            commonFreqExists = true;
                            break;
                        end
                    end
                    % If the station is not associated to a BSS, not a mesh
                    % node, and no common frequency exists between the source
                    % and destination nodes
                    coder.internal.errorIf(~obj.MAC(1).IsAssociatedSTA && ~obj.IsMeshNode && ~commonFreqExists, 'wlan:wlanNode:NoCommonBandAndChannel', obj.Name, params.DestinationNode(nodeIdx).Name);

                    out(nodeIdx).DestinationNodeID = params.DestinationNode(nodeIdx).ID;
                    out(nodeIdx).DestinationNodeName = params.DestinationNode(nodeIdx).Name;
                end
            end
        end

        function [meshPathNode, params] = validateMeshPathParams(obj, nInputs, destinationNode, varargin)
        %validateMeshPathParams Validate the inputs for addMeshPath method

            coder.internal.errorIf(~obj.IsMeshNode, 'wlan:wlanNode:MustBeMesh', 'first');
            validateattributes(destinationNode, {'wlanNode'}, {'scalar'}, '', 'destination node');
            if (mod(nInputs, 2) == 0) % mesh path node not given as input
                coder.internal.errorIf(~destinationNode.IsMeshNode, 'wlan:wlanNode:NeedProxyNode');
                meshPathNode = destinationNode;
                nvPair = varargin;
            else % mesh path node given as input
                meshPathNode = varargin{1};
                validateattributes(meshPathNode, {'wlanNode'}, {'scalar'}, '', 'mesh path node');
                coder.internal.errorIf(~meshPathNode.IsMeshNode, 'wlan:wlanNode:MustBeMesh', 'third');
                nvPair = varargin(2:end);
            end

            % NV pairs
            params = struct(SourceBandAndChannel=[], MeshPathBandAndChannel=[], DestinationBandAndChannel=[]);
            for idx = 1:2:numel(nvPair)
                paramName = validatestring(nvPair{idx}, ["SourceBandAndChannel" "MeshPathBandAndChannel" "DestinationBandAndChannel"], mfilename, 'parameter name');
                wlanDeviceConfig.validateBandAndChannel(nvPair{idx+1}, paramName);
                params.(paramName) = nvPair{idx+1};
            end
        end

        function params = validateAssociationParams(~, nvPair)
        %validateAssociationParams validate the NV pairs for
        %associateStations method
            coder.internal.errorIf(mod(numel(nvPair),2) == 1, 'wlan:ConfigBase:InvalidPVPairs');

            % NV pairs
            params = struct(BandAndChannel=[], FullBufferTraffic="off");
            for idx = 1:2:numel(nvPair)
                paramName = validatestring(nvPair{idx}, ["BandAndChannel" "FullBufferTraffic"], mfilename, 'parameter name');
                switch paramName
                    case 'BandAndChannel'
                        paramValue = nvPair{idx+1};
                        wlanDeviceConfig.validateBandAndChannel(paramValue, paramName);
                    otherwise % 'FullBufferTraffic'
                        paramValue = validatestring(nvPair{idx+1}, ["on", "off", "DL", "UL"], mfilename, paramName);
                end
                params.(paramName) = paramValue;
            end
        end
    end

    methods(Static, Hidden)
        function deviceID = getDeviceID(node, bandAndChannel)
            frequency = wlanChannelFrequency(bandAndChannel(2), bandAndChannel(1));
            deviceID = find(node.Frequencies == frequency, 1);
        end
    end

    methods(Access=private)
        function flag = isFrequencyOverlapping(obj, packet, deviceID)
            % Check if frequency of the packet is overlapping with the
            % operating frequency of the device in the node

            rxStartFreq = packet.CenterFrequency-(packet.Bandwidth/2)+1;
            rxEndFreq = packet.CenterFrequency+packet.Bandwidth/2;
            operatingStartFreq = obj.Frequencies(deviceID)-(obj.DeviceConfig(deviceID).ChannelBandwidth/2)+1;
            operatingEndFreq = obj.Frequencies(deviceID)+obj.DeviceConfig(deviceID).ChannelBandwidth/2;
            % Check if frequency is overlapping
            flag = false;
            if ((rxStartFreq >= operatingStartFreq) && (rxStartFreq <= operatingEndFreq)) || ...
                    ((rxEndFreq >= operatingStartFreq) && (rxEndFreq <= operatingEndFreq))
                flag = true;
            end
        end
    end
end
