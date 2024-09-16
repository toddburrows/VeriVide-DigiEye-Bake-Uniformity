#used to calculate brownness of an xyz pixel
Brownness <- function(xyzval){
  #little x value
  x = xyzval[1]/(xyzval[1]+xyzval[2]+xyzval[3])
  
  #if little x=infinite because X,Y,Z = 0 so X+Y+Z = 0 then brownness = 0
  if(is.nan(x)){
    BrownVal = 0
  } else {
    #if x<0.3138 then brownness will be negative which isnt brown so set
    #brownness to 0
    if(x<0.3138){
      BrownVal = 0
    } else {
      BrownVal = (100*(x-0.3138))/0.17 #brownness calculation
    }
  }
  #returns brownness value for given xyz
  return(BrownVal)
}

#used to calculate centre of mass of a cluster group
#clusternum is the group number we are wanting to find centre of mass of in kmMatrix
CoM <- function(kmMatrix, clusternum){
  
  #size of image
  xwidth <- dim(kmMatrix)[2]
  ywidth <- dim(kmMatrix)[1]
  
  #used to find coords of centre of mass
  sumx <- 0
  sumy <- 0
  numbers <- 0
  
  for(x in 1:xwidth){
    for(y in 1:ywidth){
      if(kmMatrix[y,x] == clusternum){ #pixels that are in the group specified
        sumx <-  sumx + x
        sumy <-  sumy + y
        numbers <-  numbers + 1
      }
    }
  }
  
  #gives average x position
  xcm <- sumx/numbers
  #gives average y position
  ycm <- sumy/numbers
  #giving centre of mass of the group specified
  
  #returns x and y coord
  return(c(xcm,ycm))
}

#used to get sector brownValues for the given sector radial graph
#i is the sector number i=1,...,8
#need the positional data for getting brown values within sector
#need imMat for getting a colour to represent sector - although currently not used
#as using a greyscale instead
getBrownValues <- function(i, brownMatrix, imMat, centreX, centreY, xWidth, yWidth, constantPos, constantNeg){
  #initialise brown values vector
  brownValues <- c()
  
  #each region has entirely different ways to get the data
  #sector 1 is the most odd too because of the addition of the centre point
  
  #see read me and powerpoint showing how i came to calculate the yMin, the x ranges and the yMax for each region
  
  if(i == 1){
    brownValues <- c(brownValues, brownMatrix[(yWidth-centreY),centreX]) #centre point
    
    #y always starts here
    yMin <- centreY #positive x axis included
    for(x in (centreX+1):xWidth){ #x goes between here
      yMax <- min(yWidth,(x+constantPos-1)) #yMax for each x pixel governed by positive diagonal (which isnt included)
      yVals <- yWidth - (yMax:yMin) 
      #add brown values from this column
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i ==2){
    #y always ends here
    yMax <- yWidth
    for(x in (centreX+1):xWidth){ #x goes between here, positive y axis not included
      yMin <- min(yWidth,(x+constantPos)) #yMin for each pixel governed by positive diagonal (which is included)
      yVals <- yWidth - (yMax:yMin)
      #add brown values from this column
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    } #and repeat....................................
  } else if(i == 3){
    yMax <- yWidth
    for(x in 1:centreX){
      yMin <- min(yWidth,(-x + constantNeg + 1))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i == 4){
    yMin <- centreY + 1
    for(x in 1:(centreX - 1)){
      yMax <- min(yWidth,(-x + constantNeg))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i == 5){
    yMax <- centreY
    for(x in 1:(centreX - 1)){
      yMin <- max(1,(x + constantPos + 1))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i == 6){
    yMin <- 1
    for(x in 1:(centreX - 1)){
      yMax <- max(1, (x + constantPos))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i == 7){
    yMin <- 1
    for(x in centreX:xWidth){
      yMax <- max(1,(-x + constantNeg-1))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    }
  } else if(i == 8){
    yMax <- centreY - 1
    for(x in (centreX+1):xWidth){
      yMin <- max(1,(-x + constantNeg))
      yVals <- yWidth - (yMax:yMin)
      brownValues <- c(brownValues, brownMatrix[yVals,x])
    } #until done..........................................
  } else {
    #should never happen but just incase
    print('fail')
  }
  
  #number of pixels inspected in this sector
  sectorPixels <- length(brownValues)
  #getting rid of NA values and so finding average brownness of sector
  brownValues <- na.omit(brownValues)
  sectorBrownness <- mean(brownValues)
  
  #finding the pixel in brownMatrix with its brownness closest to the average brownness of this sector
  closestBrown <- which.min(abs(brownMatrix-sectorBrownness)) 
  
  #as closestbrown gives a number like 4,573,492 we need to work out the x and y coordinate corresponding to this list position
  yClosestBrown <- round((closestBrown/dim(imMat)[1]-floor(closestBrown/dim(imMat)[1]))*dim(imMat)[1])
  xClosestBrown <- round(ceiling(closestBrown/dim(imMat)[1]))
  
  #finding the colour of this pixel
  colClosestBrown <- imMat[yClosestBrown,xClosestBrown,1:3]/255
  
  #using this colour to represent this sector
  #although not currently used as greyscale is used as we decided it was better
  sectorColour <- rgb(colClosestBrown[1], colClosestBrown[2], colClosestBrown[3])
  
  #returns the number of pixels inspected in this sector
  #the average brownness of this sector
  #and the colour this sector should be represented by - not currently used
  return(c(sectorPixels, sectorBrownness, sectorColour))
}
