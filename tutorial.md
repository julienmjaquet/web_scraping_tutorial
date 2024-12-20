# Introduction to Web Scraping Using R <br/>

For this tutorial, we will retrieve data from Wikipedia, specifically data on all [Swiss municipalities](https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden) and their associated notable personalities. <br/>
<br/>
Before starting any automatic data retrieval from a web page, one should always read the ["robots.txt" file](https://en.wikipedia.org/robots.txt) and **follow its instructions**. In our example, it reads as follows: <br/>

> "*[...] There are a lot of pages on this site, and there are some misbehaved spiders out there that go _way_ too fast. If you're irresponsible, your access to the site may be blocked.*" <br/>

First, we need to load the necessary libraries and set the working directory.
``` 
library(rvest)
library(dplyr)
library(stringr)
library(stringi)
library(gtable)
library(RSwissMaps)

setwd("C:/Users/Username/MyFolder/")
```

## Part 1: Retrieve the Table Listing All Municipalities <br/>

Define the webpage we are going to retrieve and read the page.
```
link <- "https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden"
webpage <- read_html(link)
``` 
Identify the correct nodes and extract the tables by specifying the character used as a decimal place marker.
``` 
table <- webpage %>%
  html_nodes("table.wikitable") %>%
  html_table(dec=",")
```
The newly created object `table` is a list containing the data frame (tibble). We will extract the first (and only) object of the list.
```
swissdata <- table[[1]]
```
You should obtain a table like this one : <br/>
![alt text](https://github.com/julienmjaquet/web_scraping_tutorial/blob/main/table_gemeinden.png)
<br/>
As can be seen, the column/variable "Einwohner" is of the character type because of the *thousands separator* prevents R from automatically recognizing it as a numeric variable.
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

## Part 2: Retrieve Links to Swiss Municipalities' Wikipedia Pages <br/>

The links are part of the HTML page we already retrieved (object "webpage"). We are going to extract all links (in HTML code: "href") contained in the table only.

```
links <- webpage %>% 
  html_nodes(xpath = "//table//a")  %>%
  html_attr("href")
```
For each municipality, we actually retrieved three links: one to the municipality's wiki page, one to the canton's wiki page, and one to canton's flag. Hence, three times more links retrieved.
```
length(links)
```
```
[1] 6393
```
We can remove the links we are not interested in by identifying those that contain the terms ".svg" (image file) or "Kanton."
```
check <- grepl(".svg|Kanton",links)
links <- links[check=="FALSE"]
head(links)
```
```
[1] "/wiki/Aadorf"    "/wiki/Aarau"     "/wiki/Aarberg"   "/wiki/Aarburg"   "/wiki/Aarwangen" "/wiki/Abtwil_AG"
```
Links retrieved in such a way typically do not include the root part of the web link. Thus, we need to add it.
```
links <- paste("https://de.wikipedia.org",links,sep="")
head(links)
```
```
[1] "https://de.wikipedia.org/wiki/Aadorf"    "https://de.wikipedia.org/wiki/Aarau"    
[3] "https://de.wikipedia.org/wiki/Aarberg"   "https://de.wikipedia.org/wiki/Aarburg"  
[5] "https://de.wikipedia.org/wiki/Aarwangen" "https://de.wikipedia.org/wiki/Abtwil_AG"
```
Now, we can add it to our table.
```
swissdata$links <- links
View(swissdata)
```
![alt text](https://github.com/julienmjaquet/web_scraping_tutorial/blob/main/table_gemeinden2.png)


## Part 3.1: Loop Over All Municipalities' Web Pages to Retrieve Additional Information <br/>

We are going to loop over all of the municipalities' wiki pages to retrieve data about notable personalities associated to each municipality. Most municipalities include a section about personalities. <br/>

First, we generate an empty data frame where we will store the results. 
```
personalities <- data.frame()
```
Not all pages include a notable "personalities" section. Pages that do include such a section may vary slightly in their HTML code. By randomly checking a few pages manually, we can get an idea of how a page is organized. However, we cannot be sure that we have accounted for all variants. Thus, it may be useful to test our R code on a few randomly chosen pages (and repeat the operation until we obtain the desired results). For this purpose, it is useful to shuffle our data before each try.
```
swissdata <- swissdata[sample(nrow(swissdata)),]
```
We are now ready to loop over all rows of the data frame "swissdata", which contains all municipalities' web links. Each part of the loop is described separately below.

```

for (i in 1:nrow(swissdata)){
  
  link <- swissdata$links[i]
  webpage <- read_html(link)

  personalichkeiten <- webpage %>%
    html_elements("h2,ul") %>%
    html_text2()
  check <- which(personalichkeiten=="Persönlichkeiten"|personalichkeiten=="Söhne und Töchter")


  if (length(check) == 1){
    personalichkeiten <- personalichkeiten[check+1]
    personalichkeiten <- unlist(strsplit(personalichkeiten, "\n"))

    titles <- webpage %>%
      html_elements("h2") %>%
      html_text2()

    check2 <- personalichkeiten %in% titles
    check2 <- check2[1]

    if (check2==FALSE){

      for (j in 1:length(personalichkeiten)){

      test <- grepl("[0-9]",personalichkeiten)[j]

        if (test == TRUE){
          a <- unlist(strsplit(personalichkeiten[j],"),"))
          b <- unlist(strsplit(a[1],"\\("))
          name <- b[1]
          geburtsjahr <- stri_extract_first_regex(b[2], "[0-9][0-9][0-9][0-9]")
          todesjahr <- stri_extract_last_regex(b[2], "[0-9][0-9][0-9][0-9]")
          same <- geburtsjahr == todesjahr
          todesjahr[same==TRUE] <- NA
          beschreibung <- a[2]
        }else{
          a <- unlist(strsplit(personalichkeiten[j],","))
          name <- a[1]
          geburtsjahr <- NA
          todesjahr <- NA
          beschreibung <- paste(a[2:length(a)], collapse =" ")
        }    
        gemeinde <- swissdata$`Offizieller Gemeindename`[i]
        kanton <- swissdata$Kanton[i]
        bfs_nr <- swissdata$`BFS-Nr.`[i]
        personalities_j <- data.frame(name,geburtsjahr,todesjahr,beschreibung,gemeinde,bfs_nr,kanton)
        personalities <- rbind(personalities,personalities_j)
      }
    }
  rm(check,check2)
  }
Sys.sleep(runif(1, 5, 10))
print(paste("Retrieved data from '",swissdata$`Offizieller Gemeindename`[i],"' webpage : ", round( (i / length(swissdata$Kanton))*100,2)," % done",sep=""))
}
```
**N.B.** In its current form, the code takes about 4 hours 45 minutes to retrieve all data because of the line ```Sys.sleep(runif(1, 5, 10))```, which randomly pauses between 5 and 10 seconds between each iteration.
While it is possible to increase the speed of data retrieval, you may blocked by the website if it detects an unsual amount of requests in a short period of time coming from your IP address. Thus, use it at your own risks. More importantly, be respectful of the website you are scraping and avoid overloading the server. Certainly, this can also be achieved with a shorter pause time between each iteration. <br/>

Note also that it may be possible to achieve a more efficient code (with fewer lines of code).

<br/>
In the end, your dataset should look like this (here's a sample based on about 13% of all municipalities' notable personalities) : <br/>

![alt text](https://github.com/julienmjaquet/web_scraping_tutorial/blob/main/table_personalities.png)

-----------------------------------------------------------------------------------------------------------------------------------------------------------
**N.B.** If you wish to use the retrieved data for analysis, you may want to consider the following points: <br/>
* Some pages do not include a "personalities" section but link to an external page specifically dedicated to the notable personalities of a given municipality. Data from these pages was not retrieved.
* Some pages simply do not include a "personalities" section. This does not mean there aren't any notable personalities related to the municipality.
* Some pages do not have a proper "personalities" section but mention "personalities" in other sections. Data from other sections was not retrieved.
* The code is based on Wikipedia pages in German. It is therefore possible that Swiss German municipalities have, on average, a longer list of notable personalities compared to French-speaking or Italian-speaking municipalities. However, such a difference may come from the fact that German-speaking Wikipedia authors know less about personalities from other regions.
* A given name may appear several times in the data. For example, in the municipality a person was born and in the municipality they spent most of their life. 
------------------------------------------------------------------------------------------------------------------------------------------------------------

## Part 3.2: Review of the Loop

Now, let us review the loop in more detail. <br/>

We are going to loop over all rows of the dataframe "swissdata" using the link retrieved previously. 
```
for (i in 1:nrow(swissdata)){

#code to repeat at each iteration

}
```
At each iteration, we first want to extract the web link of the municipality in row `i` and read the HTML page.
```
  link <- swissdata$links[i]
  webpage <- read_html(link)
```
Then, we retrieve all section titles ("h2") and lists ("ul"), which we transform into text with ```htm_text2()```.
```
  personalichkeiten <- webpage %>%
    html_elements("h2,ul") %>%
    html_text2()
```
We want to identify which section refers to "personalities". This command gives the position in "personlichkeiten" where the words "Persönlichkeiten" or "Söhne und Töchter" can be found (if any). We store this information in the object "check".
```
 check <- which(personalichkeiten=="Persönlichkeiten"|personalichkeiten=="Söhne und Töchter")
```
The next part of the code will only be executed if a "Personalities" section is found (that is, if the object "check" is not of null length). Otherwise, the iteration continues at the very end of the loop with ```Sys.sleep()```.
```
if (length(check) == 1){

}
```
Now, let us extract the names of the notable personnalities. They are located just after the title of the section (hence, ```[check+1]```). The rest of the text included in the object "personalichkeiten" is erased. Then, we need to split the character object into several parts (i.e., make it a vector). Since each name appears on a new line, we can use the character defining a new line ("\\n") to split the whole text (a unique character object) into several parts (command ```strsplit()```). Since the returned object is a list, we still need to unlist it with the command ```unlist()```.
```
    personalichkeiten <- personalichkeiten[check+1]
    personalichkeiten <- unlist(strsplit(personalichkeiten, "\n"))
``` 
Some pages do include a "personalities" section, but the section links to an external page specifically dedicated to the notable personalities. In such cases, there are no personalities' names within the page. This means that at the position `check+1` in the `personalichkeiten` object, there is the title of the next section (which we do not want.) The code below accounts for that possibility by retrieving only the titles of the page ("h2") and making sure our "personalichkeiten" vector is not part of the titles (but consist of names). 
```
  titles <- webpage %>%
      html_elements("h2") %>%
      html_text2()
  check2 <- personalichkeiten %in% titles
  check2 <- check2[1]
```
If the content of the vector `personalichkeiten` is not part of the object `titles` ```(check2==FALSE)```, we assume it consists of personalities' names. In this situation, the part of the code below will be executed. If the vector `personalichkeiten` contains the title of a subsequent section, the script will skip the code below.
```
if (check2==FALSE){

}
```
We now want to extract each personality's name and information, one by one. Thus, we are going to loop over all the elements of the vector `personalichkeiten`. Since it's a vector, we specify ```length()``` instead of ```nrow()```. Additionally, we use a different letter than `i` for the inner loop (for example, `j`).
```
     for (j in 1:length(personalichkeiten)){

    }
```
In the process of extracting information about notable personalities, there are now two alternatives to consider. Either the vector contains information regarding the birth (and possibly the death) of a given personality, or it does not. In other words, either the vector contains numbers or it does not. We can test which alternative is correct with the following piece of code.
```
      test <- grepl("[0-9]",personalichkeiten)[j]
```
If the test is true, we want to execute the first part of the code (alternative A). If it is not, we want to execute the block of code in the `else` brackets (alternative B):
```
      if (test == TRUE){

      }else{

      }
```
Alternative A (test == TRUE): We extract the name of the person (part of the code before the parenthesis). Then we extract the first four-digit number (birth year) and the second four-digit number (year of death). If there is no year of death (the person is still alive), both commands should give the same result. If that is the case, we attribute a missing value to the `todesjahr` object. The description is located in the second part of the vector `a`.
```
          a <- unlist(strsplit(personalichkeiten[j],"),"))
          b <- unlist(strsplit(a[1],"\\("))
          name <- b[1]
          geburtsjahr <- stri_extract_first_regex(b[2], "[0-9][0-9][0-9][0-9]")
          todesjahr <- stri_extract_last_regex(b[2], "[0-9][0-9][0-9][0-9]")
          same <- geburtsjahr == todesjahr
          todesjahr[same==TRUE] <- NA
          beschreibung <- a[2]
```
Alternative B (test == FALSE): Same as before, but there is no number to extract, so that we attribute missing values to both birth and year of death. Here the description consists of all the remaining text included in the vector `a` (positions 2 to n, which we paste together).
```
          a <- unlist(strsplit(personalichkeiten[j],","))
          name <- a[1]
          geburtsjahr <- NA
          todesjahr <- NA
          beschreibung <- paste(a[2:length(a)], collapse =" ")
```
Regardless of the alternative, we now want to create the row we are going to add to the `personalities` data.frame. We extract the name of the municipality from the original `swissdata` dataframe (from row `i`), the canton and the BFS Id. We generate the dataframe based on all the generated objects. Finally, we bind the generated dataframe (of a single row, that is `personalities_j`) to the personalities dataframe.
```
        gemeinde <- swissdata$`Offizieller Gemeindename`[i]
        kanton <- swissdata$Kanton[i]
        bfs_nr <- swissdata$`BFS-Nr.`[i]
        personalities_j <- data.frame(name,geburtsjahr,todesjahr,beschreibung,gemeinde,bfs_nr,kanton)
        personalities <- rbind(personalities,personalities_j)
```
Let us remove the objects `check` and `check2` to ensure they do not exist before the next iteration (allowing to avoid some potential errors).
```
rm(check,check2)
```
The two last lines of the code are not absolutely necessary for the code to work properly, but they are still important. First, the command `Sys.sleep` pauses R for n seconds (a random time between 5 and 10 seconds). This aims to reduce the number of requests made to the server in a short amount of time. This is a good practice in general and also limits the risk of having your IP address being banned from a website. Finally, the command `print()` literally prints the desired message at each iteration. In this case, it gives us an idea of which iteration is currently being processed.
```
Sys.sleep(runif(1, 5, 10))
print(paste("Retrieved data from '",swissdata$`Offizieller Gemeindename`[i],"' webpage : ", round( (i / length(swissdata$Kanton))*100,2)," % done",sep=""))
```


> To conclude, it worth remembering that the process of scraping data from the web is often achieved by trial and error. This also means that there are several code variants that can achieve the same results.


