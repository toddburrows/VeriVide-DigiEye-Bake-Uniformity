#needed for plotting
library(ggplot2)

#needed for dataframe manipulating
library(dplyr)

#needed for radial graph representation
library(circlize)

#needed for my self defined functions, e.g. centre of mass calculation
source('/Users/toddb/Desktop/VeriVide Work/Todd/BakeUniformity/aCode/userDefFunctions.R')


#for drawing arrows on an image
drawArrows <- function(kmMatrix, indexMap){
  
  #working out image width and length
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #used to calculate number of pixels on the cake and centre of cake
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){ #pixels on cake
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
      }
    }
  }
  
  #number of pixels on cake 
  numPixels <- countSum
  
  #calculating a scale factor used for drawing a reasonable arrow length
  #wasnt entirely accurate and sometimes needed changing so perhaps need to be
  #better calculated
  scaleFactor <- sqrt(numPixels)/200
  
  #calculating centre
  centreX <- xSum / numPixels
  centreY <- ySum / numPixels
  
  #print(c(centreX,centreY))
  
  #ordering groups by greatest amount of cake within region to lowest so like a
  #clock face, the largest width arrow is at the bottom, with smaller on top
  indexOrder <- indexMap |>
    arrange(desc(SamplePercentage))
  
  #3 times for each arrow
  for(i in 1:3){
    #finds centre of mass of group given
    com <- CoM(kmMatrix, indexOrder[1][i,])
    
    #xcoordinate
    xcm <- com[1]
    
    #ycoordinate
    ycm <- com[2]
    
    #start and end points of each arrow
    xPoints <- c(centreX, xcm)
    yPoints <- c(centreY, ycm)
    
    #set colour depending on which group we are on
    if(indexOrder[4][i,] == 'Over'){
      colour = '#FF6666'
    } else if(indexOrder[4][i,] == 'Good'){
      colour = '#06B709'
    } else {
      colour = '#00ccff'
    }
    
    #used for scaling the arrows' tail length
    arrowLength <- sqrt((xPoints[1]-xPoints[2])**2 + (yPoints[1]-yPoints[2])**2)
    
    #arrow width also proportional to sample percentage 
    arrowWidth <- ((indexOrder[3][i,]*scaleFactor)/20)
    
    #drawing arrow
    arrows(xPoints[1], yWidth-yPoints[1], xPoints[2], yWidth-yPoints[2], lwd = arrowWidth, col=colour, length = (arrowLength/500))
    #I have to do yWidth - y because the image is stored where (1,1) is in top left
    #But the default plotting format with R is that (1,1) is in bottom left
    #So y-axis is flipped so everytime I plot i just do yWidth-y.
    #I probably couldve flipped ImMat,brownMatrix,chromaMatrix,lightMatrix and kmMatrix all
    #when they are first created, then i wouldnt have had to do yWidth-y everytime i plot things
  }
  
  #returns the table of data
  return(indexMap)
}

#used to give rating of the uniformity of the bake, returns arrow, radial and overall rating
giveRating <- function(kmMatrix, indexMap, shape){ 
  #shape is 'rectangular' or 'circular'
  
  #size of image
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #used to find centre of image and number of pixels
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  #used to find width and length of bake if rectangular
  #probably shouldve only done this part and this part *** when shape == 'rectangular'
  #as when circular we assume a circle and use pi*r^2 = A to give radius.
  minX <- 9e99
  minY <- 9e99
  maxX <- 0
  maxY <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){ #pixels on cake
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
        
        # ***
        minX <- min(minX, x)
        minY <- min(minY, y)
        maxX <- max(maxX, x)
        maxY <- max(maxY, y)
        # ***
      }
    }
  }
  
  numPixels <- countSum
  
  if(shape == 'circular'){
    #if circular assume perfect circle and use pi*r^2=A
    radius <- sqrt(numPixels/pi)
  } else {
    #if rectangular take largest of the length or width as radius
    radius <- max(abs(maxX-minX),abs(maxY-minY))
  }
  
  #giving centre of cake
  centreX <- xSum / numPixels
  centreY <- ySum / numPixels
  
  #order index map
  indexOrder <- indexMap |>
    arrange(desc(SamplePercentage))
  
  #used for calculating distance between over and undercooked arrow ends (CoM)
  xDists <- c()
  yDists <- c()
  
  for(i in 1:3){
    
    #find centre of mass of given region
    com <- CoM(kmMatrix, indexOrder[1][i,])
    xcm <- com[1]
    ycm <- com[2]
    
    #start and end of arrow
    xPoints <- c(centreX, xcm)
    yPoints <- c(centreY, ycm)
    
    if(indexOrder[4][i,] == 'Over'){
      #for over cooked arrow remember where it ends
      xDists <- c(xDists, xcm)
      yDists <- c(yDists, ycm)
    } else if(indexOrder[4][i,] == 'Good'){
      #for good arrow, remember its distance from centre
      minorDist <- sqrt((xPoints[1]-xPoints[2])**2 + (yPoints[1]-yPoints[2])**2)
    } else {
      #for under cooked arrow remember where it ends
      xDists <- c(xDists, xcm)
      yDists <- c(yDists, ycm)
    }
  }
  
  #find distance between over and under cooked arrow ends 
  #(i.e. difference between their centre of masses)
  majorDist <- sqrt((xDists[1]-xDists[2])**2 + (yDists[1]-yDists[2])**2)
  
  #over under rating. Where if over and under were pointing in exact opposite direction
  #to the edge of the cake their distance would be diameter of cake (i.e. 2*radius)
  #so majordist/2*radius = 1, and so overunderrating = 0 which would be worst case
  overUnderRating <- 1 - majorDist/(2*radius)
  
  #good arrrow rating. where further from centre the good arrow is the worse the rating
  goodRating <- 1 - minorDist/radius
  
  #average of overunderrating and good rating forms arrow rating
  arrowRating <- (overUnderRating+goodRating)/2
  
  #now for calculating the radial rating
  #it uses the radial graph if the cake is circular
  #or uses the rectangular radial graph (with the bar charts) if the cake is rectangular
  #calculates the percentage difference between region with max brownness and region with min brownness
  if(shape == 'circular'){
    #size of image
    xWidth <- dim(kmMatrix)[2]
    yWidth <- dim(kmMatrix)[1]
    
    #for working out centre and radius
    xSum <- 0
    ySum <- 0
    countSum <- 0
    
    for(x in 1:xWidth){
      for(y in 1:yWidth){
        if(kmMatrix[y,x] > 0){ #if pixel on cake
          xSum <- xSum + x
          ySum <- ySum + y
          countSum <- countSum + 1
        }
      }
    }
    
    #number of pixels = area
    numPixels <- countSum
    
    #calculating centre
    centreX <- round(floor(xSum / numPixels))
    centreY <- round(floor(ySum / numPixels))
    
    #using A=pi*r^2
    radius <- sqrt(numPixels/pi)
    
    #making sure radius is not longer than the image in any direction
    radius <- min(radius,xWidth-centreX+1,centreX,yWidth-centreY+1,centreY)
    
    #positive diagonal line
    #y=x+constant this implies
    constantPos <- (yWidth-centreY)-centreX
    
    #negative diagonal line
    #y=-x+constant this implies
    constantNeg <- (yWidth-centreY)+centreX
    
    #for each sector
    pixelsTaken <- 0
    sectorPixels <- c()
    sectorBrownnessVals <- c()
    sectorColours <- c()
    
    for(i in 1:8){
      #getting average brown value for region
      sectorData <- getBrownValues(i, brownMatrix, imMat, centreX, centreY, xWidth, yWidth, constantPos, constantNeg)
      
      #average brown value
      sectorBrownness <- as.numeric(sectorData[2])
      sectorBrownnessVals <- c(sectorBrownnessVals, sectorBrownness)
    }
    
    #difference between sector with greatest brownness and sector with smallest brownness
    difference <- max(sectorBrownnessVals) - min(sectorBrownnessVals)
    
    #sum of sector with greatest brownness and sector with smallest brownness
    sumDif <- max(sectorBrownnessVals) + min(sectorBrownnessVals)
    
    #percentage difference
    graphRating <- 1 - (2*difference)/(sumDif)
    
  } else {
    #cake is rectangular instead
    
    #size of image
    xWidth <- dim(kmMatrix)[2]
    yWidth <- dim(kmMatrix)[1]
    
    #use for calculating centre
    xSum <- 0
    ySum <- 0
    countSum <- 0
    
    #used for calculating width and length of cake
    minX <- 9e99
    minY <- 9e99
    maxX <- 0
    maxY <- 0
    
    for(x in 1:xWidth){
      for(y in 1:yWidth){
        if(kmMatrix[y,x] > 0){ #pixels on cake
          xSum <- xSum + x
          ySum <- ySum + y
          countSum <- countSum + 1
          
          minX <- min(minX, x)
          minY <- min(minY, y)
          maxX <- max(maxX, x)
          maxY <- max(maxY, y)
        }
      }
    }
    
    #area = number of pixels
    numPixels <- countSum
    
    #centre of cake
    centreX <- round(floor(xSum / numPixels))
    centreY <- round(floor(ySum / numPixels))
    
    #height of image
    lineHeight <- maxY-minY+1
    
    #width of image
    lineWidth <- maxX-minX+1
    
    #step for regions
    yIncrement <- lineHeight%/%3
    #remainder
    yIncrementRem <- lineHeight%%3
    
    #location of lines
    horizontalOne <- minY+yIncrement
    horizontalTwo <- horizontalOne+yIncrement
    
    #for if remainder = 2 
    #(e.g. height=11 (11/3= 3 r2) gives regions sized 3,3,5 but then this changes it to 3,4,4)
    if(yIncrementRem == 2){
      horizontalTwo <- horizontalTwo + 1
    }
    
    #step for regions
    xIncrement <- lineWidth%/%3
    #remainder
    xIncrementRem <- lineWidth%%3
    
    #location of lines
    verticalOne <- minX+xIncrement
    verticalTwo <- verticalOne+xIncrement
    
    #for if remainder =2
    #same as above
    if(xIncrementRem == 2){
      verticalTwo <- verticalTwo + 1
    }
    
    #location of each line left to right
    xCoords <- c(minX,verticalOne,verticalTwo,maxX)
    #and top to bottom
    yCoords <- c(minY,horizontalOne,horizontalTwo,maxY)
    
    regionBrownnessVals <- c()
    
    #getting brownness values
    for(x in 1:3){
      for(y in 1:3){
        #min and max x and y for the square/rectangular region, 9 of these
        xMin <- xCoords[x]
        xMax <- xCoords[x+1]
        yMin <- yCoords[y]
        yMax <- yCoords[y+1]
        
        #getting brown values in region
        brownValues <- as.vector(brownMatrix[yMin:yMax,xMin:xMax])
        
        #omitting na values
        brownValues <- na.omit(brownValues)
        
        #average brownness value for region
        regionBrownness <- mean(brownValues)
        
        regionBrownnessVals <- c(regionBrownnessVals, regionBrownness)
      }
    }
    
    #difference between region with max brownness and region with min brownness
    difference <- max(regionBrownnessVals) - min(regionBrownnessVals)
    
    #sum of region with max brownness and region with min brownness
    sumDif <- max(regionBrownnessVals) + min(regionBrownnessVals)
    
    #percentage difference between max and min
    graphRating <- 1 - (2*difference)/(sumDif)
  }
  
  #overall rating is average of arrow rating and graph/radial rating
  overallRating <- (arrowRating+graphRating)/2 
  
  #returns all 3 ratings
  return(c(arrowRating,graphRating,overallRating))
}

#for drawing masked image
drawMaskedImage <- function(imMat, kmMatrix, brownMatrix, indexMap){
  
  #ordering by cluster number
  indexOrder <- indexMap |>
    arrange(Cluster)
  
  #about to get a colour to represent each group, to represent the areas not
  #on the cake, group 0, we will use white as below.
  groupColours <- c('#ffffff')
  
  for(i in 1:3){
    #the pixel with brownness value closest to the brownness value of the centre brownness of the
    #group. Ideally this would be average rgb of group as this sometimes selects a poor colour
    #to represent the group, sometimes I add a number as below just to select different colours
    closestBrown <- which.min(abs(brownMatrix-indexOrder$ClusterCentreBrownness[i]+0.5)) #should be 0 but added to get better colour
    
    #closestBrown gives a position like 5,463,839, so i have to find corresponding x and y
    yClosestBrown <- round((closestBrown/dim(imMat)[1]-floor(closestBrown/dim(imMat)[1]))*dim(imMat)[1])
    xClosestBrown <- round(ceiling(closestBrown/dim(imMat)[1]))
    
    #find the rgb of the pixel at (xClosestBrown,yClosestBrown)
    colClosestBrown <- imMat[yClosestBrown,xClosestBrown,1:3]/255
    
    #add this colour to the list of colours
    groupColours <- append(groupColours, rgb(colClosestBrown[1], colClosestBrown[2], colClosestBrown[3]))
  }
  
  #transpose and reverse, needed for imaging
  kmMatrixT <- apply(kmMatrix, 2, rev)
  
  #View(kmMatrixT)
  
  #draw index map
  image(1:dim(imMat)[2], 1:dim(imMat)[1], z=t(kmMatrixT), col = groupColours, axes=FALSE, xlab=NA, ylab=NA, bg=NA)
  
  #returns the table of data
  return(indexMap)
}

#for drawing arrows on the original image
drawArrowsOnIm <- function(im, kmMatrix, indexMap){
  #plot the image first
  plot(im)
  
  #now draw arrows on current image
  return(drawArrows(kmMatrix, indexMap))
}

#for drawing arrows on the masked image
drawArrowsOnMaskedIm <- function(imMat, kmMatrix, brownMatrix, indexMap){
  #plot the index map/masked image first
  temp <- drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)
  
  #now draw arrows on current image
  return(drawArrows(kmMatrix, indexMap))
}

#for drawing bubbles on an image
drawBubbles <- function(kmMatrix, indexMap){
  
  #find image size
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #for calculating centre of cake
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
      }
    }
  }
  
  #area is number of pixels
  numPixels <- countSum
  
  #a scale factor so that the size of the bubbles is reasonable for size of cake
  scaleFactor <- sqrt(numPixels)/200 #havent had to alter, has been good
  
  #centre of image
  centreX <- xSum / numPixels
  centreY <- ySum / numPixels
  
  #ordering index map by group with greatest number of pixels inside first
  #so that the largest bubble is drawn first with smaller ones on top
  indexOrder <- indexMap |>
    arrange(desc(SamplePercentage))
  
  #for each 3 bubble
  for(i in 1:3){
    
    #work out centre of mass of region
    com <- CoM(kmMatrix, indexOrder[1][i,])
    xcm <- com[1]
    ycm <- com[2]
    
    #getting corresponding colour
    if(indexOrder[4][i,] == 'Over'){
      colour = '#FF6666'
    } else if(indexOrder[4][i,] == 'Good'){
      colour = '#06B709'
    } else {
      colour = '#00ccff'
    }
    
    #radius proportional to sample percentage as well as being scaled by scale factor
    radius <- ((indexOrder[3][i,]*scaleFactor)/10)
    
    #drawing bubble
    #once again yWidth-y because axis are flipped in plot to the matrices
    imager::circles(xcm,yWidth-ycm,radius,bg=colour,fg=colour)
    
    #drawing point in the centre of the bubble
    points(xcm,yWidth-ycm, pch=4, cex=(radius*2)/(9*scaleFactor), lwd = (radius*2)/(2*scaleFactor))
  }
  
  #drawing point at the centre of the cake for reference
  points(centreX,yWidth-centreY,pch=19)
  
  #returns the table of data
  return(indexMap)
}

#for drawing bubbles on the original image
drawBubblesOnIm <- function(im, kmMatrix, indexMap){
  
  #plots original image first
  plot(im)
  
  #then draws bubbles on current image
  return(drawBubbles(kmMatrix, indexMap))
}

#for drawing bubbles on the masked image
drawBubblesOnMaskedIm <- function(imMat, kmMatrix, brownMatrix, indexMap){
  
  #plots masked/index map image first
  temp <- drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)
  
  #then draws bubbles on current image
  return(drawBubbles(kmMatrix, indexMap))
}

#for drawing polygons on an image
drawRectangles <- function(kmMatrix, indexMap){
  
  #width of image
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #used to find centre of image and number of pixels
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){ #pixels on the cake
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
      }
    }
  }
  
  numPixels <- countSum
  
  #a scale factor that is related to the size of the cake and is used to scale
  #the size of the polygons so that they are reasonable for the size of the image
  scaleFactor <- sqrt(numPixels)/200
  
  #centre
  centreX <- xSum / numPixels
  centreY <- ySum / numPixels
  
  #ordering the groups so that the largest polygon (by area) is drawn first and 
  #the smaller ones sit on top of the larger ones
  indexOrder <- indexMap |>
    arrange(desc(SamplePercentage))
  
  #for each polygon
  for(i in 1:3){
    
    #getting corresponding colour
    if(indexOrder[4][i,] == 'Over'){
      colour = '#FF6666'
    } else if(indexOrder[4][i,] == 'Good'){
      colour = '#06B709'
    } else {
      colour = '#00ccff'
    }
    
    #finding centre of mass of region
    com <- CoM(kmMatrix, indexOrder[1][i,])
    xcm <- com[1]
    ycm <- com[2]
    
    #if it were to be represented by a rectangle i calculate...
    
    #the rectangle length (euclidean distance from centre to centre of mass)
    rectLength <- sqrt((centreX-xcm)**2 + (centreY-ycm)**2)
    
    #the rectangle area which is proportional to the percentage of the cake that
    #lies within that region and scaled by the scale factor
    rectArea <- (indexOrder[3][i,]/100)*5000*scaleFactor #numbers might need altering to be reasonable
    
    #width of rectangle from area and length
    rectWidth <- rectArea/rectLength
    
    #if the rectangle width > 0.75 * rectangle length then instead we represent
    #the rectangle with a square
    #otherwise we use a rectangle as normal, but if 10*width < length so the
    #rectangle is really long and thin we use a triangle that fans out instead
    if(rectWidth < 0.75*rectLength){ 
      
      #the case of needing a triangle
      if(rectWidth < 0.1*rectLength){ #0.1, but maybe 0.2 may want to be used
        
        #the triangle's area and height will be the same as if it were
        #represented by a rectangle
        triangleArea <- rectArea
        triangleHeight <- rectLength
        
        #the base will clearly be twice the width of if it were a rectangle
        triangleBase <- 2*rectWidth
        
        #need to use trig to calculate the increase/decrease in x and 
        #increase/decrease in y from the centre of mass position to find the
        #coordinates of the triangle's vertices
        theta <- atan((centreY-ycm)/(centreX-xcm))
        phi <- (pi/2)-theta
        
        #the increment/decrement in x and increment/decrement in y
        xDist <- (triangleBase/2) * cos(phi)
        yDist <- (triangleBase/2) * sin(phi)
        
        #giving coords of traingle
        xVerts <- c(centreX,xcm-xDist,xcm+xDist)
        yVerts <- c(centreY,ycm+yDist,ycm-yDist)
        
      } else {
        #the case of still using a rectangle as normal
      
        #need to use trig to calculate the increase/decrease in x and 
        #increase/decrease in y from the centre and from the centre of mass 
        #position to find the coordinates of the rectangle's vertices
        theta <- atan((centreY-ycm)/(centreX-xcm))
        phi <- (pi/2)-theta
        
        #the increment/decrement in x and the increment/decrement in y
        xDist <- (rectWidth/2) * cos(phi)
        yDist <- (rectWidth/2) * sin(phi)
      
        #giving coords of rectangle
        xVerts <- c(centreX-xDist,xcm-xDist,xcm+xDist,centreX+xDist)
        yVerts <- c(centreY+yDist,ycm+yDist,ycm-yDist,centreY-yDist)
      
        }
      
    } else { 
      #the case that we use a square
      
      #once again the square's area is equal to the area if it had been
      #represented by a rectangle
      squareArea <- rectArea
      
      #the length of a side of the square is sqrt its area
      squareLength <- sqrt(rectArea)
      
      #need to use trig to calculate the increase/decrease in x and
      #increase/decrease in y from the centre of mass (centre of square) to find
      #the coordinates of the square's vertices
      theta <- atan((centreY-ycm)/(centreX-xcm))
      
      #each vertex
      x1 <- xcm + (squareLength/2)*(cos(theta) + cos(theta + pi/2))
      y1 <- ycm + (squareLength/2)*(sin(theta) + sin(theta + pi/2))
      
      x2 <- xcm + (squareLength/2)*(cos(theta) - cos(theta + pi/2))
      y2 <- ycm + (squareLength/2)*(sin(theta) - sin(theta + pi/2))
      
      x3 <- xcm + -1*(squareLength/2)*(cos(theta) + cos(theta + pi/2))
      y3 <- ycm + -1*(squareLength/2)*(sin(theta) + sin(theta + pi/2))
      
      x4 <- xcm + -1*(squareLength/2)*(cos(theta) - cos(theta + pi/2))
      y4 <- ycm + -1*(squareLength/2)*(sin(theta) - sin(theta + pi/2))
      
      xVerts <- c(x1,x2,x3,x4)
      yVerts <- c(y1,y2,y3,y4)
      
    }
    
    #now drawing each polygon using the xcoords and ycoords
    #also using adjust colour to make the colour translucent
    #yWidth - y again because of axis being flipped
    polygon(xVerts, yWidth-yVerts, col=adjustcolor(colour, alpha = 0.5))
  }
  
  #point at the centre of the cake
  points(centreX,yWidth-centreY,pch=19)
  
  #returning table
  return(indexMap)
}

#for drawing rectangles on the original image
drawRectanglesOnIm <- function(im, kmMatrix, indexMap){
  
  #plots original image first
  plot(im)
  
  #then draws rectangles on top of current image
  return(drawRectangles(kmMatrix, indexMap))
}

#for drawing rectangles on the masked image
drawRectanglesOnMaskedIm <- function(imMat, kmMatrix, brownMatrix, indexMap){
  
  #plots masked/index map image first
  temp <- drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)
  
  #then draws rectangles on top of current image
  return(drawRectangles(kmMatrix, indexMap))
}

#for drawing radial graph
drawRadialGraph <- function(kmMatrix, brownMatrix, indexMap, optionGiven){
  
  #size of image
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #for calculating centre of cake and number of pixels i.e. area
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){ #pixels on cake only
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
      }
    }
  }
  
  #area = number of pixels
  numPixels <- countSum
  
  #centre of cake
  centreX <- round(floor(xSum / numPixels))
  centreY <- round(floor(ySum / numPixels))
  
  #A = pi*r^2 giving radius
  radius <- sqrt(numPixels/pi)
  
  #ensuring that the radius of the cake does not exceed the left or right edge 
  #of the image or the top or bottom of the image
  radius <- min(radius,xWidth-centreX+1,centreX,yWidth-centreY+1,centreY)
  
  #vertical line
  lines(x=c(centreX,centreX),y=c(yWidth-(centreY-radius), yWidth-(centreY+radius)),lwd=2)
  
  #horizontal line
  lines(x=c(centreX-radius, centreX+radius),y=c(yWidth-centreY,yWidth-centreY),lwd=2)
  
  #above yWidth-y because of axis flipped, and line width = 2 so that it is better defined on image
  
  #positive diagonal line
  #y=x+constant this implies...
  constantPos <- (yWidth-centreY)-centreX
  
  #drawing this line
  lines(x=c(centreX+(radius*cos(pi/4)),centreX-(radius*cos(pi/4))),
        y=c(yWidth-(centreY-(radius*sin(pi/4))),yWidth-(centreY+(radius*sin(pi/4)))),
        lwd=2)
  
  #negative diagonal line
  #y=-x+constant this implies
  constantNeg <- (yWidth-centreY)+centreX
  
  #drawing this line
  lines(x=c(centreX-(radius*cos(pi/4)),centreX+(radius*cos(pi/4))),
        y=c(yWidth-(centreY-(radius*sin(pi/4))),yWidth-(centreY+(radius*sin(pi/4)))),
        lwd=2)
  
  #drawing the outer circle
  imager::circles(x=centreX,y=(yWidth-centreY),radius=radius,fg='black',lwd=2)
  
  #initialising vectors for data about all 8 sectors
  pixelsTaken <- 0 #this is not used currently but was useful for checking number of pixels inspected
  sectorPixels <- c()
  sectorBrownnessVals <- c()
  sectorColours <- c()
  
  #for each sector 8x
  for(i in 1:8){
    #I have decided to go from the positive x axis, anticlockwise, where each
    #sector includes the line that seperates it from the previous sector but
    #does not include the line that seperates it from the next sector
    #the first sector also includes the centre point, which no other does
    
    #So the first sector is the sector defined by the positive x axis, and the 
    #positive diagonal line and includes the centre point and the positive x 
    #axis line
    
    #using user-defined function to find brownness value in particular sector
    sectorData <- getBrownValues(i, brownMatrix, imMat, centreX, centreY, xWidth, yWidth, constantPos, constantNeg)
    #returns number of pixels inspected in that sector, sector average brownness and the sector colour...
    #the sector colour is the colour of the pixel on the cake with the closest brownness value to the sector's average brownness
    pixelsTaken <- pixelsTaken + as.numeric(sectorData[1]) #not used as above
    sectorBrownness <- as.numeric(sectorData[2])
    
    sectorPixels <- c(sectorPixels, as.numeric(sectorData[1]))
    sectorBrownnessVals <- c(sectorBrownnessVals, sectorBrownness)
    
    #this is not currently used, as we decided the greyscale looked better
    sectorColours <- c(sectorColours, sectorData[3]) 
  }
  
  #this decides the max brownness, i.e. the brownness at which the bar would
  #reach the edge of the cake
  if(optionGiven == 'half'){
    brownMatrix[is.na(brownMatrix)] <- 0
    maxBrownness <- max(brownMatrix)
    brownMatrix[brownMatrix == 0] <- NA
  } else if(optionGiven == 'full'){
    maxBrownness <- max(sectorBrownnessVals)
  } else {
    maxBrownness <- optionGiven
  }
  
  #This is to use the greyscale, surrounded by # so that it can be commented out
  #to revert to using the colour system instead. But i think greyscale looked
  #better. 
  ##############################################################################
  
  #defined list of colours because i found it better than trying to do a greyscale
  #proportional to the level of brownness as if all sectors similar brownness
  #it would be hard to distinguish the colour between them
  sectorColours <- c('#f2f2f2','#e8e8e8','#d6d6d6','#bdbdbd','#b0b0b0','#919191','#707070','#545454')
  
  #need the following so the brownness is ordered smallest to largest and so
  #the lightest to darkest colours are assigned correctly
  temporaryDf <- data.frame(sectNum = 1:8,
                   brown = sectorBrownnessVals)
  
  temporaryDf <- temporaryDf |>
    arrange(brown) |>
    mutate(colour = sectorColours) |> #adds the column sector Colours above
    arrange(sectNum) #arranges back to being in order of sector 1,2,...,8
  
  sectorColours <- temporaryDf$colour #now sector colours is in the correct order
  
  ##############################################################################
  
  #drawing each sector
  for(i in 1:8){
    sectorBrownness <- sectorBrownnessVals[i]
    
    #using adjust colour to make bars translucent
    sectorColour <- adjustcolor(sectorColours[i], alpha = 0.3) #0.5
    
    #if sector average brownness = max brownness then bar is same length as radius of cake
    radiusSect <- (sectorBrownness/maxBrownness)*radius
    
    #start and end degree
    startDeg <- (i-1)*45
    endDeg <- i*45
    
    #drawing sector
    draw.sector(start.degree = startDeg,
                end.degree = endDeg,
                rou1 = radiusSect,
                center = c(centreX,yWidth-centreY),
                clock.wise = FALSE,
                col = sectorColour)
  }
  
  #returning table of each sector how many pixels inspected and its average brownness
  return(data.frame(Brownness = sectorBrownnessVals,
                    NumPixels = sectorPixels))
}


#for drawing radial graph on the original image
drawRadialGraphOnIm <- function(im, kmMatrix, brownMatrix, indexMap, optionGiven){
  
  #drawing original image
  plot(im)
  
  #drawing radial graph on current image
  return(drawRadialGraph(kmMatrix, brownMatrix, indexMap, optionGiven))
}

#for drawing radial graph on the masked image
drawRadialGraphOnMaskedIm <- function(imMat, kmMatrix, brownMatrix, indexMap, optionGiven){
  
  #drawing masked/index map image
  temp <- drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)
  
  #drawing radial graph on current image
  return(drawRadialGraph(kmMatrix, brownMatrix, indexMap, optionGiven))
}

#function for drawing square radial graph on image
#optionGiven is same as above, defines the max brownness and therefore size of
#the bars
#the shape parameter is 'rectangles' or 'squares'
#rectangles is like a bar chart in each 9 regions starting from bottom
#squares is a square centered at the centre of the region increasing in size outwards
drawSquareGraph <- function(kmMatrix, brownMatrix, indexMap, optionGiven, shape){
  
  #size of image
  xWidth <- dim(kmMatrix)[2]
  yWidth <- dim(kmMatrix)[1]
  
  #used for calculating centre of cake
  xSum <- 0
  ySum <- 0
  countSum <- 0
  
  #used for finding borders of the cake/biscuit
  minX <- 9e99
  minY <- 9e99
  maxX <- 0
  maxY <- 0
  
  for(x in 1:xWidth){
    for(y in 1:yWidth){
      if(kmMatrix[y,x] > 0){ #pixels on cake
        xSum <- xSum + x
        ySum <- ySum + y
        countSum <- countSum + 1
        
        #finding minimum and maximum x and y values, i.e. border of cake/biscuit
        minX <- min(minX, x)
        minY <- min(minY, y)
        maxX <- max(maxX, x)
        maxY <- max(maxY, y)
      }
    }
  }
  
  #number of pixels used to find centre
  numPixels <- countSum
  
  #centre
  centreX <- round(floor(xSum / numPixels))
  centreY <- round(floor(ySum / numPixels))
  
  #distance between bottom of baked good and top of baked good
  lineHeight <- maxY-minY+1
  
  #distance between left of baked good and right of baked good
  lineWidth <- maxX-minX+1
  
  #increment vertically between each region
  yIncrement <- lineHeight%/%3
  
  #the remainder when dividing the height by 3
  yIncrementRem <- lineHeight%%3
  
  #working out position of horizontal lines  
  horizontalOne <- minY+yIncrement
  horizontalTwo <- horizontalOne+yIncrement
  
  #if the remainder is 1 thats okay because the heights of each region will be 
  #(n pixels),(n pixels),(n+1 pixels) but if the remainder is 2 then it will be
  #(n pixels),(n pixles),(n+2 pixels) and so we need to make it 
  #(n pixels), (n+1 pixels), (n+1 pixels) by adding one to 2nd middle horizontal
  if(yIncrementRem == 2){
    horizontalTwo <- horizontalTwo + 1
  }
  
  #increment horizontally between each region
  xIncrement <- lineWidth%/%3
  
  #the remainder when dividing the width by 3
  xIncrementRem <- lineWidth%%3
  
  #working out the position of the vertical lines
  verticalOne <- minX+xIncrement
  verticalTwo <- verticalOne+xIncrement
  
  #if the remainder is 1 thats okay because the widths of each region will be 
  #(n pixels),(n pixels),(n+1 pixels) but if the remainder is 2 then it will be
  #(n pixels),(n pixles),(n+2 pixels) and so we need to make it 
  #(n pixels), (n+1 pixels), (n+1 pixels) by adding one to 2nd middle vertical
  if(xIncrementRem == 2){
    verticalTwo <- verticalTwo + 1
  }
  
  #coordinates of lines
  xCoords <- c(minX,verticalOne,verticalTwo,maxX)
  yCoords <- c(minY,horizontalOne,horizontalTwo,maxY)
  
  #drawing horizontal lines
  lines(x=c(xCoords[1],xCoords[4]),y=c(yWidth-yCoords[1]+1,yWidth-yCoords[1]+1),lwd=2)
  lines(x=c(xCoords[1],xCoords[4]),y=c(yWidth-yCoords[2]+1,yWidth-yCoords[2]+1),lwd=2)
  lines(x=c(xCoords[1],xCoords[4]),y=c(yWidth-yCoords[3]+1,yWidth-yCoords[3]+1),lwd=2)
  lines(x=c(xCoords[1],xCoords[4]),y=c(yWidth-yCoords[4]+1,yWidth-yCoords[4]+1),lwd=2)
  
  #drawing vertical lines
  lines(x=c(xCoords[1],xCoords[1]),y=c(yWidth-yCoords[1]+1,yWidth-yCoords[4]+1),lwd=2)
  lines(x=c(xCoords[2],xCoords[2]),y=c(yWidth-yCoords[1]+1,yWidth-yCoords[4]+1),lwd=2)
  lines(x=c(xCoords[3],xCoords[3]),y=c(yWidth-yCoords[1]+1,yWidth-yCoords[4]+1),lwd=2)
  lines(x=c(xCoords[4],xCoords[4]),y=c(yWidth-yCoords[1]+1,yWidth-yCoords[4]+1),lwd=2)
  
  #yWidth - y because of y axis flipped
  
  #max height of a region (some could be 1 pixel greater - but accurate enough for my application)
  #in future it may be necessary to have a max height defined within the loop as it could be 
  #different for each region if there are remainders in baked good height/3
  maxLength <- lineHeight%/%3
  
  #intialising for getting values
  regionBrownnessVals <- c()
  regionPixelVals <- c()
  
  #getting brownness values for each region
  for(x in 1:3){
    for(y in 1:3){
      
      #using x and y coords of each horizontal and vertical line to determine
      #the maximum and minimum x and y of the region we are dealing with so that
      #only the brownness values within the region are taken
      xMin <- xCoords[x]
      xMax <- xCoords[x+1]
      yMin <- yCoords[y]
      yMax <- yCoords[y+1]
      
      #getting brown values for all pixels in region
      brownValues <- as.vector(brownMatrix[yMin:yMax,xMin:xMax])
      
      #number of pixels inspected
      regionPixels <- length(brownValues)
      
      #removing NA values - pixels not on the cake
      brownValues <- na.omit(brownValues)
      
      #getting region average brownness
      regionBrownness <- mean(brownValues)
      
      #adding the data found to vectors
      regionBrownnessVals <- c(regionBrownnessVals, regionBrownness)
      regionPixelVals <- c(regionPixelVals,regionPixels)
    }
  }
  
  #only option is grey scale for this representation as by the point i wrote this
  #we decided that greyscale was far better than getting a colour from the baked 
  #good for each region
  regionColours <- c('#f2f2f2','#e8e8e8','#d6d6d6','#bdbdbd','#b0b0b0','#919191','#707070','#545454','#1f1f1f')
  
  #need the following so the brownness is ordered smallest to largest and so
  #the lightest to darkest colours are assigned correctly
  temporaryDf <- data.frame(regionNum = 1:9,
                            brown = regionBrownnessVals)
  
  temporaryDf <- temporaryDf |>
    arrange(brown) |>
    mutate(colour = regionColours) |> #add column of colours
    arrange(regionNum) #arrange now back to in order of regions 1,2,...,9
  
  #colours now in order
  regionColours <- temporaryDf$colour
  
  #this is used to define the max brownness which is the brownness at which a
  #regions average brownness must be for the bar to take up the entire region
  #user gives half means max brownness is max brownness on baked good
  #user gives full means max brownness is brownness of sector with highest average brownness
  #user gives a value means max brownness is this value
  if(optionGiven == 'half'){
    #getting rid of na values and replacing with 0, R doesnt like NAs when using max
    brownMatrix[is.na(brownMatrix)] <- 0
    maxBrownness <- max(brownMatrix)
    brownMatrix[brownMatrix == 0] <- NA
  } else if(optionGiven == 'full'){
    maxBrownness <- max(regionBrownnessVals)
  } else {
    maxBrownness <- optionGiven
  }
  
  #if the user gave 'rectangles' for the shape parameter
  if(shape == 'rectangles'){
    for(x in 1:3){
      for(y in 1:3){
        #we only need bottom of each region not the top as the top of the bar 
        #i.e. its length is dictated by its brownness
        xMin <- xCoords[x]
        xMax <- xCoords[x+1]
        yMax <- yCoords[y+1]
        
        #determines which region we are in by x and y 
        #(starts in the top left and goes down, then middle and down, then top right and down)
        #so region 1 is in top left
        #region 2 in middle left
        #region 3 bottom left
        #region 4 top middle...
        regionNumber <- ((x-1)*3) + y
        
        #the brownness and colour of the region we are on
        regionBrownness <- regionBrownnessVals[regionNumber]
        regionColour <- regionColours[regionNumber]
        
        #calculating the height the bar should be of this region
        regionHeight <- (regionBrownness/maxBrownness)*maxLength
        
        #coordinates of the rectangle bar for the region
        xVerts <- c(xMin,xMax,xMax,xMin)
        yVerts <- c(yMax,yMax,yMax-regionHeight,yMax-regionHeight)
        
        #drawing the rectangle, using adjustcolour for translucency
        polygon(xVerts, yWidth-yVerts+1, col=adjustcolor(regionColour, alpha = 0.5))
      }
    }
  } else {
    #otherwise - if shape parameter is given as 'squares'
    for(x in 1:3){
      for(y in 1:3){
        #finding the borders of the region so we can use this to find centre of
        #the region
        xMin <- xCoords[x]
        xMax <- xCoords[x+1]
        yMax <- yCoords[y+1]
        yMin <- yCoords[y]
        
        #determines which region we are in by x and y
        regionNumber <- ((x-1)*3) + y
        
        #the brownness and colour of the region we are in
        regionBrownness <- regionBrownnessVals[regionNumber]
        regionColour <- regionColours[regionNumber]
        
        #calculating half the length/width of the square
        #if region average brownness = max brownness then half the length/width
        #of the square will be half the width of the region, i.e. the square
        #will fill the region - but problem:
        #regions are not squares most likely and so if width of region < height
        #when the square fills the region it will fill the full height meaning
        #that it will go over the edge of the region at the sides - needs fixing
        regionSquareRadius <- (regionBrownness/maxBrownness)*(maxLength/2)
        
        #centre of region
        regionCentreX <- (xMax-xMin)/2+xMin
        regionCentreY <- (yMax-yMin)/2+yMin
        
        #x coords of square
        xVerts <- c(regionCentreX+regionSquareRadius,
                    regionCentreX+regionSquareRadius,
                    regionCentreX-regionSquareRadius,
                    regionCentreX-regionSquareRadius)
        
        #y coords of square
        yVerts <- c(regionCentreY-regionSquareRadius,
                    regionCentreY+regionSquareRadius,
                    regionCentreY+regionSquareRadius,
                    regionCentreY-regionSquareRadius)
        
        #drawing square in middle of region, using adjust colour for translucency
        polygon(xVerts, yWidth-yVerts+1, col=adjustcolor(regionColour, alpha = 0.5))
      }
    }
  }
  
  #returning table of each sector how many pixels inspected and its average brownness
  return(data.frame(Brownness = regionBrownnessVals,
                    NumPixels = regionPixelVals))
}

#for drawing square graph on image
drawSquareGraphOnIm <- function(im, kmMatrix, brownMatrix, indexMap, optionGiven, shape){
  
  #drawing original image
  plot(im)
  
  #drawing square graph on current image
  return(drawSquareGraph(kmMatrix, brownMatrix, indexMap, optionGiven, shape))
}

#for drawing square graph on masked/index map image
drawSquareGraphOnMaskedIm <- function(imMat, kmMatrix, brownMatrix, indexMap, optionGiven, shape){
  
  #drawing masked/index map image
  temp <- drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)
  
  #drawing square graph on current image
  return(drawSquareGraph(kmMatrix, brownMatrix, indexMap, optionGiven, shape))
}