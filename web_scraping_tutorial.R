################################################################################
#                   Introduction to web scraping using R                       #
#                                                                              #
#                              November 2024                                   #
#                                                                              #
################################################################################

library(rvest)
library(dplyr)
library(stringr)
library(stringi)
library(gtable)
library(RSwissMaps)

setwd("C:/Users/Username/MyFolder/")


################################################################################
###PART I###

link <- "https://de.wikipedia.org/wiki/Liste_Schweizer_Gemeinden"
webpage <- read_html(link)

table <- webpage %>%
  html_nodes("table.wikitable") %>%
  html_table(dec=",")

swissdata <- table[[1]]

is.character(swissdata$Einwohner)

swissdata$Einwohner <- str_replace(swissdata$Einwohner,"'","")
swissdata$Einwohner <- as.numeric(swissdata$Einwohner)


################################################################################
###PART II###

links <- webpage %>% 
  html_nodes(xpath = "//table//a")  %>%
  html_attr("href")

length(links)

check <- grepl(".svg|Kanton",links)
links <- links[check=="FALSE"]
head(links)

links <- paste("https://de.wikipedia.org",links,sep="")
head(links)

swissdata$links <- links
View(swissdata)


################################################################################
###PART III###

personalities <- data.frame()

swissdata <- swissdata[sample(nrow(swissdata)),]


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




