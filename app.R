# install.packages('rsconnect')
require(shiny)
require(shinythemes)
require(shiny.semantic)
require(shinycssloaders)
require(dplyr)
require(readr)
require(leaflet)
require(leaflet.extras)
require(colorspace)
require(reshape2)
require(stringr)
require(scales)
require(rsconnect)
require(htmltools)
require(here)
require(RColorBrewer)
require(tidyr)
require(purrr)
require(lubridate)
require(metathis)

# here::here() %>% runApp()

# get data
ships <- "https://github.com/darwinanddavis/ships/raw/master/data/ships_df.Rda" %>% url() %>% readRDS()
vessel_type <- ships %>% pull(SHIP_TYPE) %>% unique
vessel_name <- ships %>% pull(SHIPNAME) %>% unique

ui <- semanticPage(
  # title -------------------------------------------------------------------
  div(class = "ui raised segment", 
      theme = shinytheme(theme = "cyborg"),
      tags$style(type = "text/css", "html, body {width:100%;height:100%;background-color:black;}"),
      titlePanel(tags$h1(span("Analysing shipping vessel locations | "),span(style="color:#0099F9;","Appsilon Data"),.noWS="outside")) # title
  ),
  # user input  -------------------------------------------------------------
  div(class = "ui raised segment",
      div(class = "ui grid",
          div(class="two column row",
              div(class = "column",
                  segment(
                    h3(icon("ship"),"Select vessel type"),
                    dropdown_input("select_type", vessel_type, default_text = "Select type of vessel",type = "selection fluid")
                  )),
              div(class = "column",
                  segment(
                    h3(icon("pencil alternate"),"Select vessel name"),
                    dropdown_input("select_name", vessel_name, default_text = "Select name of vessel",type = "selection fluid")
                  ))),
          p()
          # actionButton("simple_button2", "Update input to use all letters")
      )), # seg1
  # text output ---------------------------------------------------------------------
  div(class = "ui raised segment",
      segment(
        h4("Distance between points (m)"),  
        textOutput("distance")
      )
  ),
  # map ---------------------------------------------------------------------
  div(class = "ui raised segment",
      mainPanel(width = "100%",
                leafletOutput("map")
      )
  ), # div2
  mainPanel( # footer
    tags$p(span(style="text-align:left; color:#FFFFFF;",
                strong("Author: "),"Matt Malishev","|",
                strong("Github: "),
                span(style="color:#FF385C;",a(style="color:#0099F9;","@darwinanddavis",href="https://github.com/darwinanddavis/ships"))
    ))
  )
)


server <- shinyServer(function(input, output, session) {
  
  # filter vessel type
  get_vessel <- reactive({
    ships %>% filter(SHIP_TYPE %in% input$select_type)
  })
  
  # vessel name
  vessel_name <- reactive({
    get_vessel() %>% pull(SHIPNAME) %>% unique
  })
  
  # vessel options
  observeEvent(input$select_type, {
    update_dropdown_input(session, "select_name", 
                          choices = vessel_name(),
                          choices_value = vessel_name())
  })
  
  # filtered data
  map_event <- reactive({
    ships %>% filter(SHIP_TYPE %in% input$select_type & SHIPNAME %in% input$select_name)
  })
  
  output$data <- renderTable({
    map_event() %>% head 
  },rownames = T)
  
  # distance
  map_distance <- reactive({
    map_event() %>% 
      top_n(1, DISTANCE) %>% arrange(desc(DATETIME)) %>% slice(1) %>% pull(DISTANCE)
  })
  
  # origin
  map_origin <- reactive({
    map_event()[which(map_event()$DISTANCE %in% map_distance())-1,] %>% top_n(1,DATETIME) %>%  # get most recent date 
      mutate(COL="#2F0C58",
             LABEL="Origin")
  })
  
  # destination
  map_dest <- reactive({
    map_event()[which(map_event()$DISTANCE %in% map_distance()),] %>% top_n(1,DATETIME) %>%  
      mutate(COL="#DC8E2A",
             LABEL="Destination")  
  })
  
  # get distance m
  output$distance <- renderText({
    paste0((map_origin() %>% pull(DISTANCE)- map_dest() %>% pull(DISTANCE))  %>% abs)
  })
  
  # labels ------------------------------------------------------------------
  
  # map label
  map_label <- reactive({
    popup <- function(pid){
      map_event() %>% pull(pid) 
    }
    paste0(
      "<div style=\"font-size:15px;\">",
      "<strong> Ship type </strong>","<br/>",popup("SHIP_TYPE"),"<br/>",
      "<strong> Ship name </strong>","<br/>",popup("SHIPNAME"),"<br/>",
      "</div>"
    ) %>% map(htmltools::HTML) 
  })
  
  
  # style -------------------------------------------------------------------
  
  # map tile
  custom_tile <- "Esri.WorldGrayCanvas"
  
  # current colpal
  opac <- 0.7
  font_size <- 20
  
  # style
  style <- list(
    "color" = "black",
    "font-size" = "10px",
    "font-weight" = "normal",
    "padding" = "5px 5px"
  ) 
  # label options
  text_label_opt <- labelOptions(noHide = F, direction = "top",
                                 textOnly = F, opacity = 1, offset = c(0,0),
                                 style = style, permanent = T
  )
  
  # easy buttons
  locate_me <- easyButton( # locate user
    icon="fa-crosshairs", title="Zoom to my position",
    onClick=JS("function(btn, map){ map.locate({setView: true}); }"));
  
  reset_zoom <- easyButton( # reset zoom
    icon="fa-home", title="Reset zoom",
    onClick=JS("function(btn, map){ map.setZoom(10);}"));
  
  # layer options
  layer_options <- layersControlOptions(collapsed = F)
  min_zoom = 3
  max_zoom = 16  
  
  # make map   --------------------------------------------------------------
  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(worldCopyJump = T)) %>%
      addTiles(
        options = providerTileOptions(minZoom=min_zoom, maxZoom=max_zoom)) %>%
      addProviderTiles(custom_tile,
                       options = providerTileOptions(minZoom=min_zoom, maxZoom=max_zoom)) %>%
      addCircles(data = map_origin(), 
                 lng = ~LON, lat = ~LAT,
                 radius = 30,
                 color = ~COL,
                 fill = ~COL,
                 fillColor = ~COL,
                 weight = 1,
                 opacity = opac,
                 fillOpacity = opac,
                 label = map_label(),
                 labelOptions = text_label_opt) %>%
      addCircles(data = map_dest(), 
                 lng = ~LON, lat = ~LAT,
                 radius = 30,
                 color = ~COL,
                 fill = ~COL,
                 fillColor = ~COL,
                 weight = 1,
                 opacity = opac,
                 fillOpacity = opac,
                 label = map_label(),
                 labelOptions = text_label_opt) %>%
      addEasyButton(reset_zoom) %>%
      addEasyButton(locate_me) %>% 
      addLegend("bottomright",title = "Vessel key",
                colors = c(map_origin()$COL,map_dest()$COL),
                labels = c(map_origin()$LABEL,map_dest()$LABEL))
  })
}) 

shinyApp(ui = ui, server = server)