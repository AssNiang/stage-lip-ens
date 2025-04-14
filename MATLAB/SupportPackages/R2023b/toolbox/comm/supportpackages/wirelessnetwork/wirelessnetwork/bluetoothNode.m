classdef bluetoothNode < comm.internal.ConfigBase & wirelessnetwork.internal.wirelessNode
    %bluetoothNode Bluetooth BR/EDR node
    %   BLUETOOTHBREDRNODE = bluetoothNode(ROLE) creates a default
    %   Bluetooth(R) basic rate/enhanced data rate (BR/EDR) node object for
    %   the specified role, ROLE.
    %
    %   BLUETOOTHBREDRNODE = bluetoothNode(ROLE,Position=Value) creates one
    %   or more Bluetooth BR/EDR node objects. The "Position" input
    %   specifies the number of nodes that the object creates. 'Position'
    %   must be an N-by-3 matrix where N(>=1) is the number of nodes, and
    %   each row must contain three numeric values representing the [X, Y,
    %   Z] position of the node in meters. The output, BLUETOOTHBREDRNODE,
    %   is an array of bluetoothNode objects containing N nodes.
    %
    %   You can optionally set multiple names for the created nodes in the
    %   "Name" property. Specify this value as an array of strings or a
    %   cell array of character vectors. If you do not set this property,
    %   then the default value is "NodeX", where "X" is the Node ID. If
    %   this value is greater than the number of nodes created, then the
    %   object ignores the extra node names. If this value is less than the
    %   number of nodes creates, then the object assigns default node names
    %   to the extra nodes.
    %
    %   BLUETOOTHBREDRNODE = bluetoothNode(ROLE,Name=Value) creates a
    %   Bluetooth BR/EDR node object, BLUETOOTHBREDRNODE, with the
    %   specified property Name set to the specified Value. You can specify
    %   additional name-value arguments in any order as (Name1=Value1, ...,
    %   NameN=ValueN).
    %
    %   ROLE specifies the role of the created Bluetooth BR/EDR node. Set
    %   this value as "central" or "peripheral"
    %
    %   bluetoothNode properties (configurable):
    %
    %   Name                 - Node name
    %   Position             - Node position
    %   TransmitterGain      - Transmitter antenna gain in dB
    %   ReceiverGain         - Receiver antenna gain in dB
    %   ReceiverSensitivity  - Receiver sensitivity in dBm
    %   NoiseFigure          - Noise figure in dB
    %   InterferenceFidelity - Fidelity level to model interference
    %
    %   bluetoothNode properties (read-only):
    %
    %   ID               - Node identifier
    %   Role             - Role of the Bluetooth BR/EDR node
    %   NodeAddress      - Bluetooth BR/EDR node address
    %   ConnectionConfig - Connection configuration object for Central and
    %                      Peripheral nodes
    %   NumConnections   - Number of active connections associated with the
    %                      node
    %
    %   bluetoothNode methods:
    %
    %   addTrafficSource   - Add data traffic source to Bluetooth BR/EDR node
    %   updateChannelList  - Provide updated channel list to Bluetooth BR/EDR node
    %   configureScheduler - Configure baseband scheduler at Bluetooth BR/EDR Central node
    %   statistics         - Get statistics of Bluetooth BR/EDR node
    %   addMobility        - Add random waypoint mobility model to Bluetooth BR/EDR node
    %
    %   % Example 1: Create three Bluetooth BR/EDR Central nodes
    %
    %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
    %   % Library support package is installed. If the support package is not
    %   % installed, MATLAB(R) returns an error with a link to download and install
    %   % the support package.
    %   wirelessnetworkSupportPackageCheck
    %
    %   % Specify the positions of three Central nodes
    %   centralPositions = [1 0 0; 2 0 0; 3 0 0];
    %
    %   % Create an array of 3 Central nodes
    %   centralBREDRNode = bluetoothNode("central",Position=centralPositions)
    %
    %   % Example 2: Create, configure, and simulate Bluetooth BR/EDR piconet
    %   % with ACL traffic
    %
    %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
    %   % Library support package is installed. If the support package is not
    %   % installed, MATLAB(R) returns an error with a link to download and install
    %   % the support package.
    %   wirelessnetworkSupportPackageCheck
    %
    %   % Initialize the wireless network simulator
    %   networkSimulator = wirelessNetworkSimulator.init;
    %
    %   % Create two Bluetooth BR/EDR nodes, specifying the role as "central"
    %   % and "peripheral", respectively
    %   centralNode = bluetoothNode("central");
    %   peripheralNode = bluetoothNode("peripheral", Position = [1 0 0]);
    %
    %   % Create a Bluetooth BR/EDR configuration object and share the
    %   % connection between the Central and Peripheral nodes
    %   cfgConnection = bluetoothConnectionConfig;
    %   configureConnection(cfgConnection,centralNode,peripheralNode);
    %
    %   % Add application traffic from the Central to the Peripheral node
    %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
    %       GeneratePacket=true,OnTime=inf);
    %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNode);
    %
    %   % Add the nodes to the simulator
    %   addNodes(networkSimulator,[centralNode peripheralNode]);
    %
    %   % Set the simulation time in seconds and run the simulation
    %   run(networkSimulator,0.1);
    %
    %   % Retrieve statistics corresponding to the Central and Peripheral nodes
    %   centralStats = statistics(centralNode);
    %   peripheralStats = statistics(peripheralNode);
    %
    %   See also bluetoothConnectionConfig, bluetoothLENode.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties
        %TransmitterGain Transmitter antenna gain in dB
        %   Specify the transmitter antenna gain as a finite numeric scalar.
        %   Units are in dB. The default value is 0 dB.
        TransmitterGain (1,1) {mustBeNumeric,mustBeFinite} = 0

        % ReceiverGain Receiver antenna gain in dB
        %   Specify the receiver antenna gain as a finite numeric scalar. Units
        %   are in dB. The default value is 0 dB.
        ReceiverGain (1,1) {mustBeNumeric,mustBeFinite} = 0

        %ReceiverSensitivity Receiver sensitivity in dBm
        %   Specify the receiver sensitivity as a finite numeric scalar. Units
        %   are in dBm. This property sets the minimum received power to detect
        %   the incoming packet. If the received power of an incoming packet is
        %   below this value, the node drops this packet. The default value is
        %   -100 dBm.
        ReceiverSensitivity (1,1) {mustBeNumeric,mustBeFinite} = -100

        %NoiseFigure Noise figure in dB
        %   Specify the noise figure as a nonnegative finite scalar. Units are
        %   in dB. The object uses this value to apply thermal noise on the
        %   received packet. The default value is 0 dB.
        NoiseFigure (1,1) {mustBeNumeric,mustBeNonnegative,mustBeFinite} = 0

        %InterferenceFidelity Fidelity level to model interference
        %   Specify the fidelity level to model interference as 0 or 1. If you
        %   set this value to 0, the node object considers packets overlapping
        %   in both time and frequency as interference (co-channel
        %   interference). If you set this value to 1, irrespective of
        %   frequency overlap the object considers all the packets (in 2.4GHz
        %   ISM band) overlapping in time as interference. The default value is
        %   0.
        InterferenceFidelity (1,1) {mustBeInteger,mustBeMember(InterferenceFidelity,[0,1])} = 0
    end

    properties (Constant,Hidden)
        % Allowed role values
        Role_Values = ["central","peripheral"]

        %ReceiveBufferSize Maximum number of packets that can be stored at the
        %receiver buffer of the node at a particular time instant, including
        %interfering signals
        ReceiveBufferSize = 10

        % Invoke channel if packet lies in the 2.4 GHz band. The 2.4 GHz band
        % for Bluetooth starts at 2.4e9 Hz and ends at 2.4835e9 Hz.
        BluetoothStartBand = 2.4e9
        BluetoothEndBand = 2.4835e9
    end

    properties (SetAccess = private)
        %Role Role of the Bluetooth BR/EDR node
        %   This role of the node is specified as "central" or "peripheral".
        Role

        %NodeAddress Bluetooth BR/EDR node address
        %   This property is a string scalar denoting a 6-octet hexadecimal
        %   value. The node address is unique to each node and is derived from
        %   the ID property.
        NodeAddress

        %ConnectionConfig Connection configuration object for Central and
        %Peripheral nodes
        %   This property is an object or array of objects of type <a
        %   href="matlab:help('bluetoothConnectionConfig')">bluetoothConnectionConfig</a>.
        ConnectionConfig = bluetoothConnectionConfig

        %NumConnections Number of connections associated with the node
        %   The number of Peripheral nodes associated with the Central node is a
        %   scalar nonnegative integer and is applicable only when the Role
        %   property is specified as "central". You can connect a maximum of seven
        %   Peripheral nodes to a Central node. A Peripheral node can be connected
        %   to only one Central node.
        NumConnections = 0
    end

    properties (SetAccess = private,Hidden)
        %SynchronousPackets List of packet types used over synchronous
        %connection-oriented (SCO) logical transport in the piconet
        SynchronousPackets = strings(1,0)
    end

    properties (Hidden)
        %PHYReceiver PHY receiver object
        PHYReceiver
    end

    properties (Access = private)
        %pBasebandLayer Baseband layer object based on the specified Role
        %property
        pBasebandLayer

        %pPHYTransmitter PHY transmitter object
        pPHYTransmitter

        %pTrafficManager Traffic manager object
        pTrafficManager

        %pCurrentTime Current time of the simulation. This gets updated
        %every time the node is run with the received time. Units are in
        %seconds.
        pCurrentTime = 0

        %pCurrentTimeInMicroseconds Current time in microseconds
        pCurrentTimeInMicroseconds = 0

        %pConnectedNodes Vector of the connected node IDs which are associated
        %with this node
        pConnectedNodes = []

        %pRxInfo Structure containing the receiver information that needs to be
        %passed to the channel
        pRxInfo

        %pIsInitialized Flag to check whether the node is initialized or not
        pIsInitialized = false

        %pIsCentral Flag to specify whether the role is "central" or not
        pIsCentral = false

        %pAppMetadata Default metadata associated with application data as a
        %structure with these fields
        %   DestinationNodeName - Name of the associated destination node
        %   DestinationNodeID   - ID of the associated destination node
        %   LTAddress           - Primary logical transport address of the
        %                         connection
        %   LinkType            - Type of link 0 - Unknown; 1 - ACL; 2 - SCO
        pAppMetadata = struct("DestinationNodeName", [], "DestinationNodeID", 0, ...
            "LTAddress", 0, "LinkType", blanks(0))

        %pEventDataObj Data object for encapsulating information about an event
        %which can then be accessed by the registered listener
        pEventDataObj
    end

    events (Hidden)
        %PacketTransmissionStarted is triggered when the node starts
        %transmitting a packet from the PHY layer. PacketTransmissionStarted
        %passes the event notification along with this structure to the
        %registered callback:
        %   CurrentTime      - Current time of the simulation in seconds. The
        %                      field value is a nonnegative numeric scalar.
        %   Payload          - Payload bits to be transmitted. The field value
        %                      is a binary column vector.
        %   LTAddress        - Logical transport address of the Bluetooth
        %                      BR/EDR packet. The field value is an integer in
        %                      the range [1,7].
        %   PHYMode          - PHY transmission mode, returned as 'BR',
        %                      'EDR2M', or 'EDR3M'.
        %   PacketType       - Transmitted packet type. The field value is a
        %                      string scalar.
        %   ARQN             - Acknowledgment of the previously received data
        %                      packet. This field value is 0 or 1.
        %   SEQN             - Sequence number of the transmitted data packet.
        %                      This field value is 0 or 1.
        %   ChannelIndex     - Channel index for transmission. The field value
        %                      is an integer in the range [0,78].
        %   TransmitPower    - Transmission power of the packet in dBm. The
        %                      field value is a real scalar.
        %   PacketDuration   - Duration of the packet in seconds. The field
        %                      value is a positive numeric scalar.
        PacketTransmissionStarted

        %PacketReceptionEnded is triggered when a packet reception ends at the
        %baseband layer. PacketReceptionEnded passes the event notification
        %along with this structure to the registered callback:
        %   CurrentTime    - Current time of the simulation in seconds. The
        %                    field value is a nonnegative numeric scalar.
        %   SourceNodeName - Name of the source node. The field value is a
        %                    string scalar.
        %   SourceNodeID   - Unique node identifier of the source node. The
        %                    field value is a scalar positive integer.
        %   SuccessStatus  - Flag indicating the success status of packet. The
        %                    field value is a logical scalar. A true value
        %                    represents a successful valid reception at PHY.
        %   DataPayload    - Application payload bits received. The field value
        %                    is a binary column vector.
        %   VoicePayload   - Voice payload bits received. The field value is a
        %                    binary column vector.
        %   LTAddress      - Logical transport address of the Bluetooth BR/EDR
        %                    packet. The field value is an integer in the range
        %                    [1,7].
        %   PHYMode        - PHY reception mode, returned as 'BR', 'EDR2M', or
        %                    'EDR3M'.
        %   PacketType     - Received packet type. The field value is a string
        %                    scalar.
        %   ChannelIndex   - Channel index for reception. The field value is an
        %                    integer in the range [0,78].
        %   ReceivedPower  - Received power in dBm. The field value is a
        %                    scalar.
        %   PacketDuration - Duration of the packet received. The field value is a
        %                    numeric positive scalar value or [].
        %   SINR           - Signal-to-interference plus noise ratio in dB. The
        %                    field value is a scalar.
        %   ARQN           - Acknowledgment of the previously transmitted data
        %                    packet. This field value is 0 or 1.
        %   SEQN           - Sequence number of the data packet. This field
        %                    value is 0 or 1.
        PacketReceptionEnded

        %ChannelMapUpdated is triggered at baseband layer when the node starts
        %using the updated channel map after the updation. ChannelMapUpdated
        %passes the event notification along with this structure to the
        %registered callback:
        %   CurrentTime        - Current time of the simulation in seconds. The
        %                        field value is a nonnegative numeric scalar.
        %   PeerNodeName       - Name of the peer node. The field value is a
        %                        string scalar.
        %   PeerNodeID         - Unique node identifier of the peer node. The
        %                        field value is a scalar positive integer.
        %   UpdatedChannelList - List of good channels used by the physical
        %                        link. The field value is a vector of integers
        %                        in the range [0,78].
        ChannelMapUpdated

        %AppDataReceived is triggered at the traffic source when there is
        %application data decoded by the baseband. AppDataReceived passes the
        %event notification along with this structure to the registered
        %callback:
        %   CurrentTime             - Current time of the simulation in
        %                             seconds. The field value is a nonnegative
        %                             numeric scalar.
        %   SourceNodeName          - Name of the source node which sent the
        %                             application data. The field value is a
        %                             string scalar.
        %   SourceNodeID            - Unique node identifier of the source
        %                             node. The field value is a scalar
        %                             positive integer.
        %   Packet                  - Received application packet in decimal
        %                             octets. The field value is a vector of
        %                             integers in the range [0,255].
        %   PacketLength            - Number of octets of packet. The field
        %                             value is a scalar positive integer.
        %   PacketGenerationTime    - Time at which the packet was generated in
        %                             the source node in seconds. The field
        %                             value is a nonnegative numeric scalar.
        AppDataReceived
    end

    methods
        % Constructor
        function bluetoothNodeObjs = bluetoothNode(role,varargin)
            % Name-value pair check
            coder.internal.errorIf(mod(nargin-1,2)==1,"bluetooth:bleShared:InvalidPVPairs");

            % Validate the role
            bluetoothNodeObjs.Role = validatestring(string(role),bluetoothNode.Role_Values,mfilename,"role",1);
            if strcmp(bluetoothNodeObjs.Role,"central")
                bluetoothNodeObjs.pIsCentral = true;
            end

            numNodes = 1;
            % Updated the properties based on the Name-Value pair
            if nargin > 1
                % Identify number of nodes user intends to create based on
                % Position value
                for idx = 1:2:nargin-2
                    % Search the presence of 'Position' N-V pair argument
                    if strcmp(varargin{idx},"Position")
                        validateattributes(varargin{idx+1},{'numeric'},{'nonempty','ncols',3,'finite'}, mfilename,"Position");
                        positionValue = varargin{idx+1};
                        numNodes = size(varargin{idx+1},1);
                    end
                    % Search the presence of 'Name' N-V pair argument
                    if strcmp(varargin{idx},"Name")
                        nameValue = string(varargin{idx+1});
                    end
                end

                % Create Bluetooth nodes
                bluetoothNodeObjs = repmat(bluetoothNodeObjs,1,numNodes);
                for idx=2:numNodes
                    bluetoothNodeObjs(idx) = bluetoothNode(role);
                end

                % Set the configuration as per the N-V pairs
                for idx=1:2:nargin-2
                    name = varargin{idx};
                    value = varargin{idx+1};
                    switch name
                        case 'Position'
                            % Set position for node(s)
                            for objIdx = 1:numNodes
                                bluetoothNodeObjs(objIdx).Position = positionValue(objIdx, :);
                            end
                        case 'Name'
                            % Set name for node(s). If name is not supplied
                            % for all nodes then leave the trailing nodes
                            % with default names
                            nameCount = min(numel(nameValue), numNodes);
                            for objIdx=1:nameCount
                                bluetoothNodeObjs(objIdx).Name = nameValue(objIdx);
                            end
                        otherwise
                            % Make all the nodes identical by setting same
                            % value for all the configurable properties,
                            % except position and name
                            [bluetoothNodeObjs.(char(name))] = deal(value);
                    end
                end
            end

            for idx = 1:numNodes
                bluetoothNodeObj = bluetoothNodeObjs(idx);

                % Initialize the reception buffer with empty packet
                emptySignal = wirelessnetwork.internal.wirelessPacket;
                bluetoothNodeObj.ReceiveBuffer = repmat(emptySignal,1,bluetoothNodeObj.ReceiveBufferSize);

                % Create callback for event notification from internal layers to
                % the node
                notificationFcn = @(eventName,eventData) triggerEvent(bluetoothNodeObj,eventName,eventData);

                % Initialize the internal modules
                bluetoothNodeObj.pBasebandLayer = bluetooth.internal.baseband(notificationFcn,Role=bluetoothNodeObj.Role);
                bluetoothNodeObj.pPHYTransmitter = bluetooth.internal.phyTransmitter(notificationFcn);
                bluetoothNodeObj.PHYReceiver = bluetooth.internal.phyReceiver;

                % Initialize traffic manager
                appPacket = struct("DestinationNodeName",[],"DestinationNodeID",0,"LTAddress",0,"LinkType",1);
                sendPacketFcn = @(packet) pushUpperLayerData(bluetoothNodeObj.pBasebandLayer,packet);
                bluetoothNodeObj.pTrafficManager = wirelessnetwork.internal.trafficManager(bluetoothNodeObj.ID,sendPacketFcn, ...
                    notificationFcn,PacketContext=appPacket,DataAbstraction=false);

                % Register inter-layer callbacks
                bluetoothNodeObj.pBasebandLayer.ReceiveAppPacketFcn = @(packet) receivePacket(bluetoothNodeObj.pTrafficManager,packet);
                % Initialize receiver information
                bluetoothNodeObj.pRxInfo = struct("ID",bluetoothNodeObj.ID,"Position",[0 0 0],"Velocity",[0 0 0],"NumReceiveAntennas",1);

                % Create a unique node address from the node ID
                id = bluetoothNodeObj.ID;
                lap = randi([1,2^24-1],1);
                % Reserved LAPs of Bluetooth node address
                if lap>=10390272 && lap <=10390335
                    lap = lap+64;
                end
                uap = randi([1,2^8-1],1);
                bluetoothNodeObj.NodeAddress = string([dec2hex(lap,6) dec2hex(uap,2) dec2hex(id,4)]); % 6-bytes
            end
        end

        function addTrafficSource(obj,trafficSource,varargin)
            %addTrafficSource Add data traffic source to Bluetooth(R) BR/EDR
            %node
            %
            %   addTrafficSource(OBJ,TRAFFICSOURCE,
            %   DestinationNode=destinationNode) adds a data source object,
            %   TRAFFICSOURCE, to the Bluetooth BR/EDR node for pumping data traffic
            %   to the specified connected destination, DestinationNode. The Bluetooth
            %   BR/EDR node transports the data traffic over ACL logical link of the
            %   connection.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   TRAFFICSOURCE is an On-Off application traffic pattern object of type
            %   <a href="matlab:help('networkTrafficOnOff')">networkTrafficOnOff</a>.
            %   If you add the traffic source, the <a
            %   href="matlab:help('networkTrafficOnOff.GeneratePacket')">GeneratePacket</a>
            %   property of the traffic source object is not applicable because the
            %   Bluetooth BR/EDR node always generates the packets.
            %
            %   DestinationNode is the destination for the data traffic,
            %   specified as an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   % Example:
            %   % Create, configure, and simulate Bluetooth BR/EDR network.
            %
            %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
            %   % Library support package is installed. If the support package is not
            %   % installed, MATLAB(R) returns an error with a link to download and install
            %   % the support package.
            %
            %   % Initialize the wireless network simulator
            %   networkSimulator = wirelessNetworkSimulator.init;
            %
            %   % Create two Bluetooth BR/EDR nodes, specifying the role as
            %   % "central" and "peripheral", respectively
            %   centralNode = bluetoothNode("central");
            %   peripheralNode = bluetoothNode("peripheral",Position = [1 0 0]);
            %
            %   % Create a Bluetooth BR/EDR configuration object and share the
            %   % connection between the Central and Peripheral nodes
            %   cfgConnection = bluetoothConnectionConfig;
            %   configureConnection(cfgConnection,centralNode,peripheralNode);
            %
            %   % Add application traffic from the Central to the Peripheral
            %   % node
            %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
            %       GeneratePacket=true,OnTime=inf);
            %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNode);
            %
            %   % Add the nodes to the simulator
            %   addNodes(networkSimulator,[centralNode peripheralNode]);
            %
            %   % Set the simulation time in seconds and run the simulation
            %   run(networkSimulator,0.1);
            %
            %   % Retrieve statistics corresponding to the Central and
            %   % Peripheral nodes
            %   centralStats = statistics(centralNode);
            %   peripheralStats = statistics(peripheralNode);

            % Validate data source object
            validateattributes(trafficSource,{'networkTrafficOnOff'},{'scalar'},...
                mfilename,"trafficSource",2);

            % Validate the name-value arguments
            upperLayerDataInfo = validateUpperLayerData(obj,trafficSource,varargin{:});

            % Add the traffic source to the application traffic manager
            addTrafficSource(obj.pTrafficManager,trafficSource,upperLayerDataInfo);
        end

        function status = updateChannelList(obj,newUsedChannelsList,varargin)
            %updateChannelList Provide updated channel list to Bluetooth(R)
            %BR/EDR node
            %
            %   STATUS = updateChannelList(OBJ,NEWUSEDCHANNELSLIST,
            %   DestinationNode=destinationNode) updates the channel map for the specified
            %   destination,DESTINATIONNODE. To enable this syntax, set the
            %   <a href="matlab:help('bluetoothNode.Role')">Role</a> property of <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a> object, OBJ, to "central"
            %   and the <a
            %   href="matlab:help('bluetoothConnectionConfig.HoppingSequenceType')">HoppingSequenceType</a> property of the <a
            %   href="matlab:help('bluetoothNode.ConnectionConfig')">ConnectionConfig</a> property,
            %   to "Connection Adaptive".
            %
            %   STATUS is a flag indicating whether the new channel list is
            %   accepted, returned as 0 (false) or 1 (true).
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   NEWUSEDCHANNELSLIST is the new list of used (good) channels to
            %   update the channel map for the specified Bluetooth BR/EDR node,
            %   specified as an integer vector with element values in the range
            %   [0, 78].
            %
            %   The "DestinationNode" argument is a mandatory input, specifying
            %   the destination node for the new used
            %   channel list. Specify this input as an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>
            %   indicating the destination node.
            %
            %   % Example:
            %   % Classify Channels and Update Channel Map in Bluetooth Network.
            %
            %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
            %   % Library support package is installed. If the support package is not
            %   % installed, MATLAB(R) returns an error with a link to download and install
            %   % the support package.
            %   wirelessnetworkSupportPackageCheck
            %
            %   % Initialize the wireless network simulator
            %   networkSimulator = wirelessNetworkSimulator.init;
            %
            %   % Create two Bluetooth BR/EDR nodes, specifying the role as
            %   % "central" and "peripheral", respectively
            %   centralNode = bluetoothNode("central");
            %   peripheralNode = bluetoothNode("peripheral",Position = [1 0 0]);
            %
            %   % Create a Bluetooth BR/EDR configuration object and share the
            %   % connection between the Central and Peripheral nodes
            %   cfgConnection = bluetoothConnectionConfig;
            %   configureConnection(cfgConnection,centralNode,peripheralNode);
            %
            %   % Add application traffic from the Central to the Peripheral
            %   % node
            %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
            %       GeneratePacket=true,OnTime=inf);
            %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNode);
            %
            %   % Add the nodes to the simulator
            %   addNodes(networkSimulator,[centralNode peripheralNode]);
            %
            %   % Schedule channel list update for the Central node at 0.05
            %   % seconds to use channels 0 to 40
            %   scheduleAction(networkSimulator,@(varargin) updateChannelList(centralNode,...
            %       0:40,DestinationNode=peripheralNode),[],0.05);
            %
            %   % Set the simulation time in seconds and run the simulation
            %   run(networkSimulator,0.1);
            %
            %   % Retrieve statistics corresponding to the Central and
            %   % Peripheral nodes
            %   centralStats = statistics(centralNode);
            %   peripheralStats = statistics(peripheralNode);

            narginchk(4,4);
            coder.internal.errorIf(~obj.pIsInitialized,"bluetooth:bluetoothNode:NodeNotInitialized");
            status = false;
            if ~obj.pIsCentral
                coder.internal.warning("bluetooth:bluetoothNode:NotSupportedForPeripheral",...
                    "updateChannelList");
                return;
            end
            % Update the channel list at baseband layer Apply name-value
            % arguments
            validatestring(varargin{1},{'DestinationNode'},mfilename,"name-value-arguments");
            validateattributes(varargin{2},{'bluetoothNode'},{'row'},mfilename,"DestinationNode");
            connectionIndex = find(varargin{2}.ID==obj.pConnectedNodes);
            if isempty(connectionIndex)
                coder.internal.warning("bluetooth:bluetoothNode:InvalidDestinationNode");
                return;
            end
            status = updateChannelList(obj.pBasebandLayer,newUsedChannelsList,connectionIndex);
        end

        function configureScheduler(obj,varargin)
            %configureScheduler Configure baseband scheduler at Bluetooth(R)
            %BR/EDR Central node
            %
            %   configureScheduler(OBJ) configures the baseband to use the
            %   default scheduler at the Bluetooth BR/EDR Central node. If
            %   a Peripheral node has data to transmit and the available
            %   asynchronous connection-oriented (ACL) slots are sufficient
            %   for the scheduled transmission, the scheduler selects the
            %   Peripheral node. Otherwise, the scheduler selects the next
            %   Peripheral node. To specify the same scheduler configuration
            %   at multiple Central nodes, pass the OBJ argument as an array
            %   of Central nodes. Note that it is not mandatory to configure
            %   the baseband scheduler. The default scheduler is pre-configured.
            %
            %   OBJ is an object or an array of objects of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a> with
            %   the <a href="matlab:help('bluetoothNode.Role')">Role</a> property set to "central".
            %
            %   configureScheduler(OBJ,MaxTransmissions=maxTransmissions) configures
            %   the round-robin (RR) scheduler at the Bluetooth BR/EDR Central node
            %   based on the maximum number of consecutive transmissions,
            %   MaxTransmissions, between the Central and the Peripheral node.
            %
            %   MaxTransmissions specifies the maximum number of
            %   consecutive transmissions scheduled between a
            %   Central-Peripheral node pair. Specify this input as an
            %   integer in the range [1,Inf].
            %
            %   If you set the MaxTransmissions value to 1, the scheduler
            %   at the Central node selects each Peripheral node once in a
            %   fixed cyclic order. The scheduler schedules two consecutive
            %   transmissions between the Central and each Peripheral node,
            %   regardless of the availability of the data between the
            %   nodes. The first transmission occurs from the Central to
            %   the Peripheral and the second transmission takes place from
            %   the Peripheral to the Central.
            %
            %   If you set the MaxTransmissions value to N, where N is any
            %   integer in the range (1,Inf), the scheduler at the Central
            %   node selects each Peripheral node for a maximum of N times
            %   (if data is available) in a fixed cyclic order. If there is
            %   no data to be communicated between the Central-Peripheral
            %   node pair, the scheduler selects the next Peripheral node.
            %
            %   If you set the MaxTransmissions value to Inf, the scheduler
            %   at the Central node selects each Peripheral node in an
            %   exhaustive cyclic order. If there is data to be
            %   communicated between the Central-Peripheral node pair, the
            %   scheduler selects the same Peripheral node. If there is no
            %   data to be communicated between the Central-Peripheral node
            %   pair, the scheduler selects the next Peripheral node.
            %
            %   % Example:
            %   % Create, configure, and simulate Bluetooth BR/EDR network by
            %   % configuring the built-in RR scheduler.
            %
            %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
            %   % Library support package is installed. If the support package is not
            %   % installed, MATLAB(R) returns an error with a link to download and install
            %   % the support package.
            %   wirelessnetworkSupportPackageCheck
            %
            %   % Initialize the wireless network simulator
            %   networkSimulator = wirelessNetworkSimulator.init;
            %
            %   % Create Bluetooth BR/EDR nodes, specifying the role as
            %   % "central" and "peripheral", respectively
            %   centralNode = bluetoothNode("central");
            %   peripheralPos = [1 0 0; 2 0 0];
            %   peripheralNodes = bluetoothNode("peripheral",Position=peripheralPos);
            %
            %   % Create a Bluetooth BR/EDR configuration object and share the
            %   % connection between the Central and Peripheral nodes
            %   cfgConnection = bluetoothConnectionConfig;
            %   configureConnection(cfgConnection,centralNode,peripheralNodes);
            %
            %   % Configure round-robin scheduler at Central node to have
            %   % maximum number of transmit chances per selection as 3
            %   configureScheduler(centralNode,MaxTransmissions=3);
            %
            %   % Add application traffic from the Central to the Peripheral
            %   % nodes
            %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
            %       GeneratePacket=true,OnTime=inf);
            %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNodes(1));
            %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
            %       GeneratePacket=true,OnTime=inf);
            %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNodes(2));
            %
            %   % Add the nodes to the simulator
            %   addNodes(networkSimulator,[centralNode peripheralNodes]);
            %
            %   % Set the simulation time in seconds and run the simulation
            %   run(networkSimulator,0.1);
            %
            %   % Retrieve statistics corresponding to the Central and
            %   % Peripheral nodes
            %   centralStats = statistics(centralNode);
            %   peripheralStats = statistics(peripheralNodes);

            % Validate the number of input arguments
            narginchk(1,3);

            for idx = 1:numel(obj)
                coder.internal.errorIf(~obj(idx).pIsCentral,"bluetooth:bluetoothNode:NotSupportedForPeripheral",...
                    "configureScheduler");

                % Configure maximum number of transmissions in the RR scheduler
                if nargin == 3
                    % Validate maximum number of transmissions
                    validatestring(varargin{1},"MaxTransmissions",mfilename,"name-value-arguments");
                    if varargin{2} ~= inf
                        validateattributes(varargin{2},{'numeric'},{'positive','integer'},mfilename,"MaxTransmissions");
                    end
                    % Configure MaxTransmissions in the scheduler
                    obj(idx).pBasebandLayer.Scheduler.MaxTransmissions = varargin{2};
                end
            end
        end

        function nodeStatistics = statistics(obj)
            %statistics Get statistics of Bluetooth(R) BR/EDR node
            %
            %   NODESTATISTICS = statistics(OBJ) returns the Bluetooth
            %   BR/EDR node statistics. You can fetch statistics for
            %   multiple Bluetooth nodes at once by calling this function
            %   on an array of Bluetooth nodes. NODESTATISTICS is an array
            %   of statistics and an element at index 'idx' contains the
            %   statistics of Bluetooth node at index 'idx' of Bluetooth node
            %   array, OBJ.
            %
            %   NODESTATISTICS is a structure, containing the statistics of
            %   the node when the statistics of one Bluetooth node is
            %   fetched. When the statistics for multiple Bluetooth nodes
            %   are fetched at once, NODESTATISTICS is a structure array.
            %   For more information, see <a
            %   href="matlab:helpview(fullfile(docroot,'toolbox','bluetooth','helptargets.map'),'bluetoothNodeStatistics')">Bluetooth Node Statistics</a>.
            %
            %   OBJ is an object or an array of objects of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   % Example:
            %   % Create, configure, and simulate Bluetooth BR/EDR network.
            %
            %   % Check if the Communications Toolbox(TM) Wireless Network Simulation
            %   % Library support package is installed. If the support package is not
            %   % installed, MATLAB(R) returns an error with a link to download and install
            %   % the support package.
            %   wirelessnetworkSupportPackageCheck
            %
            %   % Initialize the wireless network simulator
            %   networkSimulator = wirelessNetworkSimulator.init;
            %
            %   % Create two Bluetooth BR/EDR nodes, specifying the role as
            %   % "central" and "peripheral", respectively
            %   centralNode = bluetoothNode("central");
            %   peripheralNode = bluetoothNode("peripheral",Position = [1 0 0]);
            %
            %   % Create a Bluetooth BR/EDR configuration object and share the
            %   % connection between the Central and Peripheral nodes
            %   cfgConnection = bluetoothConnectionConfig;
            %   configureConnection(cfgConnection,centralNode,peripheralNode);
            %
            %   % Add application traffic from the Central to the Peripheral
            %   % node
            %   traffic = networkTrafficOnOff(DataRate=200,PacketSize=27, ...
            %       GeneratePacket=true,OnTime=inf);
            %   addTrafficSource(centralNode,traffic,DestinationNode=peripheralNode);
            %
            %   % Add the nodes to the simulator
            %   bluetoothNodes = [centralNode peripheralNode];
            %   addNodes(networkSimulator,bluetoothNodes);
            %
            %   % Set the simulation time in seconds and run the simulation
            %   run(networkSimulator,0.1);
            %
            %   % Retrieve statistics corresponding to the Central and
            %   % Peripheral nodes
            %   centralStats = statistics(bluetoothNodes);

            nodeStatistics = repmat(struct,1,numel(obj));
            for idx = 1:numel(obj)
                node = obj(idx);
                nodeStatistics(idx).Name = node.Name;
                nodeStatistics(idx).ID = node.ID;

                % Get the application statistics
                nodeStatistics(idx).App = statistics(node.pTrafficManager);
                if ~isempty(nodeStatistics(idx).App.TrafficSources)
                    % Remove SCO traffic sources from application statistics as SCO
                    % pumps voice directly into baseband
                    scoTrafficSources = nodeStatistics(idx).App.TrafficSources([nodeStatistics(idx).App.TrafficSources.LinkType] == 2);
                    scoTransmittedPackets = sum([scoTrafficSources.TransmittedPackets]);
                    scoTransmittedBytes = sum([scoTrafficSources.TransmittedBytes]);
                    nodeStatistics(idx).App.TrafficSources([nodeStatistics(idx).App.TrafficSources.LinkType] == ...
                        bluetooth.internal.networkUtilities.SCO) = [];
                    if isempty(nodeStatistics(idx).App.TrafficSources)
                        nodeStatistics(idx).App.TrafficSources = [];
                    else
                        % Remove the link type and logical transport address fields from
                        % the per traffic source statistics
                        nodeStatistics(idx).App.TrafficSources = rmfield(nodeStatistics(idx).App.TrafficSources, ...
                            {'LinkType','LTAddress'});
                    end
                    % Remove number of transmitted SCO packets and bytes from the
                    % aggregated application statistics
                    nodeStatistics(idx).App.TransmittedPackets = nodeStatistics(idx).App.TransmittedPackets-scoTransmittedPackets;
                    nodeStatistics(idx).App.TransmittedBytes = nodeStatistics(idx).App.TransmittedBytes-scoTransmittedBytes;
                end

                % Get the baseband and the PHY statistics
                nodeStatistics(idx).Baseband = statistics(node.pBasebandLayer);
                phyStats = statistics(node.PHYReceiver);
                phyStats.TransmittedPackets = node.pPHYTransmitter.TransmittedPackets;
                phyStats.TransmittedBits = node.pPHYTransmitter.TransmittedBits;
                nodeStatistics(idx).PHY = phyStats;
            end
        end
    end


    methods (Hidden)
        function addConnection(obj,connectionConfig)
            %addConnection Add connection to the node by configuring the
            %connection parameters

            % Validate the input types
            validateattributes(connectionConfig,{'bluetoothConnectionConfig'}, ...
                {'scalar'},mfilename,"connectionConfig",2);

            % Update the number of connections and the connection configuration
            obj.NumConnections = obj.NumConnections+1;
            obj.ConnectionConfig(obj.NumConnections) = connectionConfig;

            % Get destination node ID of the node
            if obj.pIsCentral
                destinationID = connectionConfig.PeripheralID;
            else
                destinationID = connectionConfig.CentralID;
            end

            % Store list of synchronous packets used in the piconet, and add
            % data source for voice traffic
            scoPacketType = connectionConfig.SCOPacketType;
            if ~strcmp(scoPacketType,"None")
                obj.SynchronousPackets(end+1) = scoPacketType;
                % Packet size of HV1, HV2, and HV3 packets are 10, 20, and 30
                % bytes respectively
                size = 10+10*strcmp(scoPacketType,"HV2")+20*strcmp(scoPacketType,"HV3");
                trafficSource = networkTrafficOnOff(OnTime=Inf,OffTime=0, ...
                    DataRate=64,PacketSize=size,GeneratePacket=true);
                upperLayerDataInfo = obj.pAppMetadata;
                upperLayerDataInfo.LTAddress = connectionConfig.PrimaryLTAddress;
                upperLayerDataInfo.LinkType = bluetooth.internal.networkUtilities.SCO;
                addTrafficSource(obj.pTrafficManager,trafficSource,upperLayerDataInfo);
            end
            obj.pConnectedNodes(obj.NumConnections) = destinationID;
        end

        function nextInvokeTime = run(obj,currentTime)
            %run Run Bluetooth(R) BR/EDR node
            %
            %   NEXTINVOKETIME = run(OBJ,CURRENTTIME) runs the Bluetooth BR/EDR
            %   node at the current time instant,CURRENTTIME, and handles all
            %   the events scheduled at the current time. This object function
            %   returns the time instant at which the node runs again.
            %
            %   NEXTINVOKETIME is the time instant (in seconds) at which the
            %   Bluetooth BR/EDR node runs again.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   CURRENTTIME is the current simulation time in seconds.

            % Initialize the node
            if ~obj.pIsInitialized
                init(obj);
            end
            % Update the simulation time
            obj.pCurrentTime = currentTime;
            obj.pCurrentTimeInMicroseconds = round(currentTime*1e6,3);

            % Rx buffer has data to be processed
            if obj.ReceiveBufferIdx ~= 0
                % Process the data in the Rx buffer
                for idx = 1:obj.ReceiveBufferIdx
                    % Get the data from the Rx buffer and process the data
                    nextInvokeTimeInMicroseconds = runLayers(obj,obj.ReceiveBuffer(idx));
                end
                obj.ReceiveBufferIdx = 0;
            else % Rx buffer has no data to process
                % Run all the layers at current time
                nextInvokeTimeInMicroseconds = runLayers(obj,[]);
            end

            % Node next invocation time in seconds
            nextInvokeTime = round(nextInvokeTimeInMicroseconds/1e6,9);
        end

        function pushReceivedData(obj,packet)
            %pushReceivedData Push the received packet to node
            %
            %   pushReceivedData(OBJ,PACKET) pushes the received packet,
            %   PACKET, from the channel to the reception buffer of the node.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   PACKET is the packet received from the channel, specified as a
            %   structure of the format <a
            %   href="matlab:help('wirelessnetwork.internal.wirelessPacket')">wirelessPacket</a>.

            % Copy the received packet to the buffer
            obj.ReceiveBufferIdx = obj.ReceiveBufferIdx+1;
            obj.ReceiveBuffer(obj.ReceiveBufferIdx) = packet;
        end

        function [flag,rxInfo] = isPacketRelevant(obj,packet)
            %isPacketRelevant Return flag to indicate whether packet is
            %relevant for the node
            %
            %   [FLAG,RXINFO] = isPacketRelevant(OBJ,PACKET) returns a flag,
            %   FLAG, specifying whether the incoming packet, PACKET, is
            %   relevant for the node. The object function also returns the
            %   receiver information, RXINFO, required to apply channel
            %   information on the incoming packet.
            %
            %   FLAG is a logical scalar value indicating whether to invoke
            %   channel or not.
            %
            %   The object function returns the output, RXINFO, and is valid
            %   only when the FLAG value is 1 (true). The structure of this
            %   output contains these fields:
            %
            %   ID       - Receiver node identifier
            %   Position - Position of the receiver in Cartesian x-, y-, and z-
            %              coordinates. The field value is a real-valued row
            %              vector in the form [x y z]. Units are in meters.
            %   Velocity - Velocity, v, of receiver in the x- y-, and
            %              z-directions. The field value is a real-valued row
            %              vector in the form [vx vy vz]. Units are in meters
            %              per second.
            %
            %   OBJ is an object of type <a
            %   href="matlab:help('bluetoothNode')">bluetoothNode</a>.
            %
            %   PACKET is the incoming packet to the channel, specified as a
            %   structure of the format <a
            %   href="matlab:help('wirelessnetwork.internal.wirelessPacket')">wirelessPacket</a>.

            % Initialize
            flag = false;
            rxInfo = obj.pRxInfo;

            % If it is self-packet (transmitted by this node) or if the node is
            % not connected to any other node do not get this packet
            if packet.TransmitterID == obj.ID || isempty(obj.ConnectionConfig(1).CentralID)
                return;
            end

            % At Peripheral if the packet is received from its associated
            % Central but not destined to it do not get this packet. A Central
            % can send data to only one associated Peripheral and expect
            % response from the same Peripheral in the next slot. Hence, the
            % transmitted signal from Central will not act as interference to
            % other associated Peripherals.
            if ~obj.pIsCentral && ...
                    obj.ConnectionConfig.CentralID==packet.TransmitterID && ...
                    obj.ConnectionConfig.PrimaryLTAddress~=packet.Metadata.LTAddress
                return;
            end

            % Transmitter frequency
            txStartFrequency = packet.CenterFrequency-packet.Bandwidth/2;
            txEndFrequency = packet.CenterFrequency+packet.Bandwidth/2;

            % Invoke channel if packet lies in the 2.4 GHz band. The 2.4 GHz
            % band starts at 2.4 GHz and ends at 2.4835 GHz.
            if (txStartFrequency >= obj.BluetoothStartBand && txStartFrequency <= obj.BluetoothEndBand) || ...
                    (txEndFrequency >= obj.BluetoothStartBand && txEndFrequency <= obj.BluetoothEndBand)
                % Invoke channel
                flag = true;
                rxInfo.Position = obj.Position;
                rxInfo.Velocity = obj.Velocity;
            end
        end
    end

    methods (Access = private)
        function init(obj)
            %init Initialize the Bluetooth BR/EDR node and its internal modules

            % Initialize baseband layer
            for idx = 1:obj.NumConnections
                addConnection(obj.pBasebandLayer,obj.ConnectionConfig(idx));
            end
            init(obj.pBasebandLayer);

            % Initialize PHY transmitter
            obj.pPHYTransmitter.TransmitterGain = obj.TransmitterGain;

            % Initialize PHY receiver
            obj.PHYReceiver.NoiseFigure = obj.NoiseFigure;
            obj.PHYReceiver.ReceiverGain = obj.ReceiverGain;
            obj.PHYReceiver.ReceiverSensitivity = obj.ReceiverSensitivity;
            obj.PHYReceiver.InterferenceFidelity = obj.InterferenceFidelity;
            init(obj.PHYReceiver);

            % Fill node ID in the Tx buffer
            obj.pIsInitialized = true;
        end

        function nextInvokeTime = runLayers(obj,signal)
            %runLayers Runs the layers within the node with the received packet
            %and returns the next invoke time (in microseconds)

            % Baseband layer object
            baseband = obj.pBasebandLayer;
            % PHY transmitter object
            phyTx = obj.pPHYTransmitter;
            % PHY receiver object
            phyRx = obj.PHYReceiver;

            % Invoke the traffic manager
            nextAppTime = run(obj.pTrafficManager,round(obj.pCurrentTimeInMicroseconds*1e3));
            nextAppTime = round(nextAppTime/1e3,3);

            % Invoke the PHY receiver module
            [nextPHYRxTime,indicationFromPHY] = run(phyRx,obj.pCurrentTimeInMicroseconds,signal);

            % Invoke the baseband module
            [nextBBTime,requestToPHY] = run(baseband,obj.pCurrentTimeInMicroseconds,indicationFromPHY);

            % Baseband requests PHY receiver
            if ~isempty(baseband.RxRequest)
                phyRx.RxRequest = baseband.RxRequest;
            end

            % Invoke the PHY transmitter module
            txPacket = run(phyTx,requestToPHY);

            % Update the transmitted waveform along with the metadata
            if ~isempty(txPacket)
                txPacket.TransmitterID = obj.ID;
                txPacket.TransmitterPosition = obj.Position;
                txPacket.TransmitterVelocity = obj.Velocity;
                txPacket.StartTime = obj.pCurrentTime;
            end
            obj.TransmitterBuffer = txPacket;

            % Update the next invoke time as minimum of next invoke times of
            % all the modules
            nextInvokeTime = min([nextAppTime nextBBTime nextPHYRxTime]);
        end

        function upperLayerData = validateUpperLayerData(obj,dataSource,varargin)
            %validateUpperLayerData Validate the name-value arguments for the
            %upper layer data

            % Initialize upper layer data structure
            upperLayerData = obj.pAppMetadata;

            % Validate the respective name-value arguments
            narginchk(4,4);

            % Apply name-value arguments, and validate the data source against
            % connection configuration
            validatestring(varargin{1},"DestinationNode",mfilename,"name-value-arguments");
            validateattributes(varargin{2},{'bluetoothNode'},{'row'},mfilename,"DestinationNode");
            connectionIndex = find(varargin{2}.ID==obj.pConnectedNodes);
            coder.internal.errorIf(isempty(connectionIndex),"bluetooth:bluetoothNode:InvalidDestinationNode");
            % For packet summary, Refer Bluetooth Core Specification v5.3 - Vol
            % 2, Part B, Section 6.7
            if obj.pIsCentral
                ACLPacketType = obj.ConnectionConfig(connectionIndex).CentralToPeripheralACLPacketType;
            else
                ACLPacketType = obj.ConnectionConfig(connectionIndex).PeripheralToCentralACLPacketType;
            end
            % Check if packet size is valid for the ACL and SCO packets
            bluetooth.internal.networkUtilities.checkPacketSize(ACLPacketType, ...
                obj.ConnectionConfig(connectionIndex).SCOPacketType,dataSource.PacketSize);
            % Update the upper layer data information
            upperLayerData.LTAddress = obj.ConnectionConfig(connectionIndex).PrimaryLTAddress;
            upperLayerData.LinkType = bluetooth.internal.networkUtilities.ACL;
            upperLayerData.DestinationNodeName = varargin{2}.Name;
            upperLayerData.DestinationNodeID = varargin{2}.ID;
        end

        function triggerEvent(obj,eventName,eventData)
            %triggerEvent Trigger the event to notify all the listeners

            if event.hasListener(obj,eventName)
                eventData.CurrentTime = obj.pCurrentTime;
                obj.pEventDataObj = ble.internal.nodeEventData;
                obj.pEventDataObj.Data = eventData;
                notify(obj,eventName,obj.pEventDataObj);
            end
        end
    end
end