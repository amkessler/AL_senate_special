library(tmap)
library(tmaptools)
library(tigris)
library(dplyr)
library(rio)
library(leaflet)
library(htmlwidgets)
options(tigris_class = "sf")

#import AL counties map
al_geo <- counties("AL")
al_geo$NAME

#add field with uppercase county name
al_geo$cap.NAME <- toupper(al_geo$NAME)
al_geo$cap.NAME <- trimws(al_geo$cap.NAME)
al_geo$cap.NAME <- gsub("[^[:alpha:]]", "", al_geo$cap.NAME)
al_geo$cap.NAME

#import AL special election results
results <- rio::import("al_special_results.xlsx")
results
names(results) 
str(results)

#add field with uppercase county name
results$cap.name <- toupper(results$county.name)
results$cap.name <- trimws(results$cap.name)
results$cap.name <- gsub("[^[:alpha:]]", "", results$cap.name)
results$cap.name

#JOIN the data and geospatial files
votemap <- append_data(al_geo, results, key.shp = "cap.NAME", key.data = "cap.name")
#perfect match!! 

votemap
names(votemap)

#----- making the map

#one way, with a "quick" map
# qtm(votemap, fill = "pct.moore")
# qtm(votemap, fill = "pct.strange")

#more robust way, with tmap() function
tm_shape(votemap) +
  tm_polygons("rounded.strange", id = "NAME")

#To make this interactive, you just need to switch 
#tmap's mode from "plot," which is static, to "view", which is interactive, 
#using the tmap_mode() function:
tmap_mode("view")
#to redraw last map
last_map()

#once tmap mode is set as "view" it should remain for other maps until
#you change it back to "plot"
tm_shape(votemap) +
  tm_polygons("rounded.moore", id = "NAME") +
  tm_layout(title = "Alabama Special Election") 



#now use leaflet too

my_interactive_map <- tm_shape(votemap) +
  tm_polygons("rounded.strange", id = "NAME")

#SAVE tmap map to an html file:
save_tmap(my_interactive_map, "alspecial1.html")

