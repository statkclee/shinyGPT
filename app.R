library(shiny)

ui <- fluidPage(
  # Define the side panel
  sidebarLayout(
    sidebarPanel(
      # Dropdown 1
      selectInput("dropdown1", 
                  label = "Dropdown Menu 1", 
                  choices = c("Option 1.1", "Option 1.2", "Option 1.3")),
      
      # Dropdown 2
      selectInput("dropdown2", 
                  label = "Dropdown Menu 2", 
                  choices = c("Option 2.1", "Option 2.2", "Option 2.3")),
      
      # Text input for image description
      textInput("imagePrompt", "Enter image description:", 
                "blue sky and many pine trees with snowy mountains"),
      
      # Action button to trigger draw_img function
      actionButton("drawButton", "Draw Image")
    ),
    
    # Define the main panel
    mainPanel(
      # Display the PNG image using uiOutput
      uiOutput("displayImageUI")
    )
  )
)

server <- function(input, output) {
  
  observeEvent(input$drawButton, {
    draw_img(
      input$imagePrompt,
      ko2en = TRUE,
      n = 1L,
      size = "512x512",
      type = "file",
      format = "png",
      path = "./www/",
      fname = "shiny_prompt3",
      openai_api_key = Sys.getenv("OPENAI_API_KEY")
    )
    
    # Display the image
    output$displayImageUI <- renderUI({
      tags$img(src = "./shiny_prompt3.png", 
               width = "512px", 
               height = "512px", 
               alt = "Generated Image")
    })
    
    
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
