require(pacman)
p_load(tidyverse, here, janitor, shiny, DT, lubridate, shinyWidgets, bslib, shinyauthr)

user_base <- tibble::tibble(
  user = c("colebaril", "otheruser"),
  password = c("Newlife2019!", "getmeouttahere"),
  permissions = c("admin", "standard"),
  name = c("User One", "User Two")
)

# Read the data and process it
df <- read_csv("https://github.com/colebaril/JobScope/blob/main/jobs_combined.csv?raw=TRUE") |> 
  mutate(search_terms = paste(unique(search_term), collapse = ", "), .by = id) |> 
  distinct(id, .keep_all = TRUE) |> 
  mutate(job_title = paste0('<a href="', job_url, '" target="_blank">', title, '</a>')) |> 
  select(job_title, company, location, site,  date_posted, date_scraped, interval, min_amount, max_amount, search_terms) |>
  mutate(across(2:last_col(), ~str_to_upper(.))) |> 
  mutate(date_scraped = as.Date(date_scraped))

search_terms_list <- df |> select(search_terms) |> 
  separate_longer_delim(search_terms, delim = ",") |> 
  distinct() |> 
  mutate(search_terms = trimws(search_terms))

# Define the UI for the app
ui <- fluidPage(
  theme = bs_theme(bootswatch = "darkly"),

  
  # Title
  titlePanel("SCIENCE-RELATED WINNIPEG JOB POSTINGS"),
  
  # Sidebar layout with filters and a searchable table
  sidebarLayout(
    sidebarPanel(

      # add login panel UI function
      shinyauthr::loginUI(id = "login"),
      helpText("Filter and explore job postings tailored to professionals with expertise in microbiology, laboratory work, quality assurance, bioinformatics, and related fields."),
      helpText("This data is automatically updated at about 6PM CST."),
      p(""),
      
      # Filter for search terms (multi-select dropdown)
   
      pickerInput("search_terms_filter", 
                  label = tags$span(
                    "Select Search Terms", 
                    tags$i(
                      class = "glyphicon glyphicon-info-sign", 
                      style = "color:#0072B2;",
                      title = "Select which search terms were used to gather job postings. You can select more than 1."
                    )),
                  
                     choices = search_terms_list$search_terms, 
                     selected = NULL, 
                     multiple = TRUE,  # Allow multiple selections

                     ),
      
      # Date posted slider (select range of dates)
      sliderInput("date_slider",
                  "Select Date Range",
                  min = min(df$date_scraped),
                  max = max(df$date_scraped),
                  value = c(min(df$date_scraped), max(df$date_scraped)),
                  timeFormat = "%Y-%m-%d"),
      
      # Filter for job site (dropdown)
      pickerInput("site_filter", 
                  label = tags$span(
                    "Select Job Board", 
                    tags$i(
                      class = "glyphicon glyphicon-info-sign", 
                      style = "color:#0072B2;",
                      title = "Select which job boards were searched. You can select more than 1."
                    )),
                  
                  choices = unique(df$site), 
                  selected = NULL, 
                  multiple = TRUE,  # Allow multiple selections
                  
      ),
      
      # Search Box for general search
      textInput("search_box", 
                label = tags$span(
                  "Search Jobs", 
                  tags$i(
                    class = "glyphicon glyphicon-info-sign", 
                    style = "color:#0072B2;",
                    title = "Searches the job title, company and location columns."
                  )),
                 
                value = ""),
      tags$a(href="https://github.com/colebaril/JobScope", "Click here to read more about this app."),
      # add logout button UI
      div(class = "pull-right", shinyauthr::logoutUI(id = "logout"))
    ),
    
    # Main panel to display the table
    mainPanel(
      DTOutput("jobTable")
    )
  )
)

server <- function(input, output) {
  
  
  credentials <- shinyauthr::loginServer(
    id = "login",
    data = user_base,
    user_col = user,
    pwd_col = password,
    log_out = reactive(logout_init())
  )
  
  output$main_ui <- renderUI({
    req(credentials()$user_auth)
  })
  
  # call the logout module with reactive trigger to hide/show
  logout_init <- shinyauthr::logoutServer(
    id = "logout",
    active = reactive(credentials()$user_auth)
  )
  
  # LAST UPDATED
  last_updated_not <- max(df$date_scraped)
  
  # LAST UPDATED NOTIFICATION
  observe({
    showNotification(paste0("Data last updated on ", last_updated_not, "."),
                     type = "message", duration = NULL)
  }) 
  
  # Filter the data based on user input
  filtered_data <- reactive({
    df_filtered <- df
    
    
    # Filter by selected search terms (with unique terms, separated by commas)
    if (length(input$search_terms_filter) > 0 && !is.null(input$search_terms_filter)) {
      # Filter based on the search terms selected in the dropdown
      df_filtered <- df_filtered %>%
        filter(
          str_detect(search_terms, 
                     paste(input$search_terms_filter, collapse = "|"))
        )
    }
    
    # Filter by date range (if implemented)
    df_filtered <- df_filtered %>%
      filter(date_scraped >= input$date_slider[1] & date_scraped <= input$date_slider[2])
    
    # Filter by job site (if selected)
    if (!is.null(input$site_filter)) {
      df_filtered <- df_filtered %>%
        filter(site %in% input$site_filter)
    }
    
    # General search box filter (if something is entered in the search box)
    if (is.null(input$search_box) || input$search_box == "") {
      df_filtered <- df_filtered
    } else {

      df_filtered <- df_filtered %>%
        filter(
          str_detect(job_title, regex(input$search_box, ignore_case = TRUE)) | 
            str_detect(company, regex(input$search_box, ignore_case = TRUE)) | 
            str_detect(location, regex(input$search_box, ignore_case = TRUE))
        )
    }
    
    df_filtered
  })
  
  # Render the DataTable with filtered data
  output$jobTable <- renderDT({
    req(credentials()$user_auth)
    datatable(
      filtered_data() |> clean_names(case = "title"), 
      options = list(
        pageLength = 50,       # Number of rows per page
        scrollY = "800px",     # Enable vertical scrolling with a set height
        scrollX = TRUE,        # Enable horizontal scrolling for wide tables
        searching = TRUE,      # Enable the search feature
        dom = 'lrtip'          # Define table layout for search, pagination, etc.
      ),
      escape = FALSE          # IMPORTANT: This allows HTML content (links) to be rendered
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
