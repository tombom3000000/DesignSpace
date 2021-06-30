classdef DesignSpace_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DesignSpacePlotterUIFigure  matlab.ui.Figure
        DataPanel                   matlab.ui.container.Panel
        ExperimentListBox           matlab.ui.control.ListBox
        ExperimentsLabel            matlab.ui.control.Label
        VariableListBox             matlab.ui.control.ListBox
        VariablesLabel              matlab.ui.control.Label
        LoadfileButton              matlab.ui.control.Button
        Label                       matlab.ui.control.Label
        SettingsPanel               matlab.ui.container.Panel
        ColourpalletDropDownLabel   matlab.ui.control.Label
        ColourpalletDropDown        matlab.ui.control.DropDown
        DefaultcolorDropDownLabel   matlab.ui.control.Label
        DefaultcolorDropDown        matlab.ui.control.DropDown
        StemstyleDropDownLabel      matlab.ui.control.Label
        StemstyleDropDown           matlab.ui.control.DropDown
        SizeSliderLabel             matlab.ui.control.Label
        SizeSlider                  matlab.ui.control.Slider
        ToggledebugCheckBox         matlab.ui.control.CheckBox
        InvertToggle                matlab.ui.control.CheckBox
        GridoffCheckBox             matlab.ui.control.CheckBox
        VideoButton                 matlab.ui.control.Button
        FPSEditFieldLabel           matlab.ui.control.Label
        FPSEditField                matlab.ui.control.NumericEditField
        PlotPanel                   matlab.ui.container.Panel
        PlotLabel                   matlab.ui.control.Label
        GraphAxes                   matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        filePath % File path
        fileName % File name
        variables = zeros(1) % The table where all the data gets stored
        varNames % The variable names
        experiments % The name of each experiment (numbered list)
        colorScheme = parula; % Default colour map (parula)
        defaultColor = "blue"; % Default normal colour
        lineStyle = "-"; % Default line style
        defaultSize = 40 % Default point Size
        gridOff = false; % Defines if the grid is on or off (off default)
        vid = false; % If true then starts to make the vido (false default)
        vidImagesFile = 'VideoImages\'; % File location for the images that create the video
        Blue2Red % Predefine the Blue2Red custom color map
        ColourLinked % The array of variables that points to each colour map
        fps = 2; % Default fps
        
    end
    
    methods (Access = private)

%--------------------------------------------------------------------------
        
        % Resets the variables when a new file is loaded
        function reset(app)
            app.filePath = "";
            app.fileName = "";
            app.variables = zeros(1);
            app.varNames = "";
            app.experiments = "";
        end

%--------------------------------------------------------------------------        
        
        % Loads the variables and experiments into the list boxes
        function loadVariables(app)
            % Extracts the variable names and adds them to the variables
            % list box (var names in the header of the file submitted)
            app.varNames = app.variables.Properties.VariableNames;
            app.VariableListBox.Items = app.varNames;
            
            % Labels each experiment detected (number of rows) from 1 to
            % the total number of experiments
            numbOfExp = size(app.variables,1);
            app.experiments = string(1:numbOfExp);
            app.ExperimentListBox.Items = app.experiments;
        end
 
%--------------------------------------------------------------------------        
        
       %Updates the graph UI 
       function updateGraph(app)
            
            % Gets the selected value that is contained in the list box
            selectedGraphNames = app.ExperimentListBox.Value;
            
            % If there are multiple selected, it turns
            % them into a cell. Therefore this detects this and reverts it
            % back to a strign array if multiple are selected. If only one
            % is detected it is a char. Therefore convert it to a string.
            if iscell(selectedGraphNames)
                selectedGraphNames = cellfun(@string, selectedGraphNames);
            else
                selectedGraphNames = string(selectedGraphNames);
            end 
            
            %Creates an intal empty logal array with all zero with all the
            %possible selections it could be
            logicArry = false(1,length(app.ExperimentListBox.Items));
            
            %Loops through each experiment selectd and finds the
            %location of it.
            for resp = 1:length(selectedGraphNames)
                
                % Finds the location of the experiment in the list 
                % of the allowed experiments and flips it so it adds
                % correctly to the logic array.
                temp = strcmp(string(1:length(app.experiments)),selectedGraphNames(resp));
                
                % Adds on this location. If == 1 then that responce
                % function is being used, if == 0 then it is not.
                logicArry = logicArry + temp;
            end
            
            % Clear graph
            cla(app.GraphAxes,'reset')
            
            % Gets the selected value that is contained in the list box
            selectedVars = app.VariableListBox.Value;
            
            % If there are multiple selected, it turns
            % them into a cell. Therefore this detects this and reverts it
            % back to a strign array if multiple are selected. If only one
            % is detected it is a char. Therefore convert it to a string.
            if iscell(selectedVars)
                varOrder = cellfun(@string, selectedVars);
            else
                varOrder = string(selectedVars);
            end
            
            
            % If more than 1 variable is selected (so a 2D or more plot
            % can be done)
            if length(varOrder) > 1 && length(selectedGraphNames) >= 1
                
                % If too many variables are selected and are added to varOrder
                % then only select the first 5 (plot will only go as
                % high as the 5th dimension)
                if length(varOrder) > 5
                    varOrder = varOrder(1:5);
                end
                
                % Logic array contains the true false data of each
                % graph that is selected. Where 0 = not seleected and 1
                % = selectd. This function converts this into a
                % numbered array and removes any 0's so that it can be
                % used to index the combined data table. For example if
                % logicArry = [0 0 1 0 1 0] then it would be this .* [1
                % 2 3 4 5 6] = [0 0 3 0 5 0] and then zeros removed to
                % give [3 5] so the table is indexed at 3 and 5.
                logicArry = logicArry.*(1:1:length(logicArry));
                logicArry(logicArry==0) = [];
                logicArry = logicArry'; % Makes sure it is in the right direction
                
                % Uses this logical array to index the specfic data
                extractedData = app.variables(logicArry, varOrder);
                
                 
                % Plots a 2D graph when the number of columns in
                % extracted data = 2;
                if size(extractedData,2) == 2
                    
                    % 2D plot of the selected points
                    scatter(app.GraphAxes, extractedData{:,1},extractedData{:,2}, app.defaultSize , app.defaultColor, 'filled');
                    
                    % As extractedData is a table it selects the VariableNames
                    % as the x and y label.
                    xlabel(app.GraphAxes, extractedData.Properties.VariableNames(1));
                    ylabel(app.GraphAxes, extractedData.Properties.VariableNames(2));
                    
                    % If debug mode is on, display the text
                    if app.ToggledebugCheckBox.Value == 1
                        text(app.GraphAxes, extractedData{:,1},extractedData{:,2}, '  ' + string(logicArry))
                    end
                    
                    % Turn grids on by defult (get switched off later if
                    % it has been toggled so, for a 2d graph the grids are
                    % off by default)
                    app.GraphAxes.XGrid = 'on';
                    app.GraphAxes.YGrid = 'on';
                    
                    % If video option has been selected
                    if app.vid == true
                        clear F % Clears the Frames if it exists
                        % Make the direcotry for the images of the video to
                        % be stored (if it has not already)
                        mkdir(app.vidImagesFile)
                        
                        % Creates a new figure to film with an axis in it
                        newFig = figure;
                        newGraph = axes(newFig);
                        
                        % Gets the current size of the graph
                        xsize = app.GraphAxes.XLim;
                        ysize = app.GraphAxes.YLim;
                        
                        % Clear graph in the new figure
                        cla(newGraph,'reset')
                        
                        % Sets the sizes
                        newGraph.XLim = xsize;
                        newGraph.YLim = ysize;
                        % Sets the labels
                        xlabel(newGraph, extractedData.Properties.VariableNames(1));
                        ylabel(newGraph, extractedData.Properties.VariableNames(2));
                        
                        % if grid off is not selected then activate these
                        % grids.
                        if app.gridOff == false
                            newGraph.XGrid = 'on';
                            newGraph.YGrid = 'on';
                        end
                        
                        hold(newGraph, "on")
                        % Loops through each data point and plots it. Can do
                        % this all in one go but this allows it to work with
                        % video capture.
                        for point = 1:size(extractedData,1)
                            %Plot the point
                            scatter(newGraph, extractedData{point,1},extractedData{point,2}, app.defaultSize , app.defaultColor, 'filled')
                            % If debug mode is on, display the text
                            if app.ToggledebugCheckBox.Value == 1
                                text(newGraph, extractedData{point,1}, extractedData{point,2}, '  ' + string(logicArry(point)))
                            end
                            
                            % Creates image name, saves it as a .jpeg with
                            % a good resolution, re-reads and then converts
                            % to a frame ready to be processed later.
                            fname = [app.vidImagesFile 'image' num2str(point)]; % full name of image
                            print(newFig,'-djpeg','-r200',fname)     % save image with '-r200' resolution
                            I = imread([fname '.jpg']);       % read saved image
                            F(point) = im2frame(I);              % convert image to frame
                            
                        end
                        hold(newGraph, "off")

                    end
                    
                    
                % Plots a 3D graph when the number of columns in
                % extracted data = 3;    
                elseif size(extractedData,2) == 3
                    
                    % 3D scatter graph
                    scatter3(app.GraphAxes, extractedData{:,1}, extractedData{:,2}, extractedData{:,3}, app.defaultSize, app.defaultColor, 'filled')
                    
                    % Add to the same axis the lines that go down to
                    % the xy plane
                    hold (app.GraphAxes, 'on')
                    
                    % Set upper and lower bound of the z axis so that the
                    % lines drawn don't always go to z = 0 and show loads
                    % of blank space.
                    lowerBound = floor(min(extractedData{:,3})/5)*5;
                    
                    % loop through each element and add the line that
                    % goes down to the xy plane
                    for x = 1:size(extractedData,1)
                        plot3(app.GraphAxes, [extractedData{x,1} extractedData{x,1}], [extractedData{x,2} extractedData{x,2}], [lowerBound, extractedData{x,3}], 'Color', app.defaultColor, 'LineStyle', app.lineStyle)
                    end
                    
                    % Stop appending to the same axis
                    hold (app.GraphAxes, 'off')
                    
                    % Add the graph labels based on the table col name
                    % values
                    xlabel(app.GraphAxes, extractedData.Properties.VariableNames(1));
                    ylabel(app.GraphAxes, extractedData.Properties.VariableNames(2));
                    zlabel(app.GraphAxes, extractedData.Properties.VariableNames(3));
                    
                    % Get the current Z axis UB limit and then set the new
                    % Z axis limits to minimise whitespace.
                    zaxis = zlim(app.GraphAxes);
                    zlim(app.GraphAxes, [lowerBound, zaxis(2)])
                    
                    % if debug mode is on, then plot the numbers next
                    % each point for easier identifcation
                    if app.ToggledebugCheckBox.Value == 1
                        text(app.GraphAxes, extractedData{:,1},extractedData{:,2}, extractedData{:,3}, '  ' + string(logicArry))
                    end
                    
                    % If video option has been selected
                    if app.vid == true
                        clear F % Clears the Frames if it exists
                        % Make the direcotry for the images of the video to
                        % be stored (if it has not already)
                        mkdir(app.vidImagesFile)
                        
                        % Creates a new figure to film with an axis in it
                        newFig = figure;
                        newGraph = axes(newFig);
                        
                        % Gets the current size of the graph
                        xsize = app.GraphAxes.XLim;
                        ysize = app.GraphAxes.YLim;
                        zsize = app.GraphAxes.ZLim;
                        
                        % Clear graph in the new figure
                        cla(newGraph,'reset')
                        
                        % Sets the sizes
                        newGraph.XLim = xsize;
                        newGraph.YLim = ysize;
                        newGraph.ZLim = zsize;
                        
                        % Sets the labels
                        xlabel(newGraph, extractedData.Properties.VariableNames(1));
                        ylabel(newGraph, extractedData.Properties.VariableNames(2));
                        zlabel(newGraph, extractedData.Properties.VariableNames(3));
                        
                        %For some reason these actions set the graph state
                        %to 2D, so make sure it is 3D.
                        view(newGraph,3)
                        
                        % Switch on by default to begin with
                        newGraph.Box = "on";
                        
                        % if grid off is not selected then activate these
                        % grids.
                        if app.gridOff == false
                            newGraph.XGrid = 'on';
                            newGraph.YGrid = 'on';
                            newGraph.ZGrid = 'on';
                            newGraph.Box = "off";
                        end
                        
                        hold(newGraph, "on")
                        % Loops through each data point and plots it. Can do
                        % this all in one go but this allows it to work with
                        % video capture.
                        for point = 1:size(extractedData,1)
                            
                            % Plot the point
                            scatter3(newGraph, extractedData{point,1},extractedData{point,2}, extractedData{point,3}, app.defaultSize , app.defaultColor, 'filled')
                            % Plot the line
                            plot3(newGraph, [extractedData{point,1} extractedData{point,1}], [extractedData{point,2} extractedData{point,2}], [lowerBound, extractedData{point,3}], 'Color', app.defaultColor, 'LineStyle', app.lineStyle)
                            % If debug mode is on, display the text
                            if app.ToggledebugCheckBox.Value == 1
                                text(newGraph, extractedData{point,1},extractedData{point,2}, extractedData{point,3}, '  ' + string(logicArry(point)))
                            end
                            
                            % Creates image name, saves it as a .jpeg with
                            % a good resolution, re-reads and then converts
                            % to a frame ready to be processed later.
                            fname = [app.vidImagesFile 'image' num2str(point)]; % full name of image
                            print(newFig,'-djpeg','-r200',fname)     % save image with '-r200' resolution
                            I = imread([fname '.jpg']);       % read saved image
                            F(point) = im2frame(I);              % convert image to frame
                        end
                        hold(newGraph, "off")
                    end
                
                % Plots a 4D graph when the number of columns in
                % extracted data = 4, using color as the 4th dimension 
                elseif size(extractedData,2) == 4
                    % 4D scatter graph where the colour is the 4th
                    % dimenson
                    scatter3(app.GraphAxes, extractedData{:,1}, extractedData{:,2}, extractedData{:,3}, app.defaultSize, extractedData{:,4}, "filled")
                    
                    % Set the colur scheme to app.colorScheme
                    cmap = colormap(app.GraphAxes,app.colorScheme);
                    % If the invert option is selected it inverts the
                    % colour scheme.
                    if app.InvertToggle.Value == 0
                        cmap = colormap(app.GraphAxes, flipud(cmap));
                    end
                    
                    % Add the colour bar
                    cbar = colorbar(app.GraphAxes);
                    
                    % This sets up the colours for the dotted lines so
                    % that they match the scattered point colours. If
                    % all the values in extracted method are the same,
                    % then set it to the first color. If if is a
                    % difference between the values, use the max and
                    % min values to generate c, which is a matrix that
                    % spaces out the colours uniformly and in realtion
                    % to the colours of the scatter points.
                    if nnz(diff(extractedData{:,4})) == 0
                        c = ones(size(cmap,1));
                    else
                        c = round(1+(size(cmap,1)-1)*(extractedData{:,4} - min(extractedData{:,4}))/(max(extractedData{:,4})-min(extractedData{:,4})));
                    end
                    
                    % Add to the same axis the lines that go down to
                    % the xy plane
                    hold(app.GraphAxes, 'on');
                    
                    % Set upper and lower bound of the z axis so that the
                    % lines drawn don't always go to z = 0 and show loads
                    % of blank space.
                    lowerBound = floor(min(extractedData{:,3})/5)*5;
                    
                    % Based on the index/ color psotion (c) plots a
                    % dotted line that goes down from the point to the
                    % xy plane
                    for x = 1:size(extractedData,1)
                        plot3(app.GraphAxes, [extractedData{x,1} extractedData{x,1}], [extractedData{x,2} extractedData{x,2}], [lowerBound extractedData{x,3}], "Color",cmap(c(x),:), 'LineStyle', app.lineStyle)
                    end
                    
                    % Stop appending to the same axis
                    hold (app.GraphAxes, 'off');
                    
                    % Add the graph labels based on the table col name
                    % values
                    xlabel(app.GraphAxes, extractedData.Properties.VariableNames(1));
                    ylabel(app.GraphAxes, extractedData.Properties.VariableNames(2));
                    zlabel(app.GraphAxes, extractedData.Properties.VariableNames(3));
                    
                    % Get the current Z axis UB limit and then set the new
                    % Z axis limits to minimise whitespace.
                    zaxis = zlim(app.GraphAxes);
                    zlim(app.GraphAxes, [lowerBound, zaxis(2)])
                    
                    % Add title to colour bar
                    title(cbar, extractedData.Properties.VariableNames(4), "FontSize",10, "FontWeight","bold")
                    % Puts in a title so that the spacing at the top of
                    % the graph includes the title above the cbar
                    title(app.GraphAxes, " ", "FontSize",20, "FontWeight","bold")
                    cbar.FontSize = 10; %Makes font of cbar increments larger

                    
                    % if debug mode is on, then plot the numbers next
                    % each point for easier identifcation
                    if app.ToggledebugCheckBox.Value == 1
                        
                        % Loops through each point and adds text next
                        % to it that includes the number and var4 data
                        for graph = 1:size(extractedData,1)
                            text(app.GraphAxes, extractedData{graph,1},extractedData{graph,2}, extractedData{graph,3}, " " + string(logicArry(graph)) + ", " + string(extractedData{graph,4}))
                        end

                    end
                    
                    % If video option has been selected
                    if app.vid == true
                        
                        clear F % Clears the Frames if it exists
                        % Make the direcotry for the images of the video to
                        % be stored (if it has not already)
                        mkdir(app.vidImagesFile)
                        
                        % Creates a new figure to film with an axis in it
                        newFig = figure;
                        newGraph = axes(newFig);
                        
                        % Gets the current size of the graph
                        xsize = app.GraphAxes.XLim;
                        ysize = app.GraphAxes.YLim;
                        zsize = app.GraphAxes.ZLim;
                        
                        % Clear graph in the new figure
                        cla(newGraph,'reset')
                        
                        % Sets the sizes
                        newGraph.XLim = xsize;
                        newGraph.YLim = ysize;
                        newGraph.ZLim = zsize;
                        
                        % Sets the labels
                        xlabel(newGraph, extractedData.Properties.VariableNames(1));
                        ylabel(newGraph, extractedData.Properties.VariableNames(2));
                        zlabel(newGraph, extractedData.Properties.VariableNames(3));
                        
                        % Set the colur scheme to app.colorScheme
                        cmapVid = colormap(newGraph,app.colorScheme);
                        
                        % If the invert option is selected it inverts the
                        % colour scheme.
                        if app.InvertToggle.Value == 0
                            cmapVid = colormap(newGraph, flipud(cmapVid));
                        end
                        
                        % Add the colour bar
                        cbarVid = colorbar(newGraph);
                        
                        % Add title to colour bar
                        title(cbarVid, extractedData.Properties.VariableNames(4), "FontSize",10, "FontWeight","bold")
                        % Puts in a title so that the spacing at the top of
                        % the graph includes the title above the cbar
                        title(newGraph, " ", "FontSize",20, "FontWeight","bold")
                        cbar.FontSize = 10; %Makes font of cbar increments larger
                        
                        %For some reason these actions set the graph state
                        %to 2D, so make sure it is 3D.
                        view(newGraph,3)
                        
                        % Switch on by default to begin with
                        newGraph.Box = "on";
                        
                        % if grid off is not selected then activate these
                        % grids.
                        if app.gridOff == false
                            newGraph.XGrid = 'on';
                            newGraph.YGrid = 'on';
                            newGraph.ZGrid = 'on';
                            newGraph.Box = "off";
                        end 
                        
                        hold(newGraph, "on")
                        
                        % Plot all the points initally really tiny to
                        % correctly configure the colour bar
                        for x = 1:size(extractedData,1)
                            scatter3(newGraph,extractedData{x,1},extractedData{x,2},extractedData{x,3},0.001, extractedData{x,4}, "filled");
                        end
                        
                        % Loops through each data point and plots it. Can do
                        % this all in one go but this allows it to work with
                        % video capture.
                        for point = 1:size(extractedData,1)
                            
                            %Plot the point
                            scatter3(newGraph, extractedData{point,1}, extractedData{point,2}, extractedData{point,3}, app.defaultSize, extractedData{point,4}, "filled")
                            %Plot the line
                            plot3(newGraph, [extractedData{point,1} extractedData{point,1}], [extractedData{point,2} extractedData{point,2}], [lowerBound extractedData{point,3}], "Color",cmapVid(c(point),:), 'LineStyle', app.lineStyle)
                            % If debug mode is on, display the text
                            if app.ToggledebugCheckBox.Value == 1
                                text(newGraph, extractedData{point,1},extractedData{point,2}, extractedData{point,3}, " " + string(logicArry(point)) + ", " + string(extractedData{point,4}))
                            end
                            
                            % Creates image name, saves it as a .jpeg with
                            % a good resolution, re-reads and then converts
                            % to a frame ready to be processed later.
                            fname = [app.vidImagesFile 'image' num2str(point)]; % full name of image
                            print(newFig,'-djpeg','-r200',fname)     % save image with '-r200' resolution
                            I = imread([fname '.jpg']);       % read saved image
                            F(point) = im2frame(I);              % convert image to frame
                        end
                        hold(newGraph, "off")
                    end
                
                % Plots a 5D graph when the number of columns in
                % extracted data = 5, using color as the 4th 
                % dimension and size of the dot as the 5th dimension.
                elseif size(extractedData,2) == 5
                    % Change these to vary the maximum and minimim dot
                    % sizes
                    maxDotSize = 100;
                    minDotSize = 5;
                    
                    % Scale the data so that the size is bewteen the
                    % max and min dot size, for when it is plotted on
                    % the graph.
                    scaledData = rescale(extractedData{:,5}, minDotSize, maxDotSize);
                    
                    % Generates 5 uniformly spaced marker sizes between
                    % the min and max dot size specified
                    ledgMarkerSize = linspace(minDotSize, maxDotSize, 5);
                    markersActualNumb = rescale(ledgMarkerSize, min(extractedData{:,5}), max(extractedData{:,5}));
                    
                    % Add to the same axis the lines that go down to
                    % the xy plane
                    hold (app.GraphAxes, 'on');
                    
                    % The loop starts to create the figger that
                    % displays the dot size. It works by plotting 5
                    % points of varying marker size (plot3 has to be
                    % used instead of scatter3 as only this changes the
                    % dot size in the legend for some reason) and
                    % setting their visabilty to 0. Then each each
                    % number that corrisponds to the 5 uniformly
                    % distrubuted sizes is set to a cell which then
                    % later is used to called the legend function
                    % (which only shows these first 5 dots). This has
                    % to be done before the scatter function as it
                    % needs to be the FIRST 5 dots.
                    
                    for ind = 1:numel(ledgMarkerSize)
                       % Generate the plots and save them in figplots 
                       % array. Set them at (0,0,0) and set the marker
                       % size to the square root of the ledgMarkerSize
                       % (for some reason this works well for size
                       % comparson, not sure how acurate it is).
                       figplots(ind) = plot3(app.GraphAxes,0,0,0,'bo','markersize',round(sqrt(ledgMarkerSize(ind)),1),'MarkerFaceColor','blue', "MarkerEdgeColor","blue");
                       set(figplots(ind),'visible','off') % Make them invisable
                       
                       % Adds each number (acutal number not the marker
                       % size number) so that it is displayed as the
                       % label when the legend function is called later
                       legentry{ind} = num2str(round(markersActualNumb(ind),1));
                    end
                    
                    % 5D scatter graph where the colour is the 4th
                    % dimenson and size of the dot is the 5th dimension
                    scatter3(app.GraphAxes, extractedData{:,1}, extractedData{:,2}, extractedData{:,3}, scaledData, extractedData{:,4}, "filled")
                    
                    % Stop appending to the same axis
                    hold (app.GraphAxes, 'off');
                    
                    % Set the colur scheme to app.colorScheme
                    cmap = colormap(app.GraphAxes,app.colorScheme);
                    % If the invert option is selected it inverts the
                    % colour scheme.
                    if app.InvertToggle.Value == 0
                        cmap = colormap(app.GraphAxes, flipud(cmap));
                    end
                    
                    % Add the colour bar
                    cbar = colorbar(app.GraphAxes);
                    
                    % This sets up the colours for the dotted lines so
                    % that they match the scattered point colours. If
                    % all the values in extracted method are the same,
                    % then set it to the first color. If if is a
                    % difference between the values, use the max and
                    % min values to generate c, which is a matrix that
                    % spaces out the colours uniformly and in realtion
                    % to the colours of the scatter points.
                    if nnz(diff(extractedData{:,4})) == 0
                        c = ones(size(cmap,1));
                    else
                        c = round(1+(size(cmap,1)-1)*(extractedData{:,4} - min(extractedData{:,4}))/(max(extractedData{:,4})-min(extractedData{:,4})));
                    end

                    % Add to the same axis the lines that go down to
                    % the xy plane
                    hold (app.GraphAxes, 'on');
                    
                    % Set upper and lower bound of the z axis so that the
                    % lines drawn don't always go to z = 0 and show loads
                    % of blank space.
                    lowerBound = floor(min(extractedData{:,3})/5)*5;
                    
                    % Based on the index/ color psotion (c) plots a
                    % dotted line that goes down from the point to the
                    % xy plane
                    for x = 1:size(extractedData,1)
                        plot3(app.GraphAxes, [extractedData{x,1} extractedData{x,1}], [extractedData{x,2} extractedData{x,2}], [lowerBound extractedData{x,3}], "Color",cmap(c(x),:), 'LineStyle', app.lineStyle)
                    end
                    
                    % Stop appending to the same axis
                    hold (app.GraphAxes, 'off');
                    
                    % Add the graph labels based on the table col name
                    % values
                    xlabel(app.GraphAxes, extractedData.Properties.VariableNames(1));
                    ylabel(app.GraphAxes, extractedData.Properties.VariableNames(2));
                    zlabel(app.GraphAxes, extractedData.Properties.VariableNames(3));
                    
                    % Add title to colour bar
                    title(cbar, extractedData.Properties.VariableNames(4), "FontSize",10, "FontWeight","bold")
                    
                    % Puts in a title so that the spacing at the top of
                    % the graph includes the title above the cbar
                    title(app.GraphAxes, " ", "FontSize",20, "FontWeight","bold")
                    cbar.FontSize = 10; %Makes font of cbar increments larger
                    
                    % Creat the legend at the end after all points have
                    % been added as we only want the first 5 points
                    % (the dummy invisable ones stored in figplots)
                    leg = legend(app.GraphAxes, legentry);
                    leg.Location = 'eastoutside'; %Display next to the colour bar
                    leg.FontSize = 10; % Make font the same size as the color bar
                    % Gives the legend a title
                    title(leg, extractedData.Properties.VariableNames(5),"FontSize",10, "FontWeight","bold");
                    
                    % Get the current Z axis UB limit and then set the new
                    % Z axis limits to minimise whitespace.
                    zaxis = zlim(app.GraphAxes);
                    zlim(app.GraphAxes, [lowerBound, zaxis(2)])
                    
                    %For some reason these actions set the graph state
                    %to 2D, so make sure it is 3D.
                    view(app.GraphAxes,3)

                    % if debug mode is on, then plot the numbers next
                    % each point for easier identifcation
                    if app.ToggledebugCheckBox.Value == 1
                        
                        % Loops through each point and adds text next
                        % to it that includes the number, var4 and 
                        % var5 data data
                        for graph = 1:size(extractedData,1)
                            text(app.GraphAxes, extractedData{graph,1},extractedData{graph,2}, extractedData{graph,3}, " " + string(logicArry(graph)) + ", " + string(extractedData{graph,4}) + ", " + string(extractedData{graph,5}))
                        end
                    end
                    
                    % If video option has been selected
                    if app.vid == true
                        clear F % Clears the Frames if it exists
                        % Make the direcotry for the images of the video to
                        % be stored (if it has not already)
                        mkdir(app.vidImagesFile)
                        
                        % Creates a new figure to film with an axis in it
                        newFig = figure;
                        newGraph = axes(newFig);
                        
                        % Gets the current size of the graph
                        xsize = app.GraphAxes.XLim;
                        ysize = app.GraphAxes.YLim;
                        zsize = app.GraphAxes.ZLim;
                        
                        % Clear graph in the new figure
                        cla(newGraph,'reset')
                        
                        % Sets the sizes
                        newGraph.XLim = xsize;
                        newGraph.YLim = ysize;
                        newGraph.ZLim = zsize;
                        
                        % Sets the labels
                        xlabel(newGraph, extractedData.Properties.VariableNames(1));
                        ylabel(newGraph, extractedData.Properties.VariableNames(2));
                        zlabel(newGraph, extractedData.Properties.VariableNames(3));
                        
                        % Set the colur scheme to app.colorScheme
                        cmapVid = colormap(newGraph,app.colorScheme);
                        % If the invert option is selected it inverts the
                        % colour scheme.
                        if app.InvertToggle.Value == 0
                            cmapVid = colormap(newGraph, flipud(cmapVid));
                        end
                        
                        % Add the colour bar
                        cbarVid = colorbar(newGraph);
                        
                        % Add title to colour bar
                        title(cbarVid, extractedData.Properties.VariableNames(4), "FontSize",10, "FontWeight","bold")
                        % Puts in a title so that the spacing at the top of
                        % the graph includes the title above the cbar
                        title(newGraph, " ", "FontSize",20, "FontWeight","bold")
                        cbar.FontSize = 10; %Makes font of cbar increments larger
                        
                        %For some reason these actions set the graph state
                        %to 2D, so make sure it is 3D.
                        view(newGraph,3)
                        
                        % Switch on by default to begin with
                        newGraph.Box = "on";
                        
                        % if grid off is not selected then activate these
                        % grids.
                        if app.gridOff == false
                            newGraph.XGrid = 'on';
                            newGraph.YGrid = 'on';
                            newGraph.ZGrid = 'on';
                            newGraph.Box = "off";
                        end 

                        hold(newGraph, "on")
                        
                        % Same code as before, creates the legend markers
                        % and makes the points invisable so they cant be
                        % seen
                        for ind = 1:numel(ledgMarkerSize)
                            % Generate the plots and save them in figplots 
                            % array. Set them at (0,0,0) and set the marker
                            % size to the square root of the ledgMarkerSize
                            % (for some reason this works well for size
                            % comparson, not sure how acurate it is).
                            figplotsVid(ind) = plot3(newGraph,0,0,0,'bo','markersize',round(sqrt(ledgMarkerSize(ind)),1),'MarkerFaceColor','blue', "MarkerEdgeColor","blue");
                            set(figplotsVid(ind),'visible','off') % Make them invisable
                        end
                        
                        % Create the legend at the end after all points have
                        % been added as we only want the first 5 points
                        % (the dummy invisable ones stored in figplots)
                        legVid = legend(newGraph, legentry);
                        legVid.Location = 'eastoutside'; %Display next to the colour bar
                        legVid.FontSize = 10; % Make font the same size as the color bar
                        % Gives the legend a title
                        title(legVid, extractedData.Properties.VariableNames(5),"FontSize",10, "FontWeight","bold");
                        % Stop legend from adding more things to it
                        % automatically
                        set(legVid,'AutoUpdate','off');
                        
                        % Plot all the points initally really tiny to
                        % correctly configure the colour bar
                        for x = 1:size(extractedData,1)
                            scatter3(newGraph,extractedData{x,1},extractedData{x,2},extractedData{x,3},0.001, extractedData{x,4}, "filled");
                        end
                        
                        % Loops through each data point and plots it. Can do
                        % this all in one go but this allows it to work with
                        % video capture.
                        for point = 1:size(extractedData,1)
                            
                            %Plot the point
                            scatter3(newGraph, extractedData{point,1}, extractedData{point,2}, extractedData{point,3}, scaledData(point), extractedData{point,4}, "filled")
                            %Plot the line
                            plot3(newGraph, [extractedData{point,1} extractedData{point,1}], [extractedData{point,2} extractedData{point,2}], [lowerBound extractedData{point,3}], "Color",cmapVid(c(point),:), 'LineStyle', app.lineStyle)
                            % If debug mode is on, display the text
                            if app.ToggledebugCheckBox.Value == 1
                                text(newGraph, extractedData{point,1},extractedData{point,2}, extractedData{point,3}, " " + string(logicArry(point)) + ", " + string(extractedData{point,4}))
                            end
                            
                            % Creates image name, saves it as a .jpeg with
                            % a good resolution, re-reads and then converts
                            % to a frame ready to be processed later.
                            fname = [app.vidImagesFile 'image' num2str(point)]; % full name of image
                            print(newFig,'-djpeg','-r200',fname)     % save image with '-r200' resolution
                            I = imread([fname '.jpg']);       % read saved image
                            F(point) = im2frame(I);              % convert image to frame
                        end
                        hold(newGraph, "off")
                    end
                    
                end
                
                % Removes the grid lines but keeps the box
                if app.gridOff == 1
                    
                    %Box only on if dimenson is > 2
                    if size(extractedData,2) > 2
                        app.GraphAxes.Box = "on";
                    end
                    
                    app.GraphAxes.XGrid = 'off';
                    app.GraphAxes.YGrid = 'off';
                    app.GraphAxes.ZGrid = 'off';
                else
                    app.GraphAxes.XGrid = 'on';
                    app.GraphAxes.YGrid = 'on';
                    app.GraphAxes.ZGrid = 'on';
                end
                
                if app.vid == true
                    
                    % create the video writer with 2 fps, Uncompressed AVI
                    % prevents image quality from being lost
                    writerObj = VideoWriter('myVideo.avi', 'Uncompressed AVI');
                    writerObj.FrameRate = app.fps;
                    % set the seconds per image
                    % open the video writer
                    open(writerObj);
                    % write the frames to the video
                    for i=1:length(F)
                        % convert the image to a frame
                        frame = F(i) ;    
                        writeVideo(writerObj, frame);
                    end
                    % close the writer object
                    close(writerObj);
                    
                    app.vid = false;
                    
                end
                
            end
       end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            % Load in custom made color map. First create property at the
            % start with the desired name, load it in and make sure it is
            % NOT a structure.
            app.Blue2Red = load("Blue2Red.mat", "Blue2Red");
            app.Blue2Red = app.Blue2Red.Blue2Red; %Convert from struct to array
            
            % All avaiable types of colour maps. Can add more to end if
            % adding more custom palletes
            app.ColourpalletDropDown.Items = ["parula", "hsv", "hot", ...
            	"cool", "spring", "summer", "autumn", "winter", ...
                "gray", "bone", "copper", "jet", "Blue2Red"];
            % Each of the pallets points to the actual varaible containing
            % the colours. Again add to the end if you want a custom one.
            % Must be in same order as above.
            app.ColourLinked = {parula, hsv, hot, ...
            	cool, spring, summer, autumn, winter, ...
                gray, bone, copper, jet, app.Blue2Red};
            
            % Predefined matlab colours
            app.DefaultcolorDropDown.Items = ["yellow", "magenta", "cyan", "red", "green", "blue", "white", "black"];
            
            % Predefined line types
            app.StemstyleDropDown.Items = ["none","-","--",":","-."];
            
            % Set defaults (defined when colorScheme etc were made)
            app.ColourpalletDropDown.Value = "parula";
            app.DefaultcolorDropDown.Value = app.defaultColor;
            app.StemstyleDropDown.Value = app.lineStyle;
            
        end

        % Button pushed function: LoadfileButton
        function LoadfileButtonPushed(app, event)
            % Resets all the variables
            app.reset();
            
            % Opens the file explorer to allow the user to select an excel
            % file - only files containing '.xls' will be shown.
            [app.fileName, app.filePath] = uigetfile('*.xls*', 'Open Excel File');
            
            % Predefine error check
            errCheck = true;
            % Start the error checking loop
            while errCheck
                
                % If no file is selected
                if app.fileName == 0
                    app.Label.Text = "No file was selected";
                    break % End the error checking loop
                end
                
                % Gets the extension of the file
                [~,~,extension] = fileparts(app.fileName);
                % If the extension does not contain '.xls'
                if ~contains(extension, '.xls')
                    app.Label.Text = "File type must be of the form *.xls*";
                    break % End the error checking loop
                end
                
                % Try loading the file into a table format, and display
                % error if it cannot be loaded.
                try
                    % Load file into table format
                    app.variables = readtable(app.filePath + "\" + app.fileName);
                    app.Label.Text = app.fileName + " loaded!";
                    errCheck = false; % Set error check to false
                    break
                catch ME
                    app.Label.Text = "File failed to load";
                    break % End the error checking loop
                end
    
            end
         
            % If the file was sucessfully loaded (and err check was set to
            % false) then load the variables into the list boxes.
            if errCheck == false
                app.loadVariables()
            end
        end

        % Value changed function: ExperimentListBox
        function ExperimentListBoxValueChanged(app, event)
            % Any different variable selected in list box will update the
            % graph
            app.updateGraph();
        end

        % Value changed function: VariableListBox
        function VariableListBoxValueChanged(app, event)
            % Any different variable selected in list box will update the
            % graph
            app.updateGraph();
        end

        % Value changed function: ToggledebugCheckBox
        function ToggledebugCheckBoxValueChanged(app, event)
            % If the debug box is toggled then update the graph
            app.updateGraph();
        end

        % Value changed function: ColourpalletDropDown
        function ColourpalletDropDownValueChanged(app, event)
            % Converts the items to a string array
            names = cellfun(@string, app.ColourpalletDropDown.Items);
            % Finds the index of the item so that it can be used to point
            % to the linked colourmap
            index = find(strcmp(names, app.ColourpalletDropDown.Value));
            
            % Use the index to select the correct color map
            app.colorScheme  = app.ColourLinked(index);
            % Convert from cell to array
            app.colorScheme  = app.colorScheme{:,:};
            app.updateGraph();
        end

        % Value changed function: DefaultcolorDropDown
        function DefaultcolorDropDownValueChanged(app, event)
            app.defaultColor = string(app.DefaultcolorDropDown.Value);
            app.updateGraph();
        end

        % Value changed function: StemstyleDropDown
        function StemstyleDropDownValueChanged(app, event)
            app.lineStyle = string(app.StemstyleDropDown.Value);
            app.updateGraph();
        end

        % Value changed function: InvertToggle
        function InvertToggleValueChanged(app, event)
            app.updateGraph();
        end

        % Value changed function: SizeSlider
        function SizeSliderValueChanged(app, event)
            app.defaultSize  = app.SizeSlider.Value;
            app.updateGraph();
        end

        % Value changed function: GridoffCheckBox
        function GridoffCheckBoxValueChanged(app, event)
            app.gridOff = app.GridoffCheckBox.Value;
            app.updateGraph();            
        end

        % Button pushed function: VideoButton
        function VideoButtonPushed(app, event)
            app.vid = true;
            app.fps = app.FPSEditField.Value;
            app.updateGraph(); 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create DesignSpacePlotterUIFigure and hide until all components are created
            app.DesignSpacePlotterUIFigure = uifigure('Visible', 'off');
            app.DesignSpacePlotterUIFigure.Color = [0.9412 0.9412 0.9412];
            app.DesignSpacePlotterUIFigure.Position = [100 100 1048 623];
            app.DesignSpacePlotterUIFigure.Name = 'DesignSpacePlotter';
            app.DesignSpacePlotterUIFigure.Scrollable = 'on';

            % Create DataPanel
            app.DataPanel = uipanel(app.DesignSpacePlotterUIFigure);
            app.DataPanel.Title = 'Data';
            app.DataPanel.BackgroundColor = [0.8 0.8 0.8];
            app.DataPanel.FontWeight = 'bold';
            app.DataPanel.Position = [1 218 236 406];

            % Create ExperimentListBox
            app.ExperimentListBox = uilistbox(app.DataPanel);
            app.ExperimentListBox.Items = {};
            app.ExperimentListBox.Multiselect = 'on';
            app.ExperimentListBox.ValueChangedFcn = createCallbackFcn(app, @ExperimentListBoxValueChanged, true);
            app.ExperimentListBox.Position = [28 167 182 132];
            app.ExperimentListBox.Value = {};

            % Create ExperimentsLabel
            app.ExperimentsLabel = uilabel(app.DataPanel);
            app.ExperimentsLabel.HorizontalAlignment = 'center';
            app.ExperimentsLabel.Position = [38 299 164 22];
            app.ExperimentsLabel.Text = 'Experiments';

            % Create VariableListBox
            app.VariableListBox = uilistbox(app.DataPanel);
            app.VariableListBox.Items = {};
            app.VariableListBox.Multiselect = 'on';
            app.VariableListBox.ValueChangedFcn = createCallbackFcn(app, @VariableListBoxValueChanged, true);
            app.VariableListBox.Position = [29 14 182 132];
            app.VariableListBox.Value = {};

            % Create VariablesLabel
            app.VariablesLabel = uilabel(app.DataPanel);
            app.VariablesLabel.Position = [94 145 55 22];
            app.VariablesLabel.Text = 'Variables';

            % Create LoadfileButton
            app.LoadfileButton = uibutton(app.DataPanel, 'push');
            app.LoadfileButton.ButtonPushedFcn = createCallbackFcn(app, @LoadfileButtonPushed, true);
            app.LoadfileButton.Position = [68 360 100 22];
            app.LoadfileButton.Text = 'Load file';

            % Create Label
            app.Label = uilabel(app.DataPanel);
            app.Label.HorizontalAlignment = 'center';
            app.Label.Position = [1 323 235 39];
            app.Label.Text = '';

            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.DesignSpacePlotterUIFigure);
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.SettingsPanel.FontWeight = 'bold';
            app.SettingsPanel.Position = [1 1 236 218];

            % Create ColourpalletDropDownLabel
            app.ColourpalletDropDownLabel = uilabel(app.SettingsPanel);
            app.ColourpalletDropDownLabel.HorizontalAlignment = 'right';
            app.ColourpalletDropDownLabel.Position = [25 140 73 22];
            app.ColourpalletDropDownLabel.Text = 'Colour pallet';

            % Create ColourpalletDropDown
            app.ColourpalletDropDown = uidropdown(app.SettingsPanel);
            app.ColourpalletDropDown.ValueChangedFcn = createCallbackFcn(app, @ColourpalletDropDownValueChanged, true);
            app.ColourpalletDropDown.Position = [113 140 100 22];

            % Create DefaultcolorDropDownLabel
            app.DefaultcolorDropDownLabel = uilabel(app.SettingsPanel);
            app.DefaultcolorDropDownLabel.HorizontalAlignment = 'right';
            app.DefaultcolorDropDownLabel.Position = [25 173 73 22];
            app.DefaultcolorDropDownLabel.Text = 'Default color';

            % Create DefaultcolorDropDown
            app.DefaultcolorDropDown = uidropdown(app.SettingsPanel);
            app.DefaultcolorDropDown.ValueChangedFcn = createCallbackFcn(app, @DefaultcolorDropDownValueChanged, true);
            app.DefaultcolorDropDown.Position = [113 173 100 22];

            % Create StemstyleDropDownLabel
            app.StemstyleDropDownLabel = uilabel(app.SettingsPanel);
            app.StemstyleDropDownLabel.HorizontalAlignment = 'right';
            app.StemstyleDropDownLabel.Position = [36 109 62 22];
            app.StemstyleDropDownLabel.Text = 'Stem style';

            % Create StemstyleDropDown
            app.StemstyleDropDown = uidropdown(app.SettingsPanel);
            app.StemstyleDropDown.ValueChangedFcn = createCallbackFcn(app, @StemstyleDropDownValueChanged, true);
            app.StemstyleDropDown.Position = [113 109 100 22];

            % Create SizeSliderLabel
            app.SizeSliderLabel = uilabel(app.SettingsPanel);
            app.SizeSliderLabel.HorizontalAlignment = 'right';
            app.SizeSliderLabel.Position = [18 76 29 22];
            app.SizeSliderLabel.Text = 'Size';

            % Create SizeSlider
            app.SizeSlider = uislider(app.SettingsPanel);
            app.SizeSlider.Limits = [10 300];
            app.SizeSlider.MajorTicks = [];
            app.SizeSlider.MajorTickLabels = {''};
            app.SizeSlider.ValueChangedFcn = createCallbackFcn(app, @SizeSliderValueChanged, true);
            app.SizeSlider.MinorTicks = [];
            app.SizeSlider.Position = [61 87 150 3];
            app.SizeSlider.Value = 40;

            % Create ToggledebugCheckBox
            app.ToggledebugCheckBox = uicheckbox(app.SettingsPanel);
            app.ToggledebugCheckBox.ValueChangedFcn = createCallbackFcn(app, @ToggledebugCheckBoxValueChanged, true);
            app.ToggledebugCheckBox.Text = 'Debug mode';
            app.ToggledebugCheckBox.Position = [25 26 91 22];

            % Create InvertToggle
            app.InvertToggle = uicheckbox(app.SettingsPanel);
            app.InvertToggle.ValueChangedFcn = createCallbackFcn(app, @InvertToggleValueChanged, true);
            app.InvertToggle.Text = 'Invert colour';
            app.InvertToggle.Position = [129 51 88 22];

            % Create GridoffCheckBox
            app.GridoffCheckBox = uicheckbox(app.SettingsPanel);
            app.GridoffCheckBox.ValueChangedFcn = createCallbackFcn(app, @GridoffCheckBoxValueChanged, true);
            app.GridoffCheckBox.Text = 'Grid off';
            app.GridoffCheckBox.Position = [25 51 61 22];

            % Create VideoButton
            app.VideoButton = uibutton(app.SettingsPanel, 'push');
            app.VideoButton.ButtonPushedFcn = createCallbackFcn(app, @VideoButtonPushed, true);
            app.VideoButton.Position = [123 26 100 22];
            app.VideoButton.Text = 'Video';

            % Create FPSEditFieldLabel
            app.FPSEditFieldLabel = uilabel(app.SettingsPanel);
            app.FPSEditFieldLabel.HorizontalAlignment = 'right';
            app.FPSEditFieldLabel.Position = [135 1 29 22];
            app.FPSEditFieldLabel.Text = 'FPS';

            % Create FPSEditField
            app.FPSEditField = uieditfield(app.SettingsPanel, 'numeric');
            app.FPSEditField.HorizontalAlignment = 'center';
            app.FPSEditField.Position = [173 1 39 22];
            app.FPSEditField.Value = 2;

            % Create PlotPanel
            app.PlotPanel = uipanel(app.DesignSpacePlotterUIFigure);
            app.PlotPanel.Position = [236 2 813 622];

            % Create PlotLabel
            app.PlotLabel = uilabel(app.PlotPanel);
            app.PlotLabel.HorizontalAlignment = 'center';
            app.PlotLabel.FontSize = 24;
            app.PlotLabel.FontWeight = 'bold';
            app.PlotLabel.Position = [285 589 244 32];
            app.PlotLabel.Text = 'Plot';

            % Create GraphAxes
            app.GraphAxes = uiaxes(app.PlotPanel);
            xlabel(app.GraphAxes, 'X')
            ylabel(app.GraphAxes, 'Y')
            zlabel(app.GraphAxes, 'Z')
            app.GraphAxes.AmbientLightColor = [0.9412 0.9412 0.9412];
            app.GraphAxes.Color = [0.9412 0.9412 0.9412];
            app.GraphAxes.Position = [9 8 803 583];

            % Show the figure after all components are created
            app.DesignSpacePlotterUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = DesignSpace_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.DesignSpacePlotterUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.DesignSpacePlotterUIFigure)
        end
    end
end