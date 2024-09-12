# VeriVide DigiEye Bake Uniformity
A project I completed on my 4 week summer placement with VeriVide Ltd. The project title is Bake Uniformity and it involves an image, that is taken with VeriVide's DigiEye technology, being processed and the level of which the baked good is cooked across the image is inspected producing several representations to show the uniformity and distribution of the bake. This technology and software can then be used to test how even the heating is of cooking appliances such as ovens, air fryers, microwaves or pressure cookers.

## Outcome

## The Assignment Abstract
There had been requests from customers of VeriVide Ltd for their DigiEye software to provide details about the colour uniformity of their baked goods. An automated solution that would describe the bake distribution across the baked good would provide the customer with a valuable insight into the quality of the current baking process. A solution that would be able to segment an image and group similar colour values together into regions in order to provide the customer with a description of the spatial breakdown of these regions in an easily digestable way meant that the customer would be able to focus on business-critical areas as opposed to having to annotate the image themselves, which was the current solution. Also a software based solution would ensure that the process was repeatable and eliminate the chance of human error.

## My Objectives
1) Read an image that has been taken with VeriVide's DigiEye technology and process the data in order to segment the image and calculate the level of bake for each region across the baked good.
2) Group similar colour values together using k-means clustering to section the baked good into 3 distinct groups - 'under', 'good' and 'over' cooked.
3) Describe the uniformity and distribution of the bake using a variety of easily digestable visual representations of the level of bake across the baked good.
4) Create a metric giving a single number to rate the uniformity of a bake, then test with real cakes baked by my collegues!

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

---

### Arrows
I first wrote an arrow representation, the idea was that there would be 3 arrows representing the 'under', 'good' and 'over' cooked regions. Each arrow would extend from the centre of the baked good to the centre of mass of their respective group (see appendix) and the width of the arrow would be proportional to the percentage of the baked good that lies in that group. 

<img width="628" alt="arrows" src="https://github.com/user-attachments/assets/2c1d8ee5-6f62-49a5-9e4e-bd3f191385f3">

This is acheived by first calculating the centre of the baked good by finding its centre of mass. I then ordered the regions by descending percentage of the baked good that lies in each group, this is so that the largest group and therefore the widest arrow is drawn first so that, similar to a clock face, the smaller arrows sit on top of the larger ones.
For each group 1-3, I calculated the centre of mass of each region, associated its respective colour (red - over, green - good, blue - under), calculated the length of the arrow (euclidean distance between centre of baked good and centre of mass of region) and calculated the arrow width which not only is proportional to the size of the baked good that lies in that group but is scaled by a scale factor related to the size of the baked good so the arrows are reasonably sized for every image. Finally I drew each arrow in its corresponding coloir using these calculated values, where I also scaled the arrow head length to be reasonably sized determined by the arrow length.

#### Advantages
The advantages I found with this representation was that it clearly shows to the user the centre of mass of each region, including how extreme this region is (i.e. how much this region is skewed over to one side of the baked good) by how long the arrow is and also portrays more information in a compact way with the arrow width being proportional to the percentage of the baked good that lies in that group. 

#### Limitations and Improvements
One of the limitations of this representation is that if one side of the cake is overcooked for example, and the opposite side is also overcooked, the centre of mass of the overcooked region would fall close to the centre implying a uniform bake of overcooked areas, failing to spot this patten of disuniformity. Also when a cake is uniform as desired, each arrow would have a small length as the centre of mass of each region would be close to the centre, this means that it is difficult to distinguish the arrows from each other or see them clearly as they are simply too small. 

An improvement that could be made is to use the visual centre of a region rather than the centre of mass of the region, this would not help in the example given above but would mean that for an overcooked region like the one for the cake above, the arrow would end within the crescent as opposed to its focal point.

---

### Bubbles
As an alternative to the arrow representation, I also wrote the bubble representation. Similar to the arrows, there would be 3 bubbles representing the 'under', 'good' and 'over' cooked regions. Each bubble would be centered at the centre of mass of their respective group (see appendix) and the radius of the bubble would be proportional to the percentage of the baked good that lies in that group.

<img width="699" alt="bubblestogether" src="https://github.com/user-attachments/assets/066aa736-e6cf-454a-beff-99409d6c0291">

Again, similar to the arrow representation the centre of the baked good is calculated by finding its centre of mass, the regions are ordered by descending percentage of the baked good that lies in each group so that the largest bubble is drawn first and the smaller bubbles would sit on top of it. For each group the centre of mass is calculated, colour associated and radius calculated. The radius is calculated by using the percentage of the baked good that lies in that group and is scaked by a scale factor related to the size of the baked good so the bubble sizes are appropriate for the image. Each bubble is then drawn with a cross in the centre, also scaled by the scale factor and the radius of the bubble that encloses it. A small dot at the centre of the baked good is also plotted.

#### Advantages
An advantage I found with this representation was that compared to the arrows, it was easier to distinguish the increase in the radius of a bubble than the increase in the width of an arrow, especially when an arrow width becomes thick and therefore has less precision of its position due to that group taking up a large portion of the baked good. At first I didnt implement the final line of adding a point at the centre of the baked good, but with addition of this in a later iteration I found that it helped as a reference to distinguish where the bubbles were positioned on the baked good.

#### Limitations and Improvements
I did find however that the bubbles are less intuative than the arrows, without explanation it is difficult to see what they are representing unlike the arrow which clearly point to an overcooked/undercooked/good region. Similar to the arrows, the use of a visual centre would better represent where the region the bubble is representing tends to lie.

---

### Polygons
The idea for this representation stemmed from an idea of the arrow representation but using rectangles and where instead of the width being proportional to the percentage of the baked good that lies in that group, the area is. This means that for a region with centre of mass far from the centre, the width of the rectangle could be smaller than the width of a rectangle representing a region with a smaller percentage of the baked good falling in that region but has a centre of mass closer to the centre of the baked good. The next iteration of this representation I included the use of squares, these would be used for when the rectangle representing the region would have a width > 0.75 x length. This is because when the width was large it was hard to tell the direction the rectangle is pointing in as when the width>length the rectangle would appear to almost point at right angles to the direction of the centre of mass. These squares would have area still equal to the area if it had been a rectangle, but is centered at the centre of mass point and is still orientated in the direction of the centre of mass point from the centre of the baked good. The last iteration then included the use of traingles used for when the 
width < 10 x length, this aided the representation because with a very thin rectangle it was hard to see it clearly on the image, but the use of a triangle that fanned out to the centre of mass point meant that the width of the traingle at the centre of mass point was double that of if it was represented by a rectangle making it more easily perceivable.

# INSERT IMAGE OF SMALLFULLCAKE.BMP WITH POLYGONS and DRAGON.BMP WITH POLYGONS

# EXPLAIN HOW IT WAS DONE

#### Advantages

#### Limitations and Improvements

---

## Overall Evaluation

## Appendix
