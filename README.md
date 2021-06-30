App created by Thomas Dixon on 06/05/2021, in MATLAB 2020b

This app allows select and plot variables in up to 5 dimensions (x,y,z,colour and dot size) with figures automatically. 
Please enter data into an excel sheet in the format shown: titles of the variables in the first row and then data 
(all numbers) in the rows below. Make sure all the rows are filled with data. When the application is opened click 
the ‘load’ button and select the .xls file of choice. You can then change which experiments (relating to each row in 
the spreadsheet) and variables (relating to each column title) you would like to plot. To do this, select the items 
in the list box and either hold down control to select multiple individual items or shift to select multiple items in 
a row. The colour palette (colourmap for when the dimension is greater than three), default colour (when the number of 
dimensions is three or less) and line style (for when the dimension is greater than two) can also be modified.

Select debug mode to see which experiment belongs to which, as well as the non-xyz values when observing graphs in the 4th and 
5th dimension. You can also invert the colourmap, select the colour pallet (4th and 5th dimensons), select the colour (2nd and 
3rd dimensons), select the stem style (3rd, 4th and 5th dimensons) and turn the grid off. There is also an option to record a
'video' of your plot where it plots each point in order given the frames per second (FPS). For example if the FPS is 2, then
two points per second will be plotted in the video. Each frame is saved as an individual image in the 'VideoImages' file and
will be saved over each time a new plot is made. The program brings up a seperate figure to do this, which can be closed when 
it has finished.

Enjoy 😊
a