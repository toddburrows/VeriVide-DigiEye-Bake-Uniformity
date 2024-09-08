# VeriVide DigiEye Bake Uniformity
A project I completed on my 4 week summer placement with VeriVide Ltd. The project title is Bake Uniformity and it involves an image, that is taken with VeriVide's DigiEye technology, being processed and the level of which the baked good is cooked across the image is inspected producing several representations to show the uniformity and distribution of the bake. This technology and software can then be used to test how even the heating is of cooking appliances such as ovens, air fryers, microwaves or pressure cookers.

## Outcome

## The Assignment Abstract
There had been requests from customers of VeriVide Ltd for their DigiEye software to provide details about the colour uniformity of their baked goods. An automated solution that would describe the bake distribution across the baked good would provide the customer with a valuable insight into the quality of the current baking process. A solution that would be able to segment an image and group similar colour values together into regions in order to provide the customer with a description of the spatial breakdown of these regions in an easily digestable way meant that the customer would be able to focus on business-critical areas as opposed to having to annotate the image themselves, which was the current solution. Also a software based solution would ensure that the process was repeatable and eliminate the chance of human error.

## My Objectives
1) Read an image that has been taken with VeriVide's DigiEye technology and process the data in order to segment the image and calculate the level of bake for each region across the baked good.
2) Group similar colour values together using k-means clustering to section the baked good into 3 distinct groups - 'under', 'good' and 'over' cooked.
3) Describe the uniformity and distribution of the bake using a variety of easily digestable visual representations of the level of bake across the baked good.

## Method
### Data/Image Processing
Reading the image involved processing up to over 10 million pixels each with 3 channels, red, green and blue. The main problem occured from the sheer number of pixels, this caused the program to potentially take several days of processing, given that it does not crash in that time, to extract the data from a large high-quality image. At first my way around this was to use an extremely small cropped image of 22x24 pixels to check that the data was extracted correctly, but I knew that the program needed to be optimised as soon as possible as it currently was not practical. My first solution to this problem, with the input from my managers, was to alter the code so that the image was looped through in parallel utilising all of the cores of the processing unit within the comupter that the program was running on. This drastically brought down the run time of the program allowing a larger, but still cropped, image of 240x221 pixels to be processed in a reasonable time, but still with the largest of images taking over an hour. My final solution was to work out a way to eliminate the use of a nested loop and utilise in-built functions, or functions within public libraries to optimise the program so that a typical large high quality image as taken with VeriVide's DigiEye technology could be processed in a reasonable time. This was acheive with the use of the ['magick' package](https://CRAN.R-project.org/package=magick) and in-built matrix manipulation to produce a replica of the image as a matrix of rgb values in R.

### Image Segmentation and Calculating The Level Of Bake
My first job of image manipulation was to calculate the 'brownness' value for each pixel of the baked good. The brownness is a measure of the pixel's 'level of brown' which is calculated using the xyz values of each pixel from the CIE XYZ colour space, to obtain these values I had to convert each pixel's values from the CIE RGB colour space to the CIE XYZ colour space using the conversion function provided in the ['imager' package](https://cran.r-project.org/package=imager). To segment the baked good from its background I had to sift out the pixels that are not the cake by setting their brownness level to 0. For a baked good taken on VeriVide's blue background plate, the calculated brownness values for the blue plate are negative which are easy to sift out, for other objects I had to inspect their chroma from the CIE LCh colour space and eliminate those less than 12. This is because the baked good should have a large chroma due to the quality of its colour, as opposed to the low chroma of a silver cooling tray or black background. Although this did pose a problem for when inspecting a burnt piece of toast where the black bits of the toast were being sifted out, to combat this I created a toggle allowing the user to specify if they are inspecting toast or cake. The result of this was a replica of the image as a matrix of brownness values in R where only the brownness values of the baked good are greater than 0, and the part of the image that is not the baked good has brownness 0.

### Grouping Similar Colours Using K-means Clustering
I first set the brownness values of regions that are not on the baked good, which were set to 0, as NA (not applicable) to easily extract only the data of the baked good. Using this data I performed the k-means clustering algorithm with the in-built function in R to group similar brownness values into 3 distinct groups - 'under', 'good' and 'over' cooked. Using the lower and upper bounds of each group, returned by the k-means function, I set every pixel to its corresponding group with the pixels not on the baked good set to dummy group 0. This resulted in another replica of the image as a matrix where each cell is the group of the corresponding pixel.

### Index Map Visualisation
I created a visual representation of the grouping of the baked good by creating an index map of the image. For each group, 'under', 'good' and 'over' cooked I found the pixel on the image with the closest brownness value to the central value of the group, I then used the rgb colour value of this pixel to represent all pixels within this group. For pixels not on the baked good, I set the colour they should be represented with as white (#ffffff).

<img width="851" alt="smallfullcaketogether" src="https://github.com/user-attachments/assets/52c24f91-9a00-4e05-95c2-bc91201dd744">

An example of a cake and its corresponding index map visualisation.

<img width="755" alt="dragontogether" src="https://github.com/user-attachments/assets/a78f720f-0d7f-46b0-87f1-1b369d3dbd36">

An example of a biscuit and its corresponding index map visualisation.

## Representations
To accompany each of the below representations, I wrote an output to the user of a table representing the clusters and the percentage of the cake that falls in each cluster. An example of the output for the cake as shown above is,

<img width="468" alt="table" src="https://github.com/user-attachments/assets/8328f4f7-d7e9-418b-a532-e674b2b97157">

### Arrows
I first wrote an arrow representation, the idea was that there would be 3 arrows representing the 'under', 'good' and 'over' cooked regions. Each arrow would extend from the centre of the baked good to the centre of mass of their respective group (see appendix) and the width of the arrow would be proportional to the percentage of the baked good that lies in that group.

<img width="628" alt="arrows" src="https://github.com/user-attachments/assets/2c1d8ee5-6f62-49a5-9e4e-bd3f191385f3">

#### Advantages

#### Limitations and Improvements

## Appendix
