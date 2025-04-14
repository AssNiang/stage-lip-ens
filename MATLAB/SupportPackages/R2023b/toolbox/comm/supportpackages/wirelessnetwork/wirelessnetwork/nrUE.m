classdef nrUE < wirelessnetwork.internal.nrNode
    %nrUE 5G NR user equipment (UE) node
    %   UE = nrUE creates a default 5G New Radio (NR) UE.
    %
    %   UE = nrUE(Name=Value) creates one or more similar UEs with the
    %   specified property Name set to the specified Value. You can specify
    %   additional name-value arguments in any order as (Name1=Value1, ...,
    %   NameN=ValueN). The number of rows in 'Position' argument defines the
    %   number of UEs created. 'Position' must be an N-by-3 matrix of numbers
    %   where N(>=1) is the number of UEs and each row must contain three
    %   numeric values representing the [X, Y, Z] position of a UE in meters.
    %   The output, UE is an array of nrUE objects containing N UEs.
    %   You can also supply multiple names for 'Name' argument corresponding to
    %   number of UEs created. Multiple names must be supplied either as an
    %   array of strings or cell array of character vectors. If name is not set
    %   then a default name as 'NodeX' is given to node, where 'X' is ID of the
    %   node. Assuming 'N' nodes are created and 'M' names are supplied, then
    %   if (M>N) then trailing (M-N) names are ignored, and if (N>M) then
    %   trailing (N-M) nodes are set to default names.
    %   You can set the "Position" and "Name" properties corresponding to the
    %   multiple UEs simultaneously when you specify them as N-V arguments in
    %   the constructor. After the node creation, you can set the "Position"
    %   and "Name" property for only one UE object at a time.
    %
    %   nrUE properties (configurable through N-V pair as well as public settable):
    %
    %   Name                 - Node name
    %   Position             - Node position
    %
    %   nrUE properties (configurable through N-V pair only):
    %
    %   NumTransmitAntennas  - Number of transmit antennas
    %   NumReceiveAntennas   - Number of receive antennas
    %   TransmitPower        - Peak transmit power in dBm
    %   PHYAbstractionMethod - Physical layer (PHY) abstraction method
    %   NoiseFigure          - Noise figure in dB
    %   ReceiveGain          - Receiver antenna gain in dB
    %
    %   nrUE properties (read-only):
    %
    %   ID              - Node identifier of the UE
    %   ConnectionState - Connection state as "Idle" or "Connected"
    %   GNBNodeID       - Node identifier of the gNB to which UE is connected
    %   RNTI            - Radio network temporary identifier of the UE
    %
    %   nrUE methods:
    %
    %   addTrafficSource     - Add data traffic source to the UE
    %   statistics           - Get statistics of the UE
    %   addMobility          - Add random waypoint mobility model to the UE
    %
    %
    %   % Example 1:
    %   %  Create 10 similar UEs with 20 dBm transmit power. Place the UEs randomly along X-axis
    %   %  within 1000 meters from origin.
    %   numUEs = 10;
    %   position = [1000*rand(numUEs, 1) zeros(numUEs, 2)];
    %   UEs = nrUE(Position=position, TransmitPower=20)
    %
    %   See also nrGNB.

    %   Copyright 2022-2023 The MathWorks, Inc.

    properties(SetAccess = private)
        %NoiseFigure Noise figure in dB
        %   Specify the noise figure in dB. The default value is 6.
        NoiseFigure(1,1) {mustBeNumeric, mustBeFinite, mustBeNonnegative} = 6;

        %ReceiveGain Receiver gain in dB
        %   Specify the receiver gain in dB. The default value is 0.
        ReceiveGain(1,1) {mustBeNumeric, mustBeFinite, mustBeNonnegative} = 0;

        %TransmitPower Peak transmit power of a UE in dBm
        %   Peak transmit power, specified as a finite numeric scalar.
        %   Units are in dBm. The maximum value of transmit power you can
        %   specify is 60 dBm. The default value is 23 dBm. The
        %   configureULPowerControl object function (Uplink transmit power
        %   control mechanism) of the nrGNB object determines the actual
        %   transmit power of a UE node, which can be less than or equal
        %   to the peak transmit power.
        TransmitPower (1,1) {mustBeNumeric, mustBeFinite, mustBeLessThanOrEqual(TransmitPower, 60)} = 23

        %NumTransmitAntennas Number of transmit antennas on UE
        %   Specify the number of transmit antennas on UE. The allowed values are
        %   1, 2, 4. The default value is 1.
        NumTransmitAntennas (1, 1) {mustBeNumeric, mustBeMember(NumTransmitAntennas, ...
            [1 2 4])} = 1;

        %NumReceiveAntennas Number of receive antennas on UE
        %   Specify the number of receive antennas on UE. The allowed values are
        %   1, 2, 4. The default value is 1.
        NumReceiveAntennas (1, 1) {mustBeNumeric, mustBeMember(NumReceiveAntennas, ...
            [1 2 4])} = 1;

        %PHYAbstractionMethod PHY abstraction method
        %   Specify the PHY abstraction method as "linkToSystemMapping" or "none".
        %   The value "linkToSystemMapping" represents link-to-system-mapping based
        %   abstract PHY. The value "none" represents full PHY processing. The default
        %   value is "linkToSystemMapping".
        PHYAbstractionMethod = "linkToSystemMapping";
    end

    properties (SetAccess = private)
        %GNBNodeID Node ID of the gNB to which UE is connected
        GNBNodeID

        %ConnectionState Connection state of the UE as "Idle" or "Connected"
        ConnectionState = "Idle"

        %RNTI Radio network temporary identifier (integer in the range 1 to 65519, inclusive) of the UE
        RNTI;
    end

    properties(SetAccess = private, Hidden)
        %MUMIMOEnabled MU-MIMO enabled (Value 1) or not (Value 0)
        MUMIMOEnabled

        %NCellID Physical layer cell identity
        NCellID
    end

    methods(Access = public)
        function obj = nrUE(varargin)

            % Name-value pair check
            coder.internal.errorIf(mod(nargin, 2) == 1,'MATLAB:system:invalidPVPairs');

            if nargin > 0
                param = nr5g.internal.nrNodeValidation.validateUEInputs(varargin);
                names = param(1:2:end);
                % Search the presence of 'position' N-V pair argument to calculate
                % the number of UEs user intends to create
                positionIdx = find(strcmp([names{:}], 'Position'), 1, 'last');
                numUEs = 1;
                if ~isempty(positionIdx)
                    position = param{2*positionIdx}; % Read value of Position N-V argument
                    validateattributes(position, {'numeric'}, {'nonempty', 'ncols', 3, 'finite'}, mfilename, 'Position');
                    if ismatrix(position)
                        numUEs = size(position, 1);
                    end
                end

                % Search the presence of 'Name' N-V pair argument
                nameIdx = find(strcmp([names{:}], 'Name'), 1, 'last');
                if ~isempty(nameIdx)
                    nodeName = param{2*nameIdx}; % Read value of Position N-V argument
                end

                % Create UE(s)
                obj(1:numUEs) = obj;
                for i=2:numUEs
                    obj(i) = nrUE();
                end

                % Set the configuration of UE(s) as per the N-V pairs
                for i=1:2:nargin-1
                    paramName = param{i};
                    paramValue = param{i+1};
                    switch (paramName)
                        case 'Position'
                            % Set position for UE(s)
                            for j = 1:numUEs
                                obj(j).Position = position(j, :);
                            end
                        case 'Name'
                            % Set name for UE(s). If name is not supplied for all UEs then leave the
                            % trailing UEs with default names
                            nameCount = min(numel(nodeName), numUEs);
                            for j=1:nameCount
                                obj(j).Name = nodeName(j);
                            end
                        otherwise
                            % Make all the UEs identical by setting same value for all the configurable
                            % properties, except position and name
                            [obj.(char(paramName))] = deal(paramValue);
                    end
                end
            end

            % Create internal layers for each UE
            phyParam = {'TransmitPower', 'NumTransmitAntennas', 'NumReceiveAntennas', ...
                'NoiseFigure', 'ReceiveGain', 'Position'};

            % Create internal layers for each UE
            for idx=1:numel(obj)
                ue = obj(idx);

                % Set up traffic manager
                ue.TrafficManager = wirelessnetwork.internal.trafficManager(ue.ID, ...
                    [], @ue.processEvents, DataAbstraction=false, ...
                    PacketContext=struct('DestinationNodeID', 0, 'LogicalChannelID', 4, 'RNTI', 0));

                % Set up MAC
                ue.MACEntity = nr5g.internal.nrUEMAC(@ue.processEvents);

                % Set up PHY
                phyInfo = struct();
                for j=1:numel(phyParam)
                    phyInfo.(char(phyParam{j})) = ue.(char(phyParam{j}));
                end
                if strcmp(ue.PHYAbstractionMethod, "none")
                    ue.PhyEntity = nr5g.internal.nrUEFullPHY(phyInfo); % Full PHY
                    ue.PHYAbstraction = 0;
                else
                    ue.PhyEntity = nr5g.internal.nrUEAbstractPHY(phyInfo); % Abstract PHY
                    ue.PHYAbstraction = 1;
                end

                % Set inter-layer interfaces
                ue.setLayerInterfaces();
            end
        end

        function stats = statistics(obj)
            %statistics Return the statistics of the UE
            %
            %   STATS = statistics(OBJ) returns the statistics of the UE, OBJ. 
            %   STATS is a structure with these fields.
            %   ID   - ID of the UE
            %   Name - Name of the UE
            %   App  - Application layer statistics
            %   RLC  - RLC layer statistics
            %   MAC  - MAC layer statistics
            %   PHY  - PHY layer statistics
            %
            %   App is a structure with these fields.
            %   TransmittedPackets  - Total number of packets transmitted to the RLC layer
            %   TransmittedBytes    - Total number of bytes transmitted to the RLC layer
            %   ReceivedPackets     - Total number of packets received from the RLC layer
            %   ReceivedBytes       - Total number of bytes received from the RLC layer
            %
            %   RLC is a structure with these fields.
            %   TransmittedPackets  - Total number of packets transmitted to the MAC layer
            %   TransmittedBytes    - Total number of bytes transmitted to the MAC layer
            %   ReceivedPackets     - Total number of packets received from the MAC layer
            %   ReceivedBytes       - Total number of bytes received from the MAC layer
            %   DroppedPackets      - Total number of received packets dropped due to
            %                         reassembly failure
            %   DroppedBytes        - Total number of received bytes dropped due to
            %                         reassembly failure
            %
            %   MAC is a structure with these fields.
            %   TransmittedPackets  - Total number of packets transmitted to the PHY layer.
            %                         It only corresponds to new transmissions assuming
            %                         that MAC does not send the packet again to the
            %                         PHY for retransmissions. Packets are buffered at
            %                         PHY. MAC only sends the requests for
            %                         retransmission to the PHY layer
            %   TransmittedBytes    - Total number of bytes transmitted to the PHY layer
            %   ReceivedPackets     - Total number of packets received from the PHY layer
            %   ReceivedBytes       - Total number of bytes received from the PHY layer
            %   Retransmissions     - Total number of retransmissions requests sent to the PHY layer
            %   RetransmissionBytes - Total number of MAC bytes which correspond to retransmissions
            %   DLTransmissionRB    - Total number of downlink resource blocks assigned
            %                         for new transmissions
            %   DLRetransmissionRB  - Total number of downlink resource blocks assigned
            %                         for retransmissions
            %   ULTransmissionRB    - Total number of uplink resource blocks assigned
            %                         for new transmissions
            %   ULRetransmissionRB  - Total number of uplink resource blocks assigned
            %                         for retransmissions
            %
            %   PHY is a structure with these fields.
            %   TransmittedPackets  - Total number of packets transmitted
            %   ReceivedPackets     - Total number of packets received
            %   DecodeFailures      - Total number of decode failures
            %
            % You can fetch statistics for multiple UEs at once by calling this
            % function on an array of UE objects. An element at the index 'i' of STATS
            % contains the statistics of UE at index 'i' of the UE array, OBJ.

            stats = arrayfun(@(x) x.statisticsPerUE, obj);
        end
    end

    methods (Access = protected)
        function flag = isInactiveProperty(obj, prop)
            flag = false;
            switch prop
                case "GNBNodeID"
                    flag = isempty(obj.GNBNodeID);
                case "RNTI"
                    flag = isempty(obj.RNTI);
            end
        end
    end

    methods(Hidden)
        function addConnection(obj, connectionConfig)
            %addConnection Add connection context to UE

            obj.NCellID = connectionConfig.NCellID;
            obj.RNTI = connectionConfig.RNTI;
            obj.ConnectionState = "Connected";
            obj.GNBNodeID = connectionConfig.GNBID;
            obj.ULCarrierFrequency = connectionConfig.ULCarrierFrequency;
            obj.DLCarrierFrequency = connectionConfig.DLCarrierFrequency;
            obj.ReceiveFrequency = connectionConfig.DLCarrierFrequency;
            obj.MUMIMOEnabled = strcmp(connectionConfig.CSIReportConfiguration.CodebookType, 'Type2');
            % Add connection context to MAC
            macConnectionParam = {'RNTI', 'GNBID', 'GNBName' 'NCellID', 'SchedulingType', 'NumHARQ', ...
                'DuplexMode', 'DLULConfigTDD', 'RBGSizeConfiguration', 'CSIRSConfiguration', 'SRSConfiguration', 'NumResourceBlocks', ...
                'BSRPeriodicity', 'CSIReportPeriod', 'InitialCQIDL', 'SubcarrierSpacing'};
            macConnectionInfo = struct();
            for j=1:numel(macConnectionParam)
                macConnectionInfo.(char(macConnectionParam{j})) = connectionConfig.(char(macConnectionParam{j}));
            end
            % Convert the SCS value from Hz to kHz
            subcarrierSpacingInKHZ = connectionConfig.SubcarrierSpacing/1e3;
            macConnectionInfo.SubcarrierSpacing = subcarrierSpacingInKHZ;
            obj.MACEntity.addConnection(macConnectionInfo);

            % Add connection context to PHY
            phyConnectionParam = {'RNTI', 'NCellID', 'DuplexMode', 'NumResourceBlocks', ...
                'NumHARQ', 'ChannelBandwidth', 'PoPUSCH', 'AlphaPUSCH', 'GNBTransmitPower',...
                'DLCarrierFrequency', 'ULCarrierFrequency', ...
                'CSIReportConfiguration', 'SubcarrierSpacing'};
            phyConnectionInfo = struct();
            for j=1:numel(phyConnectionParam)
                phyConnectionInfo.(char(phyConnectionParam{j})) = connectionConfig.(char(phyConnectionParam{j}));
            end
            phyConnectionInfo.SubcarrierSpacing = subcarrierSpacingInKHZ;
            obj.PhyEntity.addConnection(phyConnectionInfo);

            % Add connection context to RLC entity
            rlcConnectionParam = {'RNTI', 'FullBufferTraffic', 'RLCBearerConfig'};
            rlcConnectionInfo = struct();
            for j=1:numel(rlcConnectionParam)
                rlcConnectionInfo.(char(rlcConnectionParam{j})) = connectionConfig.(char(rlcConnectionParam{j}));
            end
            obj.FullBufferTraffic = rlcConnectionInfo.FullBufferTraffic;
            addRLCBearer(obj, rlcConnectionInfo);
        end

        function updateSRSPeriod(obj, srsPeriod)
            % Update the period of existing SRS configuration

            updateSRSPeriod(obj.MACEntity, srsPeriod);
        end

        function flag = intracellPacketRelevance(obj, packet)
            %intracellPacketRelevance Returns whether the packet is intra-cell and is relevant for the UE

            flag = 1;
            if packet.Type==2 &&  ~obj.MUMIMOEnabled && packet.Metadata.NCellID==obj.NCellID && ...
                    packet.Metadata.PacketType==nr5g.internal.nrPHY.PXSCHPacketType && ...
                    ~any(packet.Metadata.RNTI == obj.RNTI)
                % If MU-MIMO is disabled then reject any intra-cell PDSCH packet not intended for this UE
                flag = 0;
            end
        end
    end

    methods(Access = protected)
        function setLayerInterfaces(obj)
            %setLayerInterfaces Set inter-layer interfaces

            phyEntity = obj.PhyEntity;
            macEntity = obj.MACEntity;

            % Register Phy interface functions at MAC for:
            % (1) Sending packets to Phy
            % (2) Sending Rx request to Phy
            % (3) Sending DL control request to Phy
            % (4) Sending UL control request to Phy
            registerPhyInterfaceFcn(obj.MACEntity, @phyEntity.txDataRequest, ...
                @phyEntity.rxDataRequest, @phyEntity.dlControlRequest, @phyEntity.ulControlRequest);

            % Register MAC callback function at Phy for:
            % (1) Sending the packets to MAC
            % (2) Sending the measured DL channel quality to MAC
            registerMACHandle(obj.PhyEntity, @macEntity.rxIndication, @macEntity.csirsIndication);

            % Register node callback function at Phy and MAC for:
            % (1) Sending the out-of-band packets from MAC
            % (2) Sending the in-band packets from Phy
            registerOutofBandTxFcn(macEntity, @obj.addToTxBuffer);
            registerTxHandle(phyEntity, @obj.addToTxBuffer);
        end

        function stats = statisticsPerUE(obj)
            % Return the statistics of UE

            % Create stats structure
            appStat = struct('TransmittedPackets', 0, 'TransmittedBytes', 0, ...
                'ReceivedPackets', 0, 'ReceivedBytes', 0);
            rlcStat = struct('TransmittedPackets', 0, 'TransmittedBytes', 0, ...
                'ReceivedPackets', 0, 'ReceivedBytes', 0, 'DroppedPackets', 0, ...
                'DroppedBytes', 0);
            macStat = struct('TransmittedPackets', 0, 'TransmittedBytes', 0, ...
                'ReceivedPackets', 0, 'ReceivedBytes', 0, 'Retransmissions', 0, ...
                'RetransmissionBytes', 0, 'DLTransmissionRB', 0, 'DLRetransmissionRB', 0, ...
                'ULTransmissionRB', 0, 'ULRetransmissionRB', 0);
            phyStat = struct('TransmittedPackets', 0, 'ReceivedPackets', 0, ...
                'DecodeFailures', 0);
            stats = struct('ID', obj.ID, 'Name', obj.Name, 'App', appStat, ...
                'RLC', rlcStat, 'MAC', macStat, 'PHY', phyStat);

            if ~isempty(obj.RNTI) % Check if UE is connected
                % Fetch per-layer stats
                stats.App = statistics(obj.TrafficManager);
                stats.RLC = cellfun(@(x) statistics(x), obj.RLCEntity)';
                stats.MAC = statistics(obj.MACEntity);
                stats.PHY = statistics(obj.PhyEntity);

                stats.App = rmfield(stats.App, 'TrafficSources');
                % RLC stats structure
                rlcStat = struct('TransmittedPackets', 0, 'TransmittedBytes', 0, ...
                    'ReceivedPackets', 0, 'ReceivedBytes', 0, 'DroppedPackets', 0, ...
                    'DroppedBytes', 0);
                % Form RLC stats
                fieldNames = fieldnames(rlcStat);
                for i=1:length(stats.RLC)
                    logicalChannelStat = stats.RLC(i);
                    for j=1:numel(fieldNames)
                        % Create cumulative stats
                        rlcStat.(char(fieldNames{j})) = rlcStat.(char(fieldNames{j})) + ...
                            logicalChannelStat.(char(fieldNames{j}));
                    end
                end
                stats.RLC = rlcStat;
            end
        end
    end
end