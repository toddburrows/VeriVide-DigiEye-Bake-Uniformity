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
The idea for this representation stemmed from an idea of the arrow representation but using rectangles and where instead of the width being proportional to the percentage of the baked good that lies in that group, the area is. This means that for a region with centre of mass far from the centre, the width of the rectangle could be smaller than the width of a rectangle representing a region with a smaller percentage of the baked good falling in that region but has a centre of mass closer to the centre of the baked good. The next iteration of this representation I included the use of squares, these would be used for when the rectangle representing the region would have a width > 0.75 x length. This is because when the width was large it was hard to tell the direction the rectangle is pointing in as when the width>length the rectangle would appear to almost point at right angles to the direction of the centre of mass. These squares would have area still equal to the area if it had been a rectangle, but is centered at the centre of mass point and is still orientated in the direction of the centre of mass point from the centre of the baked good. The last iteration then included the use of traingles used for when 10 x width < length, this aided the representation because with a very thin rectangle it was hard to see it clearly on the image, but the use of a triangle that fanned out to the centre of mass point meant that the width of the traingle at the centre of mass point was double that of if it was represented by a rectangle making it more easily perceivable.

<img width="643" alt="polygonstogether" src="https://github.com/user-attachments/assets/cc1f8681-8181-4ca0-9722-02a68a4222c1">

As before, the centre of the baked good and its area is found first. The regions are ordered so that when drawing the polygons the polygon with the largest area is drawn first. Then for each region, the associated colour is selected and the centre of mass for that region is calculated. First assuming that this region will be represented by a rectangle the rectangle length, i.e. the distance between the centre of the baked good and centre of mass of that region is calculated. The area of the rectangle is also calculated using the percentage of the baked good that falls in that region and is multiplied by a calculated scale factor so that the polygons are of reasonable size for the baked good inspected. The width of this rectangle is then calculated allowing the conditions above to be checked determining what polygon to use to represent each region.

1) In the case of a traingle - the triangle's area and height is the same as the rectangle's area and length and the base is twice the width of the rectangle's width. Using the trigonometry below the x and y increment from the centre of mass point to the two base vertices are calculated, allowing the calculation of these vertices.
2) In the case of a rectangle - the trigonometry below is used to calculate the x and y increment from the centre of the shorter sides to their endpoints (i.e. centre of mass point to upper 2 vertices, centre of baked good to lower 2 vertices), allowing the 4 vertices of the rectangle to be calculated.
3) In the case of a square - the square's area is equal to the rectangle's area, and its length/width is equal to the square root of this area. Using the trigonometry below the vertices of the square are calculated one by one for x and for y.

![IMG_0502](https://github.com/user-attachments/assets/ce0ba41a-e07d-4f40-ae6b-77eb185d2e52)

The polygons are then drawn with the alpha channel being set to one half so that the fill colour is translucent, a point at the centre of the baked good is also drawn.

#### Advantages
The main advantage I feel that this representation has over the previous is that as little as just the polygons used and their location for each region conveys a lot of information, with a quick glimpse; if there are 3 squares centered near the centre of the baked good then the bake is reasonably uniform, if there are two large rectangles and one square then the bake is not very uniform. In addition to this it still conveys the same information as in the arrow and bubble representation.

#### Limitations and Improvements
Where this representation is limited is in the ability to distinguish between the percentage of the pixels that fall into one region compared to another if they are represented by different polygons - it is difficult for one to tell which area is greater between the area of a square and the area of a triangle when their difference is not great. Again, the use of the visual centre as opposed to the centre of mass could give a more intuative end location/centre for each region's ploygon.

---

### Radial Sectors Graph
This representation deviates from inspecting the uniformity of the baked good only by the distribution of the pixels falling into the 3 seperate 'under', 'good' and 'over' cooked groups, instead for this representation we split the baked good into 8 sectors and inspect the brownness values of the pixels in each sector giving an average brownness in multiple regions around the baked good. This allows the user to see the uniformity of the bake by the level at which the baked good is cooked in different areas over its cross-section. The greater the average brownness of the sector, the greater the sector shaped bar's radius is (similar to a bar chart but circular). 

<img width="403" alt="Picture 1" src="https://github.com/user-attachments/assets/cb00bf9d-ee12-4096-a7e2-a571e7de4ead">

The centre of the baked good is found first, along with its area. We assume the baked good to be a circle for this representation so the radius of the baked good is the square root of its area. The radius is then checked to make sure that it does not exceed the dimensions of the image, if it does then the minimum distance between the centre and the edge of the image is taken to be the radius. A horizontal and vertical line with their centre being the centre of the baked good is drawn, with length equal to the diameter of the baked good, two positive and negative diagonal lines are drawn in this way too, an outer circle is also drawn. Then for each region, starting at the positive x axis moving anticlockwise the brownness for every pixel in the region is taken (see appendix) and the average of the sector is found (the first sector includes the centre point and the x axis and every subsequent sector includes the line that seperates it from the previous sector). The maxBrownness is set by the user, this decides the brownness at which the bar would reach the edge of the cake, if 'half' is given the maxBrownness is equal to the maximum brownness of a pixel on the baked good, if 'full' is given the sector with the greatest average brownness will take up its whole region. The sectors are then drawn with a greyscale where the lightest grey is given to the sector with the lowest average brownness.

#### Advantages
The advantage of this representation is the ability to inspect particular regions on the baked good to see if there is some sort of hotspots or coolspots in the heating device the user is using where the baked good is not as cooked/brown. Also by not splitting the baked good into just 3 groups there is the ability to compare the brownness more precisely between regions. 

#### Limitations and Improvements
The limitation though is that the use of a polar format limits the ability to inspect scales on the cartesian axis, for example if there is a horizontal hotspot across the centre of the baked good, this would go unnoticed under the radial sectors graph as each sector would increase in average brownness by a similar amount with sectors 8 and 1 and sectors 4 and 5 increasing slightly more due to their orientation but this would still be difficult to notice.

---

### Radial Regions Graph
This representation was created to offer a similar representation to the radial sectors graph above but for a baked good that is rectangular as opposed to circular. Instead the baked good is split into 9 rectangles in a 3x3 grid formation with each rectangle roughly equal height and equal width, the brownness values of the pixels in each region is then inspected to give an average brownness value for each region. The representation can then be displayed in 2 ways, either with central increasing squares or with rectangles similar to a bar chart. When represented with rectangles the greater the average brownness of the region the greater the height of the bar in each region. When represented with central increasing squares the greater the average brownness of the region the greater the radius of a square centered at the centre of the region is in each region.

<img width="527" alt="image" src="https://github.com/user-attachments/assets/2d417f6a-3aec-4cac-9e6f-56c2fbc61b3d">

Once again the centre of the baked good is found, including finding the maximum and minimum x and y values i.e. the border of the baked good. The length of the vertical lines is found with subtracting the minimum y position from the maximum, and the same with the horizontal line with the minimum and maximum x. The height and width are then divided by 3, and the remainders are found - with remainder 0 all heights/widths will be the same, with remainder 1 the bottom/right boxes will be 1 greater and with remainder 2 the middle and bottom/middle and right boxes will be 1 greater. The lines are then drawn and using these lines the brownness values of the pixels within each regions boundaries are found with an average brownness for that region calculated. The maxBrownness is set by the user, this decides the brownness at which the squares would fill their region, if 'half' is given the maxBrownness is equal to the maximum brownness of a pixel on the baked good, if 'full' is given the sector with the greatest average brownness will fill its region. Squares are then drawn from the centre of each region with their radius proportional to the percentage of the sample within that region, their colour is a greyscale with the lightest grey given to the region with the lowest brownness value and the transulency set to one half.

### Advantages
The advantages of this representation are that of the radial sectors graph but with a baked good that is rectangular. In addition though because of the use of a central 9th region there is the ability to notice a vertical, horizontal or diagonal scale unlike in the radial sectors graph. 

#### Limitations and Improvements
A limitation though is the difficulty in seeing the image underneath the representation, unlike the radial sectors graph which fans out to a certain radius, this representation occupies all areas of the baked good taking up different regions by differing amounts. Also an improvement that needs to be made is that the regions will unlikely be squares, but with the central increasing squares representation squares are being used to represent each region so if they grow to a certain size their length/width will exceed one of the dimensions.

---

## The Uniformity Rating
The uniformity rating is a measure I developed to give a single number rating the uniformity of a bake, it is calculated in two parts with the average taken to give the overall rating. The first rating is the arrow rating, used for measuring the distribution of the 'under', 'good' and 'over' cooked groups. The second rating is the graph rating, used for measuring the variance of the bake.

### The Arrow Rating
To calculate the arrow rating the arrow representation calculations are performed as normal, but without displaying the representation. First the distance between the endpoint of the under cooked arrow and the endpoint of the over cooked arrow is calculated, this distance is divided by twice the radius of the baked good (where the radius is the radius of the baked good itself or the minimum distance between the centre of the baked good and the edge of the image) to give a percentage of the baked good it takes up. This is subtracted from 1 to give the first part of the rating. The second part of the rating is the distance between the centre of the baked good and the endpoint of the good cooked arrow divided by the above radius of the baked good an subtracted from 1. The average of these two ratings gives the arrow rating.

### The Graph Rating
To calculate the graph rating either the radial sectors graph representation or the radius regions graph representation calculations are performed as normal, but without displaying the representation, which one is determined by the shape of the baked good which is given as a parameter. The brownness of the sector/region with the greatest average brownness value is taken and the brownness of the sector/region with the lowest average brownness value is taken and the percentage difference is calculated but divided by 100 for decimal difference, then subtracted from 1 to give the graph rating.

## Overall Evaluation
My overall evaluation is that strongest of the first 3 group focussed representations is the polygon representation, this representation conveys lots of information in one go, is visually intuative and easy to use to spot problems with uniformity. With a glimpse it is easy to see the amount of the baked good falling into each region and also if there is any region that is densely populated in a particular direction. The use of different polygons allows a target to be set of all 3 groups being represented by squares close to the centre of the baked good, as this will be a uniform cake.

I feel that both the radial sectors and radial regions graphs are excellent for baked goods with their respective shape (circular or rectangular), they allow the user to see the bake of the baked good across the regions spotting any hotspots or scales in a particular direction. But on their own these graphs can fail to detect some disuniformity as explained in their limitations.

In light of both of these evaluations I deemed that the most valuable representation for the average user would be a graph representation respective of the shape of the baked good, overlaid with the polygon representation. This alleviates the weaknesses of each of the representations on their own and so complements each other producing the best representation conveying the most amount of information. The user can see if the baked good is over or under cooked in a particular direction, the percentage of the baked good falling into each group and the level of bake across the baked good in each of the sectors/regions.

<img width="682" alt="image" src="https://github.com/user-attachments/assets/0ea408fe-9f29-4068-8c6d-21729051fb4f">

Another use for the radial sectors and radial regions graphs are the ability for the user to set the same standard maxBrownness benchmark for representing different images, so that two sectors/regions on two different images will take up the same amount of space on the baked good if their brownness is equal. This allows for comaparisons between two different images. This would allow for example a user to test the same mixture on two different shelves of their oven to test the uniformity of the heat of their oven. Or the user could be responsible for testing the food product itself rather than the heating appliance, so they use two different mixtures on the same shelf in the same oven at the same temperature for the same time and compare the results side by side.

<img width="720" alt="image" src="https://github.com/user-attachments/assets/3dd3d13d-3f41-4c96-8ddd-3208e342fa5d">

Comparing two different circular cookies with the same maxBrownness benchmark.

<img width="624" alt="image" src="https://github.com/user-attachments/assets/38f9f379-916a-453d-849e-f74d3d94671c">

Comparing two different rectangular biscuits with the same maxBrownness benchmark.

The user/customer of VeriVide's DigiEye technology now no longer needs to annotate the image themselves, saving time for business critical areas and preventing the risk of human error. Now there is an automated solution to represent the bake uniformity of their bakes with is quick and repeatable saving time and money.

## Appendix

### Centre Of Mass Of A K-means Group
How to calculate brownness of radial sectors.
