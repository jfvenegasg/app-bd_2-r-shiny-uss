#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(bigrquery)
library(googleCloudStorageR)
library(echarts4r)

bigrquery::bq_auth(path ="shiny-apps-385622-08e5b9820326.json")
googleCloudStorageR::gcs_auth(json_file = "shiny-apps-385622-0553170e693d.json")
#googleCloudStorageR::gcs_list_buckets("shiny-apps-385622")

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Esta es una aplicación de demostración desarrollada con la libreria shiny en R"),
    fluidRow(imageOutput("imagen")),
    # Sidebar with a slider input for number of bins 
    fluidRow(sidebarLayout(
        sidebarPanel(
            sliderInput("bins",
                        "Numero de columnas:",
                        min = 1,
                        max = 50,
                        value = 30)
        ),

        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("distPlot")
        )
    )),
    fluidRow(actionButton(inputId = "boton",label =  "Descarga")),
    fluidRow(dataTableOutput("datos_bigquery")),
    fluidRow(echarts4rOutput("grafico_bigquery"))
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    output$imagen <- renderImage({
    googleCloudStorageR::gcs_get_object(object_name ="uss.png" ,bucket = "imagenes_app_uss",saveToDisk ="uss_GCS.png",overwrite = TRUE )
    
    list(src = "uss_GCS.png")
    
    }, deleteFile = F)
    
    output$distPlot <- renderPlot({
        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white',
             xlab = 'Waiting time to next eruption (in mins)',
             main = 'Histogram of waiting times')
    })
    
    #Aca se define el proyecto que tenemos activo en GCP
    project_id <- "shiny-apps-385622"
    
    sql<-"SELECT * from `bigquery-public-data.austin_bikeshare.bikeshare_trips` LIMIT 30"
    
    respuesta <- reactiveValues(data=NULL)
    
    observeEvent(input$boton, {
      consulta <- bigrquery::bq_project_query(project_id, sql)
      respuesta$datos <-bigrquery::bq_table_download(consulta,n_max = 30)
    })
    
    output$datos_bigquery<-renderDataTable({respuesta$datos})
    
    #Aca se genera el grafico,de acuerdo a los datos extraidos en la consulta SQL.
    #El grafico muestra en el eje x el tipo de suscriptor y en el eje y la duracion en minutos de los viajes
    output$grafico_bigquery<-renderEcharts4r({
      if(is.null(respuesta$datos)==TRUE){
        
      }else{
        datos_graficos <- respuesta$datos %>%
          group_by(subscriber_type) %>%
          summarise(duration_minutes = sum(duration_minutes))
        
        datos_graficos |>
          echarts4r::e_chart(subscriber_type) |>
          echarts4r::e_bar(duration_minutes) |>
          echarts4r::e_theme("walden")  
      }
      
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)
