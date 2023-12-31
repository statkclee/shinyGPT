# https://www.listendata.com/2023/04/how-to-build-chatgpt-clone-in-shiny.html

library(shiny)
library(httr)
library(sass)
library(markdown)
library(waiter)
library(shinyjs)
library(shinyCopy2clipboard)
# remotes::install_github("deepanshu88/shinyCopy2clipboard")

css <- sass(sass_file("www/chat.scss"))

jscode <- 'var container = document.getElementById("chat-container");
if (container) {
  var elements = container.getElementsByClassName("user-message");
  if (elements.length > 1) {
    var lastElement = elements[elements.length - 1];
    lastElement.scrollIntoView({
      behavior: "smooth"
    });
  }
}'

chatGPT_R <- function(apiKey, prompt, model="gpt-3.5-turbo") {
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    add_headers(Authorization = paste("Bearer", apiKey)),
    content_type("application/json"),
    encode = "json",
    body = list(
      model = model,
      messages = list(
        list(role = "user", content = prompt)
      )
    )
  )
  
  if(status_code(response)>200) {
    result <- trimws(content(response)$error$message)
  } else {
    result <- trimws(content(response)$choices[[1]]$message$content)
  }
  
  return(result)
  
}

execute_at_next_input <- function(expr, session = getDefaultReactiveDomain()) {
  observeEvent(once = TRUE, reactiveValuesToList(session$input), {
    force(expr)
  }, ignoreInit = TRUE)
}

# Define UI for application
ui <- fluidPage(
  useWaiter(),
  useShinyjs(),
  use_copy(),
  tags$head(tags$style(css)),
  sidebarLayout(
    sidebarPanel(
      textInput("apiKey", "API Key", "sk-xxxxxxxxxxxxxxxxxxxx"),
      selectInput("model", "OpenAI LLM 모형", choices = c("gpt-3.5-turbo", "gpt-4"), selected = "gpt-3.5-turbo"),
      style = "background-color: #fff; color: #333; border: 1px solid #ccc;"
    ),
    
    mainPanel(
      tags$div(
        id = "chat-container",
        tags$div(
          id = "chat-header",
          tags$img(src = "kwangmyung.svg", alt = "AI 사진"),
          tags$h3("광명시 챗봇")
        ),
        tags$div(
          id = "chat-history",
          uiOutput("chatThread"),
        ),
        tags$div(
          id = "chat-input",
          tags$form(
            column(12,textAreaInput(inputId = "prompt", label="", placeholder = "프롬프트를 여기에 작성해주세요...", width = "100%")),
            fluidRow(
              tags$div(style = "margin-left: 1.5em;",
                       actionButton(inputId = "submit",
                                    label = "프롬프트 보내기",
                                    icon = icon("paper-plane")),
                       actionButton(inputId = "remove_chatThread",
                                    label = "기록 삭제",
                                    icon = icon("trash-can")),
                       CopyButton("clipbtn",
                                  label = "복사",
                                  icon = icon("clipboard"),
                                  text = "")
                       
              ))
          ))
      )
    ))
)

# Define server logic
server <- function(input, output, session) {
  
  historyALL <- reactiveValues(df = data.frame() , val = character(0))
  
  # On click of send button
  observeEvent(input$submit, {
    
    if (nchar(trimws(input$prompt)) > 0) {
      
      # Spinner
      w <- Waiter$new(id = "chat-history",
                      html = spin_3(),
                      color = transparent(.5))
      w$show()
      
      # Response
      chatGPT <- chatGPT_R(input$apiKey, input$prompt, input$model)
      historyALL$val <- chatGPT
      history <- data.frame(users = c("Human", "AI"),
                            content = c(input$prompt, markdown::mark_html(text=chatGPT)),
                            stringsAsFactors = FALSE)
      historyALL$df <- rbind(historyALL$df, history)
      updateTextInput(session, "prompt", value = "")
      
      # Conversation Interface
      output$chatThread <- renderUI({
        conversations <- lapply(seq_len(nrow(historyALL$df)), function(x) {
          tags$div(class = ifelse(historyALL$df[x, "users"] == "Human",
                                  "user-message",
                                  "bot-message"),
                   HTML(paste0(ifelse(historyALL$df[x, "users"] == "Human",
                                      "
<img src='question.svg' class='img-wrapper2'>
",
"
<img src='answer.svg' class='img-wrapper2'>
"),
historyALL$df[x, "content"])))
        })
        do.call(tagList, conversations)
      })
      
      w$hide()
      execute_at_next_input(runjs(jscode))
      
    }
    
  })
  
  observeEvent(input$remove_chatThread, {
    output$chatThread <- renderUI({return(NULL)})
    historyALL$df <- NULL
    updateTextInput(session, "prompt", value = "")
  })
  
  observe({
    req(input$clipbtn)
    CopyButtonUpdate(session,
                     id = "clipbtn",
                     label = "복사",
                     icon = icon("clipboard"),
                     text = as.character(historyALL$val))
    
  })
  
  
}

# Run the application
shinyApp(ui=ui, server=server)
