# Analysing shipping vessel locations 
## Appsilon Data   

Versions:  
 - R 3.5.0  
 - RStudio 1.1.453      

******

File extensions:   
.R  
.Rda  
.dcf 

******  

## Overview      

Shiny app for analysing maritime vessel GPS location and transportation/movement data     

[Launch the Shiny app](https://darwinanddavis.shinyapps.io/ships/)    

### Analysis  

* Users select a vessel type     
* Users select a vessel name     
* The app calculates the observations when the vessel sailed the longest distance between two consecutive time points     

Data analysis    

Below is pseudocode describing some of the analysis. More detailed code is available in `app.R`.   

Distance travelled was calculated using `speed` and `elapsed` variables.  

```
ships %>%
      select(LON,LAT,SHIPNAME,ship_type,ELAPSED,SPEED,DATETIME) %>%
      rename(SHIP_TYPE=ship_type) %>%
      mutate(DISTANCE = SPEED*ELAPSED + lead(SPEED*ELAPSED, default = 0))
    
```

User can select a vessel name belonging to the type of ship based on the following code. The distance between latlon location is then calcualted between consecutive time points. The maximum distance is then calculated according to the most recent timestamp. 

```
ships %>% filter(SHIP_TYPE %in% input$select_type & SHIPNAME %in% input$select_name) %>%
 top_n(1, DISTANCE) %>%
  arrange(desc(DATETIME)) %>%
   slice(1) %>% 
   pull(DISTANCE)

```

The origin and destination latlon points are then plotted on a world map. Locations, vessel info, and distance update as user selects new vessels.  

Full code available in `app.R`.      

## Maintainer      
**Matt Malishev**       
:mag: [Website](https://darwinanddavis.github.io/DataPortfolio/)        
:bird: [@darwinanddavis](https://twitter.com/darwinanddavis) <a><img src="https://img.shields.io/twitter/follow/darwinanddavis.svg?label=Follow%20@darwinanddavis" alt="Follow @darwinanddavis"/></a>    
:email: matthew.malishev [at] gmail.com          

