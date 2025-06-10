classdef hPlotPacketTransitions < handle
    %hPlotPacketTransitions Plots the live packet transitions across
    %time and frequency for Bluetooth and WLAN nodes in a UI figure
    %
    %   hPlotPacketTransitions(NODES,SIMULATIONTIME,Name=Value) creates the
    %   live packet transition visualization across time and frequency for
    %   Bluetooth, WLAN, and coexistence nodes in UI figure. The first
    %   subplot is time vs nodes. The second subplot is time vs frequency.
    %   You can specify additional name-value arguments in any order as
    %   (Name1=Value1, ..., NameN=ValueN).
    %
    %   NODES is the configured nodes to visualize. Specify this as an array of
    %   objects or cell array of scalar objects of type bluetoothNode,
    %   bluetoothLENode, wlanNode, or helperCoexNode.
    %
    %   SIMULATIONTIME is a finite positive scalar indicating the
    %   simulation time in seconds.
    %
    %   hPlotPacketTransitions properties (Configurable as NV pair):
    %
    %   FrequencyPlotFlag       - Display the time vs frequency plot
    %   VisualizeAtEnd          - Display visualization only at the end of simulation
    %   ShowPacketInfo          - Display of packet information as data tip
    %
    %   Note:
    %     * The figure shows packet communication across time and frequency for all
    %       the configured nodes.
    %     * The top plot shows state transition across time for all the
    %       nodes.
    %     * The bottom plot shows the packet communication in frequency
    %       across time. This plot can be disabled using the FrequencyPlotFlag
    %       NV pair.
    %     * In frequency domain if two or more packets operate in same
    %       frequency, the packet might be with higher contrast indicating
    %       overlap.
    %     * The legend indicating the states and packet type can be seen on the
    %       right for both the plots.
    %     * The time slider and edit box between both the plot can be used to
    %       go to a specific time period.
    %     * The full view check box can be used to view all the nodes and the
    %       complete simulation duration.
    %     * The export button can be used to save a snip of the UI figure.
    %     * Interactions in the UI figure are applicable only at the end of
    %       simulation.

    %   Copyright 2023 The MathWorks, Inc.

    %% Configurable properties as NV pair in constructor
    properties (SetAccess=private)
        %FrequencyPlotFlag Enable the time vs frequency plot
        %   FrequencyPlotFlag is a flag indicating whether to enable or disable the
        %   frequency plot. Enable this flag to display the frequency plot. Disable
        %   this flag to hide the frequency plot. Specify this flag as a logical
        %   scalar. The default value is true.
        FrequencyPlotFlag (1,1) {logical} = true

        %VisualizeAtEnd Display visualization only at the end of simulation
        %   VisualizeAtEnd is a flag indicating whether to display the
        %   visualization only at the end of simulation. If this flag is disabled,
        %   the packet communication can be visualized during the run time of the
        %   simulation. If this flag is enabled, the visualization will be
        %   displayed only after the simulation is over. Irrespective of the state
        %   of this flag, packet communication will be available for the complete
        %   simulation time. For long running simulation enable this flag for
        %   better performance. Specify this flag as a logical scalar. The default
        %   value is false.
        VisualizeAtEnd (1,1) {logical} = false

        %ShowPacketInfo Display of packet information as data tip
        %   PacketClickInfo is a flag indicating whether to enable or disable the
        %   display of packet information as data tip functionality. Enable this
        %   flag to display the data tip. The packet information can be obtained by
        %   clicking on a packet in the state transitions plot. For long running
        %   simulation disable this flag for better performance. Specify this flag
        %   as a logical scalar. The default value is false.
        ShowPacketInfo (1,1) {logical} = false
    end

    %% Figure Based properties
    properties (SetAccess=private)
        %PacketCommUIFigure UI Figure handle for the packet communication
        PacketCommUIFigure

        %StateAxes UI Axes handle for time vs nodes displaying the state
        %transitions
        StateAxes

        %FreqAxes UI Axes handle for time vs frequency displaying the packet
        %communication over frequency
        FreqAxes
    end

    properties (Constant,Hidden)
        % State colors
        ContendColor = "--mw-color-warning"
        TxColor = "--mw-color-success"
        IdleEIFSColor = "--mw-backgroundColor-tertiary"
        RxColorUs = "--mw-graphics-colorOrder-9-quaternary"
        RxColorOthers = "--mw-graphics-colorOrder-2-tertiary"
        RxColorSuccess = "--mw-graphics-colorOrder-11-secondary"
        RxColorFailure = "--mw-color-error"

        % Bar Height
        BarHeight = 1
    end

    properties (Access=private)
        %pMaxNodesToDisplay Maximum number of nodes to display in Y axis of state
        %transitions plot. If the frequency plot is enabled the maximum number of
        %nodes to display is set as 6. If the frequency plot is disabled maximum
        %number of nodes to display is changed as 20.
        pMaxNodesToDisplay

        %pFigUIGL Handle of the grid layout in the UI figure
        pFigUIGL

        %pTimeLine1 Handle of the line to display in the state transition figure
        pTimeLine1

        %pTimeLine2 Handle of the line to display in the time vs frequency figure
        pTimeLine2

        %pTimeWindow Value of the time window in the visualization. The default
        %time window value is 12000 microseconds.
        pTimeWindow = 12000

        %pMinTimeSliderMin Handle for horizontal slider to vary the minimum time
        %value of the plots
        pMinTimeSlider

        %pMaxTimeSlider Handle for horizontal slider to vary the maximum time value
        %of the plots
        pMaxTimeSlider

        %pEditMinHandle Handle for the edit box displaying minimum time value of
        %the plots
        pEditMinHandle

        %pEditMaxHandle Handle for the edit box displaying maximum time value of
        %the plots
        pEditMaxHandle

        %pVSliderHandle Handle for vertical slider. This slider is available only
        %if the number of nodes to visualize is greater than the value of
        %pMaxNodesToDisp value.
        pVSliderHandle

        %pFreqWindowHandle Handle for the drop down for changing frequency. This
        %edit box will be displayed only when more than 1 frequency range exists.
        %2.4 GHz, 5 GHz, and 6 GHz are the supported frequency ranges.
        pFreqWindowHandle

        %pCheckBoxHandle Handle for the check box for displaying the full view
        pCheckBoxHandle

        %pYTickOrder List of Y tick information of the state transition plot. First
        %column indicates ID of the node, second column indicates device ID incase
        %of WLAN, and the third column indicates the type of technology. 1
        %indicates WLAN, 3 indicates Bluetooth LE, and 4 indicates Bluetooth
        %BR/EDR. This is used to plot the packets in their respective positions in
        %the state transition plot.
        pYTickOrder

        %pXLimits X axis limit values stored for usage when reverting from full
        %view
        pXLimits

        %pYLimits Y axis limit values stored for usage when reverting from full
        %view
        pYLimits

        %pMaxLength Maximum length of characters in the Y axis labels of state
        %transition plot
        pMaxLength

        %pMaxYLimitFreq Maximum Y limits in the frequency domain
        pMaxYLimitFreq

        %pIsInitialized Flag to check whether the visualization is initialized or
        %not
        pIsInitialized = false
    end

    %% Standard relevant properties
    properties (Constant,Hidden)
        %PacketInfoWLAN Packet type and packet color of WLAN packets
        PacketInfoWLAN = {1,"--mw-graphics-colorOrder-8-primary"}

        %PacketInfoLE Packet type and packet color of Bluetooth LE packets
        PacketInfoLE = {3,"--mw-graphics-colorOrder-4-quaternary"}

        %PacketInfoBREDR Packet type and packet color of Bluetooth BR/EDR packets
        PacketInfoBREDR = {4,"--mw-graphics-colorOrder-11-quaternary"}

        % Bluetooth LE channel center frequencies in Hz
        LECenterFrequencies = [2404:2:2424 2428:2:2478 2402 2426 2480]*1e6
    end

    properties (SetAccess=private)
        %WLANNodes List of WLAN nodes to visualize. The value is an array of
        %objects of type wlanNode.
        WLANNodes

        %BluetoothNodes List of Bluetooth nodes to visualize. The value is an array
        %of objects of type bluetoothNode or bluetoothLENode object
        BluetoothNodes

        %CoexNodes List of coexistence nodes to visualize. The value is an array
        %of objects of type helperCoexNode object
        CoexNodes

        %InterferingWLANNodes List of interfering WLAN nodes to visualize. The
        %value is an array of objects of type helperInterferingWLANNode object
        InterferingWLANNodes

        %SimulationTime Simulation time in seconds. The value is a nonnegative
        %scalar.
        SimulationTime = 0
    end

    properties (Access=private)
        %pPPDUDuration PPDU duration for WLAN nodes
        pPPDUDuration = zeros(1,3)

        %pNumBREDRNodes Number of Bluetooth BR/EDR nodes configured.
        pNumBREDRNodes = 0

        %pNumLENodes Number of Bluetooth LE nodes configured.
        pNumLENodes = 0

        %pNumWLANNodes Number of WLAN nodes configured.
        pNumWLANNodes = 0

        %pNumInterferingWLANNodes Number of interfering WLAN nodes configured.
        pNumInterferingWLANNodes = 0
    end

    %% Constructor
    methods
        function obj = hPlotPacketTransitions(nodes,simulationTime,varargin)

            % Validate and store the simulation time
            validateattributes(simulationTime,{'numeric'},{'nonempty','scalar','positive','finite'},mfilename,'simulationDuration');
            obj.SimulationTime = max(round(simulationTime,9),1e-9);

            % Name-value pair check
            if mod(nargin-2,2)==1
                error("Invalid property/value pair arguments");
            end

            % Store the NV pair information
            for idx = 1:2:nargin-2
                obj.(char(varargin{idx})) = varargin{idx+1};
            end

            % Validate the nodes
            if iscell(nodes)
                for idx = 1:numel(nodes)
                    validateattributes(nodes{idx},["bluetoothLENode","bluetoothNode","wlanNode","helperCoexNode","helperInterferingWLANNode"], ...
                        {'scalar'},mfilename,'nodes');
                end
            else
                validateattributes(nodes(1),["bluetoothLENode","bluetoothNode","wlanNode","helperCoexNode","helperInterferingWLANNode"], ...
                    {'scalar'},mfilename,'nodes');
                nodes = num2cell(nodes);
            end

            % Segregate the nodes based on their type and attach necessary listeners
            % for plotting the visualization
            countCoex = 1; countBluetooth = 1; countWLAN = 1; countIntWLAN = 1;
            numBREDRNodes = 0; numLENodes = 0; numWLANNodes = 0; numIntWLANNodes = 0;
            for idx = 1:numel(nodes)
                if isa(nodes{idx},"helperCoexNode")
                    obj.CoexNodes{countCoex} = nodes{idx};
                    % Add listener to Bluetooth device
                    addlistener(nodes{idx},"PacketTransmissionStarted",@(srcNode,eventData) bluetoothPlotCallback(obj,srcNode,eventData));
                    addlistener(nodes{idx},"PacketReceptionEnded",@(srcNode,eventData) bluetoothPlotCallback(obj,srcNode,eventData));

                    % Add listener to WLAN device
                    addlistener(nodes{idx},"StateChanged",@(srcNode,eventData) wlanPlotCallback(obj,srcNode,eventData,obj.CoexNodes));
                    addlistener(nodes{idx},"MPDUDecoded",@(srcNode,eventData) wlanPlotCallback(obj,srcNode,eventData,obj.CoexNodes));

                    % Increment device count based on the added devices in coexistence node
                    if ~isempty(nodes{idx}.BluetoothDevice.DeviceName)
                        numBREDRNodes = numBREDRNodes+1;
                    end
                    if ~isempty(nodes{idx}.BluetoothLEDevice.DeviceName)
                        numLENodes = numLENodes+1;
                    end
                    if ~isempty(nodes{idx}.WLANDevice.DeviceName)
                        numWLANNodes = numWLANNodes+1;
                    end
                    countCoex = countCoex+1;
                elseif isa(nodes{idx},"bluetoothNode") || isa(nodes{idx},"bluetoothLENode")
                    obj.BluetoothNodes{countBluetooth} = nodes{idx};
                    % Add listener to Bluetooth device
                    addlistener(obj.BluetoothNodes{countBluetooth},"PacketTransmissionStarted",@(srcNode,eventData) bluetoothPlotCallback(obj,srcNode,eventData));
                    addlistener(obj.BluetoothNodes{countBluetooth},"PacketReceptionEnded",@(srcNode,eventData) bluetoothPlotCallback(obj,srcNode,eventData));

                    % Increment Bluetooth node count
                    if isa(nodes{idx},"bluetoothNode")
                        numBREDRNodes = numBREDRNodes+1;
                    elseif isa(nodes{idx},"bluetoothLENode")
                        numLENodes = numLENodes+1;
                    end
                    countBluetooth = countBluetooth+1;
                elseif isa(nodes{idx},"wlanNode")
                    obj.WLANNodes{countWLAN} = nodes{idx};
                    % Add listener to WLAN device
                    addlistener(obj.WLANNodes{countWLAN},"StateChanged",@(srcNode,eventData) wlanPlotCallback(obj,srcNode,eventData,obj.WLANNodes));
                    addlistener(obj.WLANNodes{countWLAN},"MPDUDecoded",@(srcNode,eventData) wlanPlotCallback(obj,srcNode,eventData,obj.WLANNodes));

                    % Increment WLAN node count
                    numWLANNodes = numWLANNodes+1;
                    countWLAN = countWLAN+1;
                elseif isa(nodes{idx},"helperInterferingWLANNode")
                    obj.InterferingWLANNodes{countIntWLAN} = nodes{idx};
                    addlistener(obj.InterferingWLANNodes{countIntWLAN},"PacketTransmissionStarted",@(srcNode,eventData) interferingWLANPlotCallback(obj,srcNode,eventData));
                    numIntWLANNodes = numIntWLANNodes+1;
                    countIntWLAN = countIntWLAN+1;
                end
            end
            obj.pNumBREDRNodes = numBREDRNodes;
            obj.pNumLENodes = numLENodes;
            obj.pNumWLANNodes = numWLANNodes;
            obj.pNumInterferingWLANNodes = numIntWLANNodes;

            % Schedule actions in the network simulator
            networkSimulator = wirelessNetworkSimulator.getInstance;
            scheduleAction(networkSimulator,@(varargin) updateFigureAtSimulationEnd(obj),[],simulationTime);
            scheduleAction(networkSimulator,@(varargin) pause(0.001),[],0,0.005); %#ok<*testStandardsViolation.pause>
        end
    end

    %% Figure Based Methods
    methods (Access=private)
        function initializeVisualization(obj)
            %initializeVisualization Initialize the visualization

            import matlab.graphics.internal.themes.specifyThemePropertyMappings

            % Get screen resolution and calculate the figure dimension
            set(0,"units","pixels");
            resolution = get(0,"screensize");
            screenWidth = resolution(3);
            screenHeight = resolution(4);
            figureWidth = screenWidth*0.85;
            figureHeight = screenHeight*0.8;

            % Create the UI figure
            if obj.FrequencyPlotFlag
                figUIName = "Packet Communication Over Time And Frequency";
            else
                figUIName = "Packet Communication Over Time";
            end
            obj.PacketCommUIFigure = uifigure("Name",figUIName,"Tag","Packet Communication UI");
            if obj.VisualizeAtEnd
                obj.PacketCommUIFigure.Visible = "off";
            end
            matlab.graphics.internal.themes.figureUseDesktopTheme(obj.PacketCommUIFigure);
            obj.PacketCommUIFigure.Position = [60 60 figureWidth figureHeight];
            obj.PacketCommUIFigure.WindowButtonDownFcn =  @(winn,eventData) updateLine(obj,eventData,zeros(1,0));
            obj.pFigUIGL = uigridlayout(obj.PacketCommUIFigure,[10 4],"ColumnWidth",{'0.5x','0.8x','5x','5x','2x'}, ...
                "RowHeight",{'0.8x','1x','1x','1x','1x','1.5x','1x','1x','1x','1x'});

            % Add title
            title = createLabel(obj,obj.pFigUIGL,figUIName,"Packet Communication Title",18,"Bold",1,[2 4]);
            title.HorizontalAlignment = "center";

            % If the frequency plot is disabled, display the state transition for the
            % complete screen and place the slider below
            if ~obj.FrequencyPlotFlag
                obj.pFigUIGL.RowHeight{9} = "1.5x";
                stateFig1Row = [2 8];
                sliderRow = 9;
                obj.pMaxNodesToDisplay = 20;
            else
                stateFig1Row = [2 5];
                sliderRow = 6;
                obj.pMaxNodesToDisplay = 6;
            end

            % Axes for time vs nodes state transition plot
            obj.StateAxes = uiaxes("Parent",obj.pFigUIGL,"Tag","State Transition Axes");
            obj.StateAxes.XLabel.String = "Time (Microseconds)";
            obj.StateAxes.YLabel.String = "Node Names";
            obj.StateAxes.FontSize = 14;
            assignRowColumnToLayout(obj,obj.StateAxes,stateFig1Row,[2 4]);
            obj.StateAxes.Title.String = "State Transitions of Nodes";
            obj.StateAxes.Title.FontSize = 16;
            xlim(obj.StateAxes,[0 obj.SimulationTime*1e6]);
            hold(obj.StateAxes,"on")

            if obj.FrequencyPlotFlag
                % Axes for time vs frequency
                obj.FreqAxes = uiaxes("Parent",obj.pFigUIGL,"Tag","Frequency Axes");
                obj.FreqAxes.XLabel.String = "Time (Microseconds)";
                obj.FreqAxes.YLabel.String = {'Frequency';'in MHz'};
                obj.FreqAxes.FontSize = 14;
                assignRowColumnToLayout(obj,obj.FreqAxes,[7 10],[2 4]);
                obj.FreqAxes.Title.String = "Packet Communication over Frequency";
                obj.FreqAxes.Title.FontSize = 16;
                hold(obj.FreqAxes,"on")
            end

            % Calculate the tick list and corresponding labels
            tickBase = 1;
            tickIdx = 1;
            yTicksList = zeros(0,1);
            yTickLabels = cell(0,1);

            % Update the Y Ticks of coexistence nodes with node and device for Y axis labels
            wlanFreqInfoCoex = [];
            for idx = 1:numel(obj.CoexNodes)
                if ~isempty(obj.CoexNodes{idx}.WLANDevice.DeviceName)
                    [tickIdx,tickBase,yTicksList,yTickLabels,wlanFreqInfoCoex] = yTicksWLAN(obj,tickIdx,tickBase,yTicksList,yTickLabels,obj.CoexNodes(idx));
                    tickBase = tickBase-obj.BarHeight*0.75;
                end

                for btIdx = [obj.PacketInfoLE{1} obj.PacketInfoBREDR{1}]
                    if (btIdx==4&&~isempty(obj.CoexNodes{idx}.BluetoothDevice.DeviceName))
                        [tickIdx,tickBase,yTicksList,yTickLabels] = yTicksBluetooth(obj,btIdx,["BR" "EDR"],tickIdx,tickBase,yTicksList,yTickLabels,obj.CoexNodes{idx},obj.CoexNodes{idx}.BluetoothDevice.DeviceID);
                        tickBase = tickBase-obj.BarHeight*0.75;
                    elseif(btIdx==3&&~isempty(obj.CoexNodes{idx}.BluetoothLEDevice.DeviceName))
                        [tickIdx,tickBase,yTicksList,yTickLabels] = yTicksBluetooth(obj,btIdx,"LE",tickIdx,tickBase,yTicksList,yTickLabels,obj.CoexNodes{idx},obj.CoexNodes{idx}.BluetoothLEDevice.DeviceID);
                        tickBase = tickBase-obj.BarHeight*0.75;
                    end
                end
                tickBase = tickBase+obj.BarHeight*0.75;
                tickBase = tickBase+obj.BarHeight*1.25;
            end
            tickBase = tickBase-obj.BarHeight*1.25;
            tickIdx = numel(yTickLabels)+1;

            % Update the Y Ticks of Bluetooth nodes
            for idx = 1:numel(obj.BluetoothNodes)
                [tickIdx,tickBase,yTicksList,yTickLabels] = yTicksBluetooth(obj,0,"",tickIdx,tickBase,yTicksList,yTickLabels,obj.BluetoothNodes{idx},1);
            end

            % Update the Y Ticks of interfering WLAN nodes
            wlanFreqInfoIntWLAN = zeros(numel(obj.InterferingWLANNodes),2);
            for idx = 1:numel(obj.InterferingWLANNodes)
                [tickIdx,tickBase,yTicksList,yTickLabels,wlanFreqInfoIntWLAN(idx,:)] = yTicksIntWLAN(obj,0,tickIdx,tickBase,yTicksList,yTickLabels,obj.InterferingWLANNodes{idx});
            end

            % Update the Y Ticks of WLAN nodes
            [~,~,yTicksList,yTickLabels,wlanFreqInfoWLAN] = yTicksWLAN(obj,tickIdx,tickBase,yTicksList,yTickLabels,obj.WLANNodes);
            if ~isempty(wlanFreqInfoCoex)
                wlanFreqInfo = [wlanFreqInfoCoex;wlanFreqInfoIntWLAN;wlanFreqInfoWLAN];
            else
                wlanFreqInfo = [wlanFreqInfoIntWLAN;wlanFreqInfoWLAN];
            end

            % If the number of nodes in Y axis is less than maximum nodes to display
            % update Y Axis
            if numel(yTickLabels)<obj.pMaxNodesToDisplay
                obj.pMaxNodesToDisplay = numel(yTickLabels);
            end
            ymax1 = max(yTicksList(1:obj.pMaxNodesToDisplay))+obj.BarHeight;
            ylim(obj.StateAxes,[0 ymax1]);

            % Update the Y ticks
            yticks(obj.StateAxes,yTicksList);
            obj.StateAxes.YTickLabel = yTickLabels;
            set(obj.StateAxes,"TickLength",[0 0])

            % Calculate the maximum length of the characters for node names to adjust
            % the frequency plot and time slider accordingly
            maxLength = numel(char(yTickLabels{1}));
            for idx=2:numel(yTickLabels)
                if numel(char(yTickLabels{idx}))>maxLength
                    maxLength = numel(char(yTickLabels{idx}));
                end
            end

            % Legend using UI label
            boxColors = [{obj.TxColor};{obj.IdleEIFSColor};{obj.ContendColor}; ...
                {obj.RxColorUs};{obj.RxColorOthers};{obj.RxColorSuccess};{obj.RxColorFailure}];
            headingStateTrans = ["Common States";"WLAN Node States";"Bluetooth Node States"];
            statesList = ["Transmission"; "Idle/EIFS/SIFS"; "Contention"; "Reception (Destined to node)"; ...
                "Reception"; "Reception Success"; "Reception Failure"];

            % Temporary variables to break down the annotation strings and colors
            statePair = [2 3 2]; colorIdx = [0 2 4];

            % Legend for state transition plot
            stateLegendPanel = createPanel(obj,obj.pFigUIGL,"State Transition Legend Panel",[1 5],5);
            stateLegendGrid = uigridlayout(stateLegendPanel,[100 6]);
            idx3 = 0;
            for idx1 = 1:3
                if obj.pNumWLANNodes+obj.pNumInterferingWLANNodes==0 && idx1==2 % No WLAN nodes hence do not display WLAN node states
                    continue;
                elseif obj.pNumBREDRNodes+obj.pNumLENodes==0 && idx1==3 % No Bluetooth nodes hence do not display Bluetooth node states
                    continue;
                end

                % Show "Operating States" as a single heading for WLAN only or Bluetooth only scenario
                if idx1==1 && obj.pNumWLANNodes+obj.pNumInterferingWLANNodes>0 && obj.pNumBREDRNodes+obj.pNumLENodes==0 % Only WLAN nodes
                    statePair = 5;
                    headingStateTrans = "Operating State";
                elseif idx1==1 && obj.pNumWLANNodes+obj.pNumInterferingWLANNodes==0 && obj.pNumBREDRNodes+obj.pNumLENodes>0 % Only Bluetooth nodes
                    statePair = 4;
                    boxColors = [{obj.TxColor};{obj.IdleEIFSColor};{obj.RxColorSuccess};{obj.RxColorFailure}];
                    statesList = ["Transmission"; "Idle/EIFS/SIFS"; "Reception Success"; "Reception Failure"];
                    headingStateTrans = "Operating State";
                end

                % Write the labels for state
                stateLabel = createLabel(obj,stateLegendGrid,headingStateTrans(idx1),strjoin([headingStateTrans(idx1) "Label"]),14,"Bold",[idx3+1 idx3+3],[1 6]);
                idx3 = stateLabel.Layout.Row(2);
                idx3Temp = idx3;
                for idx = 1:statePair(idx1)
                    idx2 = idx3+3;
                    stateLabel = createLabel(obj,stateLegendGrid,statesList(idx+colorIdx(idx1)+(idx1==3)),strjoin([statesList(idx+colorIdx(idx1)+(idx1==3)) "Label"]),14,"normal",[idx3+1 idx2],[2 6]);
                    idx3 = idx2;
                end

                % Draw box for legend to show colors
                idx3 = idx3Temp;
                for idx = 1:statePair(idx1)
                    idx2 = idx3+3;
                    stateBoxPanel = createPanel(obj,stateLegendGrid,"State Legend Panel",[idx3+1 idx2],1);
                    specifyThemePropertyMappings(stateBoxPanel,"BackgroundColor",boxColors{idx+colorIdx(idx1)+(idx1==3),:});
                    idx3 = idx2;
                end

                % Skip the usual headings for WLAN only or Bluetooth only
                % scenario since "Operating States" is added as a single
                % heading
                if (idx1==1 && obj.pNumWLANNodes+obj.pNumInterferingWLANNodes>0 && obj.pNumBREDRNodes+obj.pNumLENodes==0) ... % Only WLAN nodes
                        || (idx1==1 && obj.pNumWLANNodes+obj.pNumInterferingWLANNodes==0 && obj.pNumBREDRNodes+obj.pNumLENodes>0) % Only Bluetooth nodes
                    break;
                end
            end

            if obj.FrequencyPlotFlag
                % If frequency plot is enabled create legend
                freqLegendPanel = createPanel(obj,obj.pFigUIGL,"Freq Comm Legend Panel",[7 10],5);
                freqLegendGrid = uigridlayout(freqLegendPanel,[100 6]);

                techList = ["WLAN"; "Bluetooth LE"; "Bluetooth BR/EDR";];
                freqBoxColors = [obj.PacketInfoWLAN{2}; obj.PacketInfoLE{2}; obj.PacketInfoBREDR{2};];

                idx3 = 0;
                for idx = 1:3
                    if obj.pNumWLANNodes+obj.pNumInterferingWLANNodes==0 && idx==obj.PacketInfoWLAN{1}
                        continue;
                    elseif obj.pNumLENodes==0 && idx==obj.PacketInfoLE{1}-1
                        continue;
                    elseif obj.pNumBREDRNodes==0 && idx==obj.PacketInfoBREDR{1}-1
                        continue;
                    end

                    idx2 = idx3+3;
                    pglp2 = createPanel(obj,freqLegendGrid,"Freq Legend Color Panel",[1+idx3 idx2],1);
                    specifyThemePropertyMappings(pglp2,"BackgroundColor",freqBoxColors(idx,:));
                    stateLabel = createLabel(obj,freqLegendGrid,techList(idx),strjoin([techList(idx) "Label"]),14,"normal",[idx3+1 idx2],[2 6]);
                    idx3 = idx2;
                end
            end

            % Implements the slider for time minimum
            timeScrollPanel = createPanel(obj,obj.pFigUIGL,"Time Min Slider Panel",sliderRow,3);
            timeScrollPanel.BorderColor = timeScrollPanel.BackgroundColor;
            timeEditGrid = uigridlayout(timeScrollPanel,[2 8]);
            editLabelHandle = createLabel(obj,timeEditGrid,"Min Time","Time Min Label",14,"bold",[],[]);
            obj.pEditMinHandle = uieditfield(timeEditGrid,"numeric","Tag","Time Min Edit Field","Limits",[0 obj.SimulationTime*1e6]);
            obj.pEditMinHandle.ValueChangedFcn = @(~,eventData) updateXAxisLimits(obj,eventData.Value,true);
            obj.pMinTimeSlider = uislider(timeEditGrid,"Tag","Time Min Slider");
            assignRowColumnToLayout(obj,obj.pMinTimeSlider,2,[1 8]);
            obj.pMinTimeSlider.Limits = [0 obj.SimulationTime*1e6];
            obj.pMinTimeSlider.ValueChangedFcn = @(~,eventData) updateXAxisLimits(obj,eventData.Value,true);

            % Implements the slider for time maximum
            timeScrollPanel = createPanel(obj,obj.pFigUIGL,"Time Max Slider Panel",sliderRow,4);
            timeScrollPanel.BorderColor = timeScrollPanel.BackgroundColor;
            timeEditGrid = uigridlayout(timeScrollPanel,[2 8]);
            editLabelHandle = createLabel(obj,timeEditGrid,"Max Time","Time Max Label",14,"bold",[],[]);
            editLabelHandle.Layout.Column = 7;
            obj.pEditMaxHandle = uieditfield(timeEditGrid,"numeric","Tag","Time Max Edit Field","Limits",[0 obj.SimulationTime*1e6+obj.pTimeWindow/2]);
            obj.pEditMaxHandle.Layout.Column = 8;
            obj.pEditMaxHandle.ValueChangedFcn = @(edtHandle,eventData) updateXAxisLimits(obj,eventData.Value,false);
            obj.pMaxTimeSlider = uislider(timeEditGrid,"Tag","Time Max Slider");
            assignRowColumnToLayout(obj,obj.pMaxTimeSlider,2,[1 8]);
            obj.pMaxTimeSlider.Limits = [0 obj.SimulationTime*1e6+obj.pTimeWindow/2];
            obj.pMaxTimeSlider.ValueChangedFcn = @(~,eventData) updateXAxisLimits(obj,eventData.Value,false);

            % Implements the drop down for frequency
            maxLimitsYFreq = [];
            if obj.FrequencyPlotFlag
                limitsYFreq = [2400 2500];
                maxLimitsYFreq = limitsYFreq; % For full view
                ddItems = [];
                % Based on the presence of nodes, find the possible frequency bands
                if obj.pNumBREDRNodes+obj.pNumLENodes==0
                    if all(wlanFreqInfo(:,2)/1e6<=2500)
                    elseif all(wlanFreqInfo(:,2)/1e6>=5000) && all(wlanFreqInfo(:,2)/1e6<=5900)
                        limitsYFreq = [5000 6000]; maxLimitsYFreq = limitsYFreq;
                    elseif all(wlanFreqInfo(:,2)/1e6>=5900)
                        limitsYFreq = [5900 7200]; maxLimitsYFreq = limitsYFreq;
                    elseif any(wlanFreqInfo(:,2)/1e6>=2400) && any(wlanFreqInfo(:,2)/1e6>=5000) && all(wlanFreqInfo(:,2)/1e6<=5900)
                        ddItems = ["2.4 GHz band";"5 GHz band"]; maxLimitsYFreq(2) = 6000;
                    elseif any(wlanFreqInfo(:,2)/1e6>=2400) && any(wlanFreqInfo(:,2)/1e6>=5900) && ~(any(wlanFreqInfo(:,2)/1e6>=5000) && any(wlanFreqInfo(:,2)/1e6<=5900))
                        ddItems = ["2.4 GHz band";"6 GHz band"]; maxLimitsYFreq(2) = 7200;
                    elseif all(wlanFreqInfo(:,2)/1e6>=5000)
                        ddItems = ["5 GHz band";"6 GHz band"]; maxLimitsYFreq = [5000 7200];
                    else
                        ddItems = ["2.4 GHz band";"5 GHz band";"6 GHz band"];
                        maxLimitsYFreq(2) = 7200;
                    end
                else
                    if obj.pNumWLANNodes+obj.pNumInterferingWLANNodes>0
                        if (any(wlanFreqInfo(:,2)/1e6>=5000) && any(wlanFreqInfo(:,2)/1e6<=5900))&&any(wlanFreqInfo(:,2)/1e6>=5900)
                            ddItems = ["2.4 GHz band";"5 GHz band";"6 GHz band"];
                            maxLimitsYFreq(2) = 7200;
                        elseif any(wlanFreqInfo(:,2)/1e6>=5000) && all(wlanFreqInfo(:,2)/1e6<=5900)
                            ddItems = ["2.4 GHz band";"5 GHz band"];
                            maxLimitsYFreq(2) = 6000;
                        elseif any(wlanFreqInfo(:,2)/1e6>=5900)
                            ddItems = ["2.4 GHz band";"6 GHz band"];
                            maxLimitsYFreq(2) = 7200;
                        end
                    end
                end
                obj.pMaxYLimitFreq = maxLimitsYFreq;
                obj.pMaxLength = maxLength;

                if numel(ddItems)>1
                    % More than 1 frequency band exists for frequency axes, add a drop down
                    stateLabel = createLabel(obj,freqLegendGrid,"Freq Band","Time Max Label",14,"normal",[idx3+1 idx3+5],[1 3]);
                    obj.pFreqWindowHandle = uidropdown(freqLegendGrid,"Items",ddItems,"Value",ddItems(1),"Tag","Freq Drop Down");
                    assignRowColumnToLayout(obj,obj.pFreqWindowHandle,[idx3+1 idx3+5],[4 6]);
                    obj.pFreqWindowHandle.ValueChangedFcn = @(freqVarHandle,eventData) freqDDCallback(obj,eventData,maxLength);
                end
                calcYTicks(obj,limitsYFreq,maxLength);
            end

            % Panel for axes configurations
            cfgPanel = createPanel(obj,obj.pFigUIGL,"Config Panel",6,5);
            cfgGrid = uigridlayout(cfgPanel,[2 2],"ColumnWidth",{'1x','1x'});

            % Check box for full view
            obj.pCheckBoxHandle = uicheckbox(cfgGrid,"Text","Full view","FontSize",14,"Tag","Full view");
            assignRowColumnToLayout(obj,obj.pCheckBoxHandle,1,1);
            obj.pCheckBoxHandle.ValueChangedFcn = @(checkHandle,eventData) fullViewUpdate(obj);

            % Save Snip button
            saveImageHandle = uibutton(cfgGrid,"Text","Export","FontSize",14,"Tag","Export");
            assignRowColumnToLayout(obj,saveImageHandle,2,1);
            saveImageHandle.ButtonPushedFcn = @(btnHandle,eventData) saveSnipCallback(obj,obj.PacketCommUIFigure);

            % Implements scrollbar for more number of nodes
            if numel(yTickLabels)>obj.pMaxNodesToDisplay
                obj.pVSliderHandle = uislider(obj.pFigUIGL,"Orientation","vertical","Limits",[1 numel(yTickLabels)], ...
                    "MajorTicks",1:numel(yTickLabels),"MinorTicks",[],"Tag","Node Slider");
                if obj.FrequencyPlotFlag
                    assignRowColumnToLayout(obj,obj.pVSliderHandle,[2 5],1);
                else
                    assignRowColumnToLayout(obj,obj.pVSliderHandle,[2 8],1);
                end
                obj.pVSliderHandle.ValueChangedFcn = @(sliderUI,eventData) nodeSliderCallback(obj,eventData);
            end

            % Adds the line at t=0
            updateLine(obj,[],0)

            % Pauses for all the actions to reflect for live visualization
            if ~obj.VisualizeAtEnd
                pause(8);
            end
        end

        function panelHandle = createPanel(obj,parentHandle,tagName,row,column)
            %createPanel Creates UI panel
            panelHandle = uipanel(parentHandle,"Scrollable","on","Tag",tagName);
            assignRowColumnToLayout(obj,panelHandle,row,column);
        end

        function labelHandle = createLabel(obj,parentHandle,labelName,tagName,fontSize,fontWeight,row,column)
            %createLabel Creates UI label
            labelHandle = uilabel(parentHandle,"Text",labelName,"WordWrap","on","FontWeight",fontWeight',"Tag",tagName);
            assignRowColumnToLayout(obj,labelHandle,row,column)
            if ~isempty(fontSize)
                labelHandle.FontSize = fontSize;
            end
        end

        function assignRowColumnToLayout(~,uiHandle,row,column)
            %assignRowColumnToLayout Assigns row and column to the specified UI handle

            if ~isempty(row)
                uiHandle.Layout.Row = row;
            end
            if ~isempty(column)
                uiHandle.Layout.Column = column;
            end
        end

        %% Live Update Functions
        function updateFigure(obj,startTime,duration,stateBox)
            %updateFigure Implement additional visualization options such as updating
            %of scrollbar, edit box, axis limits, and datatip

            % Calculate minimum time and maximum time value
            xLower = startTime-obj.pTimeWindow/2;
            xHigher = startTime+obj.pTimeWindow/2;
            if xLower<0
                xLower=0;
            end
            % Check if X max limit is exceeding simulation time
            if xHigher>obj.SimulationTime*1e6
                xHigher = obj.SimulationTime*1e6;
            end

            % Check if X min limit is lesser than time window after recalculation of X
            % min and max limits
            if xHigher-xLower<obj.pTimeWindow
                xLower = xHigher-obj.pTimeWindow/2;
            end

            % Update the scrollbar and edit box value
            obj.pMinTimeSlider.Value = xLower;
            obj.pMaxTimeSlider.Value = xHigher;
            obj.pEditMinHandle.Value = xLower;
            obj.pEditMaxHandle.Value = xHigher;
            set(obj.StateAxes,"xlim",[xLower,xHigher]);
            if obj.FrequencyPlotFlag
                set(obj.FreqAxes,"xlim",[xLower,xHigher]);
            end

            if obj.ShowPacketInfo
                % % If datatip feature enabled, store packet information
                stateBox.UserData = struct("StartTime",startTime, ...
                    "EndTime",startTime+duration,"Duration",duration);
                stateBox.ButtonDownFcn = @(srcNode,eventData) callbackTips(obj,stateBox,eventData);
            end
        end

        %% Callbacks to the UI Components
        function updateLine(obj,eventData,value)
            %updateLine Add a line handle to the figure

            import matlab.graphics.internal.themes.specifyThemePropertyMappings

            % Return of UI figure was closed
            if isempty(obj.PacketCommUIFigure) || ~isvalid(obj.PacketCommUIFigure)
                return;
            end

            % Get the value when clicked on any axes
            if isempty(value) && isa(eventData.Source.CurrentObject,"matlab.ui.control.UIAxes")
                value = eventData.Source.CurrentObject.CurrentPoint(1,1);
            end

            % Draw the line
            if ~isempty(value)
                % Delete the old line and draw at the new position clicked
                delete(obj.pTimeLine1)
                obj.pTimeLine1 = xline(obj.StateAxes,value,"LineWidth",1,"Tag","Time line 1");
                specifyThemePropertyMappings(obj.pTimeLine1,"Color","--mw-graphics-colorOrder-5-secondary");
                if obj.FrequencyPlotFlag
                    delete(obj.pTimeLine2)
                    obj.pTimeLine2 = xline(obj.FreqAxes,value,"LineWidth",1,"Tag","Time line 2");
                    specifyThemePropertyMappings(obj.pTimeLine2,"Color","--mw-graphics-colorOrder-5-secondary");
                end
            end
        end

        function updateXAxisLimits(obj,newTimeVal,isMin)
            %updateXAxisLimits Update the time limits of the figures

            % Calculate the limits for the time axis
            xlimit_lower=obj.StateAxes.XLim(1);
            xlimit_higher=obj.StateAxes.XLim(2);
            if isMin
                validateattributes(newTimeVal,'double',{'scalar','<=',xlimit_higher},'Minimum Time Value');
                xlimit_lower = newTimeVal;
            else
                validateattributes(newTimeVal,'double',{'scalar','>=',xlimit_lower},'Maximum Time Value');
                xlimit_higher = newTimeVal;
            end

            % Update the scrollbar and edit box value
            obj.pMinTimeSlider.Value = xlimit_lower;
            obj.pMaxTimeSlider.Value = xlimit_higher;
            obj.pEditMinHandle.Value = xlimit_lower;
            obj.pEditMaxHandle.Value = xlimit_higher;

            % Update the X limits of the plots
            obj.StateAxes.XLim = [xlimit_lower,xlimit_higher];
            if obj.FrequencyPlotFlag
                obj.FreqAxes.XLim = [xlimit_lower,xlimit_higher];
            end
        end

        function fullViewUpdate(obj)
            %fullViewUpdate Callback for the full view of the plot

            checkboxHandle = obj.pCheckBoxHandle;
            limitsYFreq = obj.pMaxYLimitFreq;
            maxLength = obj.pMaxLength;

            % Find the limits of the axis based on the check box value
            if checkboxHandle.Value
                enableCfg = "off";
                timeLimit = [0 obj.SimulationTime*1e6+4000];
                nodeLimit = [0 obj.StateAxes.YTick(end)+2];
                obj.pXLimits = obj.StateAxes.XLim;
                obj.pYLimits(1,:) = obj.StateAxes.YLim;
                if obj.FrequencyPlotFlag
                    obj.pYLimits(2,:) = obj.FreqAxes.YLim;
                end
            else
                enableCfg = "on";
                timeLimit = [obj.pXLimits(1) obj.pXLimits(2)];
                nodeLimit = [obj.pYLimits(1,1) obj.pYLimits(1,2)];
                if obj.FrequencyPlotFlag
                    limitsYFreq = [obj.pYLimits(2,1),obj.pYLimits(2,2)];
                end
            end

            % Enable or disable other figure handles accordingly
            if obj.FrequencyPlotFlag
                obj.PacketCommUIFigure.Children.Children(6).Enable = enableCfg;
                obj.PacketCommUIFigure.Children.Children(7).Enable = enableCfg;
                if ~isempty(obj.pFreqWindowHandle)
                    obj.pFreqWindowHandle.Enable = enableCfg;
                end
            else
                obj.PacketCommUIFigure.Children.Children(4).Enable = enableCfg;
                obj.PacketCommUIFigure.Children.Children(5).Enable = enableCfg;
            end
            if ~isempty(obj.pVSliderHandle)
                obj.pVSliderHandle.Enable = enableCfg;
            end

            % Update the limits of the axis
            obj.StateAxes.XLim = timeLimit;
            obj.StateAxes.YLim = nodeLimit;
            if obj.FrequencyPlotFlag
                obj.FreqAxes.XLim = timeLimit;
                calcYTicks(obj,limitsYFreq,maxLength);
            end
        end

        function nodeSliderCallback(obj,eventData)
            %nodeSliderCallback Callback for the vertical slider if there are more
            %nodes

            % Calculate the nominal Y axis limits
            maxYLimitBase = max(obj.StateAxes.YTick(1:obj.pMaxNodesToDisplay))+obj.BarHeight;
            value = round(eventData.Value);

            % Check nominal values with specified value and update
            if value<numel(obj.StateAxes.YTick)
                ylimit_higher = obj.StateAxes.YTick(value)+obj.BarHeight;
            else
                ylimit_higher = obj.StateAxes.YTick(end)+obj.BarHeight;
            end

            % Reset if max Y limit if necessary
            if ylimit_higher<maxYLimitBase
                ylimit_higher = maxYLimitBase;
            end

            % Calculate minimum Y limit
            ylimit_lower = ylimit_higher-maxYLimitBase-obj.BarHeight;
            if ylimit_lower<1
                ylimit_lower = 1;
            end

            % Update the Y Axis limits of state transition plot
            obj.StateAxes.YLim = [ylimit_lower,ylimit_higher];
        end

        function freqDDCallback(obj,eventData,maxLength)
            %freqDDCallback Callback for the frequency drop down

            % Calculate Y axis limits and ticks based on the frequency limits
            switch eventData.Value
                case "2.4 GHz band"
                    freqLimits = [2400 2500];
                case "5 GHz band"
                    freqLimits = [5000 6000];
                case "6 GHz band"
                    freqLimits = [5900 7200];
            end

            % Update the frequency figure Y limits, Ticks, and Labels
            calcYTicks(obj,freqLimits,maxLength)
        end

        function callbackTips(obj,rectObj,eventData)
            %callbackTips Callback if a rectangle object is clicked for datatip

            packetInfo = ["StartTime (us): "+num2str(rectObj.UserData.StartTime) "EndTime (us): "+num2str(rectObj.UserData.EndTime) "Duration (us): "+num2str(rectObj.UserData.Duration)];

            % Display the info
            uialert(obj.PacketCommUIFigure,packetInfo,"Packet Information","Icon","none")

            % Display the line at the position clicked
            updateLine(obj,eventData,eventData.IntersectionPoint(1,1))
        end

        function saveSnipCallback(~,figHandle)
            %saveSnipCallback Save the UI figure as a image

            % Open dialog to get the file name and file format
            filter = {'*.jpg';'*.jpeg';'*.png';'*.tif';'*.tiff';'*.pdf'};
            [filename,filepath] = uiputfile(filter);

            % Once file name is entered, save the UI figure with the specified format
            if ischar(filename)
                exportapp(figHandle,[filepath filename]);
            end
        end

        function calcYTicks(obj,limitsYFreq,maxLength)
            %calcYTicks Based on the Y Frequency limits returns the Y Ticks

            switch string(limitsYFreq)
                case ["2400" "2500"]
                    yTickLabels = {'2400';'2410';'2420';'2430';'2440';'2450';'2460';'2470';'2480';'2490';'2500'};
                case ["2400" "6000"]
                    yTickLabels = {'2400';'2500';'3000';'3500';'4000';'4500';'5000';'5500';'6000'};
                case ["2400" "7200"]
                    yTickLabels = {'2400';'2500';'3000';'4000';'5000';'5500';'6000';'6500';'7000';'7200'};
                case ["5000" "6000"]
                    yTickLabels = {'5000';'5100';'5200';'5300';'5400';'5500';'5600';'5700';'5800';'5900';'6000'};
                case ["5900" "7200"]
                    yTickLabels = {'6000';'6100';'6200';'6300';'6400';'6500';'6600';'6700';'6800';'6900';'7000';'7100';'7200'};
            end
            obj.FreqAxes.YLim = limitsYFreq;
            obj.FreqAxes.YTick = str2double(string(cell2mat(yTickLabels)));
            obj.FreqAxes.YTickLabel = yTickLabels;

            % Adjust the frequency subplot based on the maximum length of node names of
            % state transition plot
            adjustOffset = maxLength+floor((obj.StateAxes.InnerPosition(1)-obj.FreqAxes.InnerPosition(1))/8.5);
            obj.FreqAxes.YTickLabel{1} = [blanks(adjustOffset) obj.FreqAxes.YTickLabel{1}];

        end

        function updateFigureAtSimulationEnd(obj,varargin)
            %updateFigureAtSimulationEnd Update the visualization at the end of
            %simulation

            % Calculate the minimum and maximum limits
            endTime = obj.SimulationTime*1e6;
            limits = [endTime-obj.pTimeWindow/2,endTime+obj.pTimeWindow/2];

            % Update the slider and edit box value
            obj.pEditMinHandle.Value = limits(1);
            obj.pEditMaxHandle.Value = limits(2);
            obj.pMinTimeSlider.Value = limits(1);
            obj.pMaxTimeSlider.Value = limits(2);

            % Add line to the state figure at simulation end time
            updateLine(obj,[],endTime);

            % Update the limits in the figure axes
            set(obj.StateAxes,"xlim",limits);
            set(obj.FreqAxes,"xlim",limits);

            % Display the figure
            obj.PacketCommUIFigure.Visible = "on";

            % Enable full view at the end of simulation
            obj.pCheckBoxHandle.Value = true;
            fullViewUpdate(obj)
        end
    end

    %% Standard Based:Figure relevant Methods
    methods (Access=private)
        function [tickIdx,tickBase,yTicksList,yTickLabels] = yTicksBluetooth(obj,btIdx,techName,tickIdx,tickBase,yTicksList,yTickLabels,node,deviceID)
            %yTicksBluetooth Update and return Y ticks of Bluetooth nodes

            obj.pYTickOrder(tickIdx,:) = [node.ID deviceID btIdx];
            yTickLabels{tickIdx} = node.Name;
            if isa(node,"helperCoexNode")
                tickBase = tickBase+obj.BarHeight*0.5;
                if ~contains(node.Name,techName)
                    yTickLabels{tickIdx} = strjoin([node.Name strjoin(techName)]);
                end
            else
                tickBase = tickBase+obj.BarHeight*1.25;
            end
            tickBase = tickBase+obj.BarHeight*1.25;
            yTicksList(tickIdx) = tickBase;
            tickIdx = tickIdx+1;
            tickBase  = tickBase+obj.BarHeight;
        end

        function [tickIdx,tickBase,yTicksList,yTickLabels,wlanFreqInfo] = yTicksIntWLAN(obj,intWLANIdx,tickIdx,tickBase,yTicksList,yTickLabels,node)
            %yTicksIntWLAN Update and return Y ticks of interfering WLAN nodes

            obj.pYTickOrder(tickIdx,:) = [node.ID 0 intWLANIdx];
            yTickLabels{tickIdx} = strjoin([node.Name num2str(node.CenterFrequency/1e6) "MHz"]);
            tickBase = tickBase+obj.BarHeight*2.5;
            yTicksList(tickIdx) = tickBase;
            tickIdx = tickIdx+1;
            tickBase  = tickBase + obj.BarHeight;
            wlanFreqInfo = [node.ID node.CenterFrequency];
        end

        function [tickIdx,tickBase,yTicksList,yTickLabels,wlanFreqInfo] = yTicksWLAN(obj,tickIdx,tickBase,yTicksList,yTickLabels,nodes)
            %yTicksWLAN Update and return the WLAN frequency information and tick
            %information

            % WLAN information for Y Ticks
            numWLAN = numel(nodes);
            wlanFreqInfo = zeros(numWLAN*3,2);
            if numWLAN>0
                isCoex = isa(nodes{1},"helperCoexNode");
                if isCoex
                    tickBase = tickBase+obj.BarHeight*0.5;
                    node = nodes{1}.WLANDevice;
                    node.ID = nodes{1}.ID;
                    node.Name = nodes{1}.Name;
                else
                    obj.pPPDUDuration = zeros(numWLAN,3);
                end
                wlanFreqInfo = zeros(numWLAN*3,2);
                count = 1;

                for idx = 1:numWLAN
                    if ~isCoex
                        node = nodes{idx};
                        deviceIDs = 1:numel(node.Frequencies);
                    else
                        deviceIDs = [node.DeviceID];
                    end
                    numFreq =  numel(node.Frequencies);
                    wlanFreqInfo(count:count+numFreq-1,:) = [node.ID*ones(numFreq,1) [node.Frequencies]']; % Node ID Frequency
                    obj.pYTickOrder(size(obj.pYTickOrder,1)+1:size(obj.pYTickOrder,1)+numFreq,:) = [node.ID*ones(numFreq,1) deviceIDs' ones(numFreq,1)];
                    count = count+numFreq;
                    tickBase  = tickBase+obj.BarHeight*1.25;
                    for inIdx = 1:numFreq
                        yTicksList(tickIdx) = tickBase;
                        if isCoex
                            yTickLabels{tickIdx} = strjoin([node.Name "WLAN" num2str(node.Frequencies(inIdx)/1e6) "MHz"]);
                        else
                            yTickLabels{tickIdx} = strjoin([node.Name num2str(node.Frequencies(inIdx)/1e6) "MHz"]);
                        end
                        tickIdx = tickIdx+1;
                        tickBase  = tickBase+obj.BarHeight*1.5;
                    end
                    tickBase  = tickBase-obj.BarHeight*0.5;
                end
                wlanFreqInfo = wlanFreqInfo(1:count-1,:);
            end
        end
    end
    %% Standard Based Callbacks for Events
    methods (Access=private)
        function wlanPlotCallback(obj,srcNode,eventData,nodes)
            %wlanPlotCallback Calculates the information necessary for live state
            %transition of WLAN node and plots the transition

            if ~obj.pIsInitialized
                % If visualization is not initialized, create the visualization
                obj.pIsInitialized = true;
                initializeVisualization(obj);
            end

            import matlab.graphics.internal.themes.specifyThemePropertyMappings

            % Return of UI figure was closed
            if isempty(obj.PacketCommUIFigure) || ~isvalid(obj.PacketCommUIFigure)
                return;
            end

            % Get the WLAN node information
            if isa(srcNode,"helperCoexNode")
                sourceNode = srcNode.WLANDevice;
                sourceNode.ID = srcNode.ID;
                sourceNode.Name = srcNode.Name;
            else
                sourceNode = srcNode;
            end

            notificationData = eventData.Data;

            % Get the position in the WLAN nodes and in the Y tick list
            wlanNodeYTickIdx = find(sourceNode.ID==obj.pYTickOrder(:,1));
            nodeIDs = zeros(1,numel(nodes));
            for idx = 1:numel(nodes)
                nodeIDs(idx) = nodes{idx}.ID;
            end
            nodeIdx = find(nodeIDs==sourceNode.ID);
            deviceIdx = notificationData.DeviceID;
            if isa(nodes{nodeIdx},"helperCoexNode")
                nodes{nodeIdx} = nodes{nodeIdx}.WLANDevice;
                deviceIdx = notificationData.DeviceIndex;
            end

            if numel(wlanNodeYTickIdx)>1
                % If more than one Y tick is found, check based on device ID
                wlanDeviceYTickIdx = notificationData.DeviceID==obj.pYTickOrder(wlanNodeYTickIdx,2);
                wlanNodeYTickIdx = wlanNodeYTickIdx(wlanDeviceYTickIdx);
            end

            % Get the channel frequency and bandwidth
            centerFrequency = nodes{nodeIdx}.DeviceConfig(deviceIdx).ChannelFrequency/1e6;
            channelBandwidth = nodes{nodeIdx}.DeviceConfig(deviceIdx).ChannelBandwidth/1e6;
            channelFrequencyStart = centerFrequency-(channelBandwidth/2);

            fillColor = [];
            receptionDestined = false;
            % Update information based on the state of received information
            if isfield(notificationData,"State")
                if strcmp(notificationData.State,"Contention")
                    fillColor = obj.ContendColor;
                    startTime = round((notificationData.CurrentTime-notificationData.Duration)*1e6,3);
                    duration = round(notificationData.Duration*1e6,3);
                elseif strcmp(notificationData.State,"Transmission")
                    fillColor = obj.TxColor;
                    startTime = round(notificationData.CurrentTime*1e6,3);
                    duration = round(notificationData.Duration*1e6,3);
                elseif strcmp(notificationData.State,"Reception")
                    fillColor = obj.RxColorOthers;
                    startTime = round(notificationData.CurrentTime*1e6,3);
                    duration = round(notificationData.Duration*1e6,3);
                    obj.pPPDUDuration(nodeIdx,deviceIdx) = notificationData.Duration;
                end
            else
                if any(~notificationData.FCSFail)
                    if ~isstruct(notificationData.MPDU)
                        % Find first MPDU with FCS pass
                        passIndex = find(~notificationData.FCSFail,1,"first");
                        hex_packet = dec2hex(notificationData.MPDU{passIndex});
                        destinationMACAddress = reshape(hex_packet(5:10,:).',12,1).';
                        receivedMACAddress = nodes{nodeIdx}.MAC(deviceIdx).MACAddress;
                    else
                        destinationMACAddress = notificationData.MPDU.Address1;
                        receivedMACAddress = nodes{nodeIdx}.MAC(deviceIdx).MACAddress;
                    end

                    % Expected MAC address is same or if it is broadcast
                    if strcmp(destinationMACAddress,receivedMACAddress) || strcmp(destinationMACAddress,"FFFFFFFFFFFF")
                        fillColor = obj.RxColorUs;
                        receptionDestined = true;
                        startTime = round((notificationData.CurrentTime- obj.pPPDUDuration(nodeIdx,deviceIdx))*1e6,3);
                        duration = round(obj.pPPDUDuration(nodeIdx,deviceIdx)*1e6,3);
                    end
                end
            end

            if ~isempty(fillColor)
                if numel(wlanNodeYTickIdx)>1
                    for idx = 1:numel(wlanNodeYTickIdx)
                        if obj.pYTickOrder(wlanNodeYTickIdx(idx),3)==obj.PacketInfoWLAN{1}
                            wlanNodeYTickIdx = wlanNodeYTickIdx(idx);
                            break;
                        end
                    end
                end
                % Plot the state transition
                stateBox = rectangle(obj.StateAxes,"Position",[startTime,obj.StateAxes.YTick(wlanNodeYTickIdx)-obj.BarHeight/2,duration,obj.BarHeight]);
                specifyThemePropertyMappings(stateBox,"FaceColor",fillColor);
                verticeVals = [startTime channelFrequencyStart; startTime+duration channelFrequencyStart; startTime+duration channelFrequencyStart+channelBandwidth; startTime  channelFrequencyStart+channelBandwidth];
                if obj.FrequencyPlotFlag && ~receptionDestined && ~strcmp(notificationData.State,"Contention")
                    freqBox = patch(obj.FreqAxes,"Faces",[1 2 3 4],"Vertices",verticeVals,"FaceAlpha",0.3);
                    specifyThemePropertyMappings(freqBox,"FaceColor",obj.PacketInfoWLAN{2});
                end

                % Update the figure for additional actions
                updateFigure(obj,startTime,duration,stateBox);
            end
        end

        function bluetoothPlotCallback(obj,srcNode,eventData)
            %bluetoothPlotCallback Calculates the information necessary for live state
            %transition of Bluetooth nodes and plots the transition

            if ~obj.pIsInitialized
                % If visualization is not initialized, create the visualization
                obj.pIsInitialized = true;
                initializeVisualization(obj);
            end

            % Return of UI figure was closed
            if isempty(obj.PacketCommUIFigure) || ~isvalid(obj.PacketCommUIFigure)
                return;
            end

            import matlab.graphics.internal.themes.specifyThemePropertyMappings

            notificationData = eventData.Data;
            % Update information based on the state of received information
            if isfield(notificationData,"TransmittedPower")
                fillColor = obj.TxColor;
                startTime = round((notificationData.CurrentTime)*1e6,3);
            else
                startTime = round((notificationData.CurrentTime-notificationData.PacketDuration)*1e6,3);
                if notificationData.SuccessStatus
                    fillColor = obj.RxColorSuccess;
                else
                    fillColor = obj.RxColorFailure;
                end
            end
            duration = round(notificationData.PacketDuration*1e6,3);

            % Get the frequency for the channel number received
            channelNumber = notificationData.ChannelIndex;
            if isa(srcNode,"bluetoothNode") || (isa(srcNode,"helperCoexNode")&&any(strcmp(notificationData.PHYMode,["BR","EDR2M","EDR3M"])))
                packetInfo = obj.PacketInfoBREDR;
                channelBandwidth = 1;
                channelFrequencyStart = 2402+channelNumber-0.5;
            else
                packetInfo = obj.PacketInfoLE;
                channelBandwidth = 2;
                channelFrequencyStart = ((obj.LECenterFrequencies(channelNumber+1))/1e6)-channelBandwidth/2;
            end

            % Plot the state transition
            bluetoothNodeYTickIdx = find(srcNode.ID==obj.pYTickOrder(:,1));
            if numel(bluetoothNodeYTickIdx)>1
                for idx = 1:numel(bluetoothNodeYTickIdx)
                    if obj.pYTickOrder(bluetoothNodeYTickIdx(idx),2)==notificationData.DeviceID
                        bluetoothNodeYTickIdx = bluetoothNodeYTickIdx(idx);
                        break;
                    end
                end
            end
            stateBox = rectangle(obj.StateAxes,"Position",[startTime,obj.StateAxes.YTick(bluetoothNodeYTickIdx)-obj.BarHeight/2,duration,obj.BarHeight]);
            specifyThemePropertyMappings(stateBox,"FaceColor",fillColor);

            if obj.FrequencyPlotFlag
                freqBox = rectangle(obj.FreqAxes,"Position",[startTime,channelFrequencyStart,duration,channelBandwidth]);
                specifyThemePropertyMappings(freqBox,"FaceColor",packetInfo{2});
            end

            % Update the figure for additional actions
            updateFigure(obj,startTime,duration,stateBox);
        end

        function interferingWLANPlotCallback(obj,srcNode,eventData)
            %interferingWLANPlotCallback Calculates the information necessary for live
            %state transition of interfering WLAN nodes and plots the transition

            if ~obj.pIsInitialized
                % If visualization is not initialized, create the visualization
                obj.pIsInitialized = true;
                initializeVisualization(obj);
            end

            % Return of UI figure was closed
            if isempty(obj.PacketCommUIFigure) || ~isvalid(obj.PacketCommUIFigure)
                return;
            end

            import matlab.graphics.internal.themes.specifyThemePropertyMappings

            notificationData = eventData.Data;

            % Update information based on the state of received information
            fillColor = obj.TxColor;
            startTime = round((notificationData.CurrentTime)*1e6,3);
            duration = round(notificationData.PacketDuration*1e6,3);

            % Get the frequency for the channel number received
            packetInfo = obj.PacketInfoWLAN;
            channelBandwidth = srcNode.Bandwidth/1e6;
            channelFrequencyStart = (srcNode.CenterFrequency/1e6)-channelBandwidth/2;

            % Plot the state transition
            intWLANNodeYTickIdx = find(srcNode.ID==obj.pYTickOrder(:,1));
            if numel(intWLANNodeYTickIdx)>1
                for idx = 1:numel(intWLANNodeYTickIdx)
                    if obj.pYTickOrder(intWLANNodeYTickIdx(idx),3)==packetInfo{1}
                        intWLANNodeYTickIdx = intWLANNodeYTickIdx(idx);
                        break;
                    end
                end
            end
            stateBox = rectangle(obj.StateAxes,"Position",[startTime,obj.StateAxes.YTick(intWLANNodeYTickIdx)-obj.BarHeight/2,duration,obj.BarHeight]);
            specifyThemePropertyMappings(stateBox,"FaceColor",fillColor);

            if obj.FrequencyPlotFlag
                freqBox = rectangle(obj.FreqAxes,"Position",[startTime,channelFrequencyStart,duration,channelBandwidth]);
                specifyThemePropertyMappings(freqBox,"FaceColor",packetInfo{2});
            end

            % Update the figure for additional actions
            updateFigure(obj,startTime,duration,stateBox);
        end
    end
end
