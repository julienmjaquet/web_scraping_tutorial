***Introduction to web scraping using R*** <br/>

This tutorial was originally written for a bachelor course at the University of Fribourg, Switzerland, on November 2024. <br/>

For the purpose of this tutorial, we are going to retrieve data from Wikipedia. More specifically, we are going to retrieve the table of all [Swiss municipalities](https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden]). <br/>

First, we have to load the necessary libraries and set the working path.
``` 
library(rvest)
library(dplyr)
library(stringr)
library(gtable)
library(RSwissMaps)

setwd("C:/Users/Username/MyFolder/")
```






