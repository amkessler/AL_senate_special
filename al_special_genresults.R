library(tmap)
library(tmaptools)
library(tigris)
library(dplyr)
library(rio)
library(leaflet)
library(htmlwidgets)

library(ggplot2)
library(reshape2)
library(gridExtra)
library(knitr)

options(tigris_class = "sf")

#import AL counties map
al_geo <- counties("AL")
al_geo$NAME

#add field with uppercase county name
al_geo$cap.NAME <- toupper(al_geo$NAME)
al_geo$cap.NAME <- trimws(al_geo$cap.NAME)
al_geo$cap.NAME <- gsub("[^[:alpha:]]", "", al_geo$cap.NAME)
al_geo$cap.NAME


#---Import original spreadsheet from AL Sec of State, clean it up

#import AL special election results
results_orig <- rio::import("al_special_jonesmoore.xlsx")
results_orig
names(results_orig) 
str(results_orig)

results_orig$`Candidate Name` <- as.factor(results_orig$`Candidate Name`)
results_orig$`Contest Code` <- as.factor(results_orig$`Contest Code`)
results_orig$`Contest Title` <- as.factor(results_orig$`Contest Title`)

#remove uneeded fields
results_orig2 <- results_orig[,c(4,6, 7,8,9,10)]
head(results_orig2)

#clean up field names
names(results_orig2) <- c("county.name", "contest.title", "cand.id", "candidate", "votes", "party")
head(results_orig2)

#filter for only senate race votes - no tax issues etc.
results <- filter(results_orig2, contest.title == "UNITED STATES SENATOR")


#add field with uppercase county name
results$cap.name <- toupper(results$county.name)
results$cap.name <- trimws(results$cap.name)
#remove all non alphabetic characters
results$cap.name <- gsub("[^[:alpha:]]", "", results$cap.name)
results$cap.name
head(results)

# ***use DCAST() from the RESHAPE2 package to move the candidates' vote numbers 
#onto one line per county, with each name across
results2 <- dcast(results, cap.name ~ candidate, value.var = "votes", fill = 0)

head(results2,10)

#clean up new field names
names(results2) <- c("county", "jones", "moore", "writein")

#calculate total vote count and percentages
results2$jones.pct <- round(results2$jones / (results2$jones+results2$moore+results2$writein),2)
results2$moore.pct <- round(results2$moore / (results2$jones+results2$moore+results2$writein),2)
results2$writein.pct <- round(results2$writein / (results2$jones+results2$moore+results2$writein),2)

#Now the data is done and ready
head(results2)


#----- making the map ------

#JOIN the data and geospatial files
votemap <- append_data(al_geo, results2, key.shp = "cap.NAME", key.data = "county")

#perfect match!!

votemap
names(votemap)

#one way, with a "quick" map
qtm(votemap, fill = "jones.pct")
qtm(votemap, fill = "moore.pct")

#more robust way, with tmap() function
tm_shape(votemap) +
  tm_polygons("jones.pct", id = "NAME")

#To make this interactive, you just need to switch 
#tmap's mode from "plot," which is static, to "view", which is interactive, 
#using the tmap_mode() function:
tmap_mode("view")
#to redraw last map
tmap_last()

#once tmap mode is set as "view" it should remain for other maps until
#you change it back to "plot"
tm_shape(votemap) +
  tm_polygons("moore.pct", id = "NAME") +
  tm_layout(title = "Alabama Special Election") 

tm_shape(votemap) +
  tm_polygons("writein.pct", id = "NAME") +
  tm_layout(title = "Alabama Special Election")

#now use leaflet too

my_interactive_map <- tm_shape(votemap) +
  tm_polygons("jones.pct", id = "NAME") +
  tm_layout(title = "Alabama Special Election") 

#--how to **SAVE** tmap map to an html file:
# save_tmap(my_interactive_map, "alspecial_jones.html")

#turn into leaflet object
votemap_leaflet <- tmap_leaflet(my_interactive_map)

votemap_leaflet



#### Some slicing and dicing of the election results using dcast
head(results)

head(dcast(results, cap.name ~ candidate, value.var = "votes", fill = 0))

head(dcast(results, cap.name ~ party, value.var = "votes", fill = 0))

head(dcast(results, cap.name+party ~ candidate, value.var = "votes", fill = 0))

head(dcast(results, party ~ candidate, value.var = "votes", fill = 0)) #defaults to length
head(dcast(results, party ~ candidate, sum, value.var = "votes", fill = 0)) #add sum function

#totals per race, candidates across 
head(dcast(results, contest.title ~ candidate, value.var = "votes", fill = 0))
head(dcast(results, contest.title ~ candidate, sum, value.var = "votes", fill = 0))


