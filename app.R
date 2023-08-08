library(shiny)
library(tidyverse)
library(bitGPT)
library(shinythemes)  # load shinythemes for better aesthetics

generate_random_filename <- function() {
  format(Sys.time(), "%Y%m%d_%H%M%S") |> 
    paste0("_", sample(1:1e5, 1)) 
}

api_key <- read_lines("apikey.txt")

ui <- fluidPage(
  # Set app title and theme
  title = "Image Generator App",
  theme = shinytheme("cerulean"),
  
  # Custom CSS
  tags$style("
      body {
          font-family: 'Arial', sans-serif;
      }
      .btn {
          background-color: #4CAF50;
          color: black;
          margin-top: 10px;
      }
      .sidebar {
          background-color: #f4f4f4;
      }
  "),
  
  # Define the layout using fluid rows and columns
  sidebarLayout(
    sidebarPanel(
      fluidRow(
        # Using column layout for better aesthetics
        column(6, selectInput("dropdown_artist", label = "아티스트", 
                              choices = c("Peter Mohrbacher", "Craig Mullins", "Refer", "Ashley Wood", 
                                          "hajime sorayama", "floria sigismondi", "matt mahurin", "robert mapplethorope"))),
        column(6, selectInput("dropdown_light", label = "빛", 
                              choices = c("monochromatic", "uplight", "neon light", "soft light", 
                                          "cinematic light", "volumetric light"))),
        column(6, selectInput("dropdown_resolution", label = "해상도", 
                              choices = c("hd", "4k", "8k", "extreme detail", "highly detail", "hyper detail"))),
        column(6, selectInput("dropdown_camera", label = "카메라 뷰", 
                              choices = c("ultra wide-angle", "street level view", "panoramic", "top view", 
                                          "low angle view", "bird-eye view"))),
        column(6, selectInput("dropdown_picture", label = "사진", 
                              choices = c("analog photography", "nature photography", "80s photography", "cinematic photography"))),
        column(6, selectInput("dropdown_style", label = "스타일", 
                              choices = c("concept art", "digital art", "digital painting", "sketch", 
                                          "matte painting", "pop art", "line art", "manga", "stencil art", 
                                          "crayon", "chalk", "oil paintings", "Abstract Expressionism", 
                                          "Abstraction", "Academic", "Action painting", "Aesthetic", 
                                          "Allover painting", "Angular", "Appropriation", 
                                          "Architecture", "Artifice", "Automatism", "Avant-garde", 
                                          "Baroque", "Bauhaus", "Contemporary", "Cubism", "Cyberpunk", 
                                          "Digital art", "Fantasy", "Impressionism", "Minimal", "Modern", 
                                          "Pixel art", "Realism", "Surrealism"))),
        column(12, textInput("imagePrompt", "생성할 이미지(먹음직스러운 백작수수쌀과 토마토):", "delicious Count's rice and tomato")),
        column(12, actionButton("drawButton", "이미지 생성 실행!"))
      )
    ),
    
    mainPanel(
      uiOutput("displayImageUI"),
      textOutput("textPromptOutput")
    )
  )
)

server <- function(input, output) {
  
  # Initially, set the output to the default image
  output$displayImageUI <- renderUI({
    tags$img(src = "kwangmyung_ChatGPT.jpg", width = "512px", height = "512px", alt = "Default Image")
  })
  
  observeEvent(input$drawButton, {
    
    # 결합된 텍스트 생성
    image_gen_prompt <- paste0(input$imagePrompt, ", ", input$dropdown_artist, ", ", 
                               input$dropdown_resolution, ", ", input$dropdown_camera, ", ", 
                               input$dropdown_picture, ", ", input$dropdown_style, 
                               sep = " ")
    
    output$textPromptOutput <- renderText({   # <- This is new
      cat(glue::glue("\n\n'{image_gen_prompt}'"))
    })
    
    gen_filename <- generate_random_filename()
    
    draw_img(
      prompt = image_gen_prompt,
      ko2en = FALSE,
      n = 1L,
      size = "512x512",
      type = "file",
      format = "png",
      path = "www",
      fname = gen_filename,
      # openai_api_key = Sys.getenv("OPENAI_API_KEY")
      openai_api_key = api_key
    )

    # Display the image using renderUI
    output$displayImageUI <- renderUI({
      tags$img(src = paste0(gen_filename, ".png"), width = "512px", height = "512px", alt = "Generated Image")
    })

  })
}
 

# Run the application 
shinyApp(ui = ui, server = server)
