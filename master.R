#Todd Burrows

#install.packages('magick')

#install.packages('dplyr')

#install.packages('ggplot2')

#install.packages('circlize')

#install.packages('imager')

#install.packages('schemr')

#This removes all variables stored in memory, all plots and all code outputs
rm(list=ls())
graphics.off()
clearMem <- gc()
rm(clearMem)
cat("\014")

#needed for image manipulation
library(magick)

#needed for nice database manipulation
library(dplyr)

#/Users/toddb/Desktop/VeriVide Work/Todd/BakeUniformity/aCode/
#needed for my self defined functions, e.g. brownness calculation
source('/Users/toddb/Desktop/VeriVide Work/Todd/BakeUniformity/aCode/userDefFunctions.R')

#needed for representations
source('/Users/toddb/Desktop/VeriVide Work/Todd/BakeUniformity/aCode/representations.R')

#for tracking run time
startTime <- Sys.time()

#reading image and getting matrix of rgb values
#ONLY BEEN USING BMP IMAGES BUT IT DOES WORK WITH OTHERS... I THINK
im <- image_read('/Users/toddb/Desktop/VeriVide Work/dragon.BMP') ############################ENTER IMAGE
imMat <- as.numeric(image_data(im))*255
#optionIm <- 'toast'
optionIm <- 'cake'

#creating matrix of brownness, chroma and lightness values with NA everywhere
brownMatrix <- matrix(nrow = dim(imMat)[1], ncol = dim(imMat)[2])
chromaMatrix <- matrix(nrow = dim(imMat)[1], ncol = dim(imMat)[2])
lightMatrix <- matrix(nrow = dim(imMat)[1], ncol = dim(imMat)[2])

for(i in 1:dim(imMat)[2]){
  #converting rgb to xyz
  xyzColumn <- as.matrix(schemr::rgb_to_xyz(imMat[1:dim(imMat)[1],i,1:3], transformation = 'sRGB'))
  
  #getting this columns lab values, calculating chroma and so getting the columns chroma values
  #and then taking just l to get lightness values
  labColumn <- as.matrix(schemr::rgb_to_lab(imMat[1:dim(imMat)[1],i,1:3], transformation = 'sRGB'))
  chromaColumn <- as.matrix(c(sqrt(((labColumn[1:nrow(labColumn),2])**2)+((labColumn[1:nrow(labColumn),3])**2))))
  lightnessColumn <- as.matrix(labColumn[1:nrow(labColumn), 1])
  
  #adding this column to its column in the image matrix, populating brownness values matrix,
  #chroma values matrix and lightness values matrix
  brownMatrix[,i] <- apply(xyzColumn, 1, Brownness)
  chromaMatrix[,i] <- chromaColumn
  lightMatrix[,i] <- lightnessColumn
}

#this was to get rid of silver cooling tray in one particular cake image
if (optionIm == 'cake'){
  brownMatrix[which(chromaMatrix < 12)] <- 0 #was 12
}

#this was used for Mick's clafoutis
#brownMatrix[which(lightMatrix > 70)] <- 0

#was also used for a particular image in the past
#brownMatrix[intersect(which(chromaMatrix<12),which(lightMatrix>40))] <- 0

#View(brownMatrix)

#replacing 0s in brownmatrix with NA and then using built-in na.omit to get a 
#list of the brownness values without NA - so the pixels on the cake only
brownMatrix[brownMatrix == 0] <- NA
brownListNA <- na.omit(brownMatrix[1:length(brownMatrix)])

#putting the values into one long single variable data frame for k-means
brownListNAdf <- data.frame(brown = brownListNA)

#performing k-means algorithm to find 3 groups of brownness
km <- kmeans(brownListNAdf, centers = 3, nstart = 25)

#producing table of data to output representing the clusters from k-means
indexMap <- data.frame(Cluster = 1:length(km$centers),
                       ClusterCentreBrownness = as.numeric(km$centers),
                       SamplePercentage = 100*(km$size/sum(km$size)))

#adding a nice label of level of cooked
indexMap <- indexMap |>
  arrange(ClusterCentreBrownness) |>
  mutate(CookingLevel = c("Under", "Good", "Over"))

#calculating ranges of groups from the kmeans

#under cooked
lower1 <- 0
upper1 <- (indexMap$ClusterCentreBrownness[1]+indexMap$ClusterCentreBrownness[2])/2

#good
lower2 <- upper1
upper2 <- (indexMap$ClusterCentreBrownness[2]+indexMap$ClusterCentreBrownness[3])/2

#over cooked
lower3 <- upper2
upper3 <- 9e99

#producing matrix of group number
kmMatrix <- brownMatrix #just starting with this because it will have same dimensions

#pixels not on the cake put into the 0th group
kmMatrix[is.na(brownMatrix)] <- 0 

#for brown values in group i=1 (the under-cooked group) set their corresponding group value
kmMatrix[brownMatrix > lower1 & brownMatrix <= upper1] <- indexMap$Cluster[1]

#for brown values in group i=2 (the good group) set their corresponding group value
kmMatrix[brownMatrix > lower2 & brownMatrix <= upper2] <- indexMap$Cluster[2]

#for brown values in group i=3 (the over-cooked group) set their corresponding group value
kmMatrix[brownMatrix > lower3 & brownMatrix <= upper3] <- indexMap$Cluster[3]

#View(kmMatrix)

#indexMap

#tracking and outputting run time
endTime <- Sys.time()
timeTaken <- endTime - startTime
timeTaken

#removing from memory no longer needed data
rm(brownListNAdf, km, xyzColumn, brownListNA, endTime, i, lower1, lower2,
   lower3, startTime, timeTaken, upper1, upper2, upper3, chromaColumn,
   labColumn, chromaMatrix, lightMatrix, lightnessColumn, optionIm)
clearMem <- gc()
rm(clearMem)

#All the functions to call to do each process:

#raw image
#plot(im)

#index map image
#drawMaskedImage(imMat, kmMatrix, brownMatrix, indexMap)

#no need to plot image/index map image before running these, they do it 
#drawArrowsOnIm(im, kmMatrix, indexMap)
#drawArrowsOnMaskedIm(imMat, kmMatrix, brownMatrix, indexMap)
#drawBubblesOnIm(im, kmMatrix, indexMap)
#drawBubblesOnMaskedIm(imMat, kmMatrix, brownMatrix, indexMap)
#drawRectanglesOnIm(im,kmMatrix,indexMap)
#drawRectanglesOnMaskedIm(imMat,kmMatrix,brownMatrix,indexMap)

#For the following...
#use 'full' for where the region with the highest brownness value takes up the full region
#use 'half' for where for a region to take up the full region, its average brownness must equal
#the max brownness of a pixel on the cake.
#or give a number e.g. 50 which will be the value a region must have as its average brownness
#to take up the full region

#drawRadialGraphOnIm(im, kmMatrix, brownMatrix, indexMap, 'half')

#drawRadialGraphOnMaskedIm(imMat, kmMatrix, brownMatrix, indexMap, 'half')

#If you want the rectangles/squares/triangles on top use
#(doesnt plot image or masked image at start, so goes on top of current plot)
#drawRectangles(kmMatrix, indexMap) 

#For the next ones also use 'rectangles' for the representation like bar charts 
#in each of the 9 regions
#or use 'squares' for the representation of increasing squares centered at the centre
#of each region

#drawSquareGraphOnIm(im, kmMatrix, brownMatrix, indexMap, 'half','rectangles')

#drawSquareGraphOnIm(im, kmMatrix, brownMatrix, indexMap, 'half','squares')

#drawSquareGraphOnIm(im, kmMatrix, brownMatrix, indexMap, 50,'rectangles')

#drawSquareGraphOnMaskedIm(imMat, kmMatrix, brownMatrix, indexMap, 'half', 'rectangles')

#drawSquareGraphOnMaskedIm(imMat, kmMatrix, brownMatrix, indexMap, 'half', 'squares')

#This was used to test Owain's theory of the 3 arrows creating a closed traingle.
#I started each arrow where the previous one ended.
#NOT LOADED INTO REPRESENTATIONS ANYMORE CHECK OLD FOLDER
#drawOwainOnIm(im, kmMatrix, indexMap)

#Used to give the ratings of each cake, arrow rating, radial rating and overall
#Use 'circular' when the biscuit/cake is circular
#Use 'rectangular' when the biscuit/cake is a rectangle/square
#giveRating(kmMatrix, indexMap, 'rectangular')

#Each time i changed something in representations i used this to refresh functions
#so they could be tested.
#source('T:\\Image Archive [ALL]\\Customers\\CR\\BakeUniformity\\aCode\\representations.R')