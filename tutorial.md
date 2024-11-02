# Introduction to web scraping using R <br/>

This tutorial was originally written for a bachelor course at the University of Fribourg, Switzerland, on November 2024 (see the full code in one chunk at the end of this page) <br/>

For the purpose of this tutorial, we are going to retrieve data from Wikipedia. More specifically, we are going to retrieve data on all [Swiss municipalities](https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden). <br/>

First, we have to load the necessary libraries and set the working path.
``` 
library(rvest)
library(dplyr)
library(stringr)
library(gtable)
library(RSwissMaps)

setwd("C:/Users/Username/MyFolder/")
```

## Step 1 : retrieve the table listing all municipalities <br/>

Define the webpage we are going to retrieve and read the page
```
link <- "https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden"
webpage <- read_html(link)
``` 

Extract the table (by specifying the character used as a decimal place marker).
``` 
table <- webpage %>%
  html_table(dec=",")
```
The newly created object `table' is a list containing the data.frame (tibble). We are going to extract the first (and only) object of the list.
```
swissdata <- table[[1]]
```
You should obtain a table like this one : <br/>
![alt text](https://github.com/julienmjaquet/web_scraping_tutorial/blob/main/table_gemeinden.png)
<br/>
As can be seen, the column/variable "Einwohner" is of the character type because of the *thousands separator* which prevents R to automatically recognize it as a numeric variable.
```
is.character(swissdata$Einwohner)
```
```
[1] TRUE
```
We can remove it and transform the variable into a numeric one.
```
swissdata$Einwohner <- str_replace(swissdata$Einwohner,"'","")
swissdata$Einwohner <- as.numeric(swissdata$Einwohner)
```
<br/>
## Step 2 : retrieve links to Swiss municipalities wikipedia pages <br/>
The links are part of the html page we already retrieved (object "webage"). We are going to extract all links (in html code: "href") contained in the table only.

```
links <- webpage %>% 
  html_nodes(xpath = "//table//a")  %>%
  html_attr("href")
```
For each municipality, we actually retrieved 3 links : one to the municipality wiki page, one to the kanton wiki page and one to the flag of the kanton. This is why we have 3 times more links than needed.
```
length(links)
```
```
[1] 6393
```
We can remove the links we are not interested by identifying those that contain the terms ".svg" (image file) or "Kanton."
```
check <- grepl(".svg|Kanton",links)
links <- links[check=="FALSE"]
head(links)
```
```
[1] "/wiki/Aadorf"    "/wiki/Aarau"     "/wiki/Aarberg"   "/wiki/Aarburg"   "/wiki/Aarwangen" "/wiki/Abtwil_AG"
```



**Step 3 : loop over all municipalities web pages to retrieve additional information** <br/>









