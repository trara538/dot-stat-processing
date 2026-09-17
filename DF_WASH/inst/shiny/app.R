# ===============================================================
# WASH SDMX Data Processing Shiny Application
# ===============================================================

# ===============================================================
# Load libraries
# ===============================================================

library(shiny)
library(rsdmx)
library(dplyr)
library(DT)
library(readr)

# ===============================================================
# Working directory
# ===============================================================

repository <- normalizePath(".", winslash = "/", mustWork = TRUE)

# ===============================================================
# Constants
# ===============================================================

username <- Sys.getenv("USERNAME")

# Countries
country <- c(
  "COK", "FJI", "FSM", "KIR", "MHL", "NRU", "NIU", "PNG", "PCN",
  "PLW", "SLB", "TKL", "TON", "TUV", "VUT", "WLF", "WSM"
)

# Dataflows
dataflows <- c(
  "WASH_HOUSEHOLDS",
  "WASH_SCHOOLS",
  "WASH_HEALTHCARE_FACILITY"
)

# ===============================================================
# User Interface
# ===============================================================

ui <- fluidPage(
  titlePanel("UNICEF WASH SDMX Data Processing Application"),
  sidebarLayout(
    # -----------------------------------------------------------
    # Sidebar
    # -----------------------------------------------------------
  sidebarPanel(
      h4("Processing"),
      p("This application downloads WASH data from the UNICEF SDMX API ",
        "for the selected Pacific Island countries."),
      
      hr(),
      strong("Countries"),
      p(paste(length(country), "countries configured for download.")),
      hr(),
      strong("Dataflows"),
      p(paste(length(dataflows), "WASH dataflows configured:")),
      
      tags$ul(
        tags$li("WASH Households"),
        tags$li("WASH Schools"),
        tags$li("WASH Healthcare Facility")
      ),
      
      hr(),
      
      actionButton(
        inputId = "process",
        label = "Process Data",
        icon = icon("play"),
        class = "btn-primary",
        width = "100%"
      ),
      
      br(),
      br(),
      
      downloadButton(
        outputId = "download_final",
        label = "Download Final CSV",
        class = "btn-success",
        width = "100%"
      ),
      
      hr(),
      h4("Status"),
      verbatimTextOutput("status")
    ),
    
    # -----------------------------------------------------------
    # Main panel
    # -----------------------------------------------------------
    
    mainPanel(
      
      tabsetPanel(
        
        # =======================================================
        # Summary
        # =======================================================
        
        tabPanel("Summary",
          br(),
          h4("Processing Summary"),
          DTOutput("summary_table"),
          br(),
          h4("Final Combined Data"),
          DTOutput("final_preview")
        ),
        
        # =======================================================
        # WASH Households
        # =======================================================
        
        tabPanel("WASH Households",
          br(),
          h4("WASH Households"),
          DTOutput("wash_hh_table")
        ),
        
        # =======================================================
        # WASH Schools
        # =======================================================
        
        tabPanel("WASH Schools",
          br(),
          h4("WASH Schools"),
          DTOutput("wash_schools_table")
        ),
        
        # =======================================================
        # WASH Healthcare
        # =======================================================
        
        tabPanel("WASH Healthcare",
          br(),
          h4("WASH Healthcare Facility"),
          DTOutput("wash_health_table")
        ),
        
        # =======================================================
        # Failed Downloads
        # =======================================================
        
        tabPanel("Failed Downloads",
          br(),
          h4("Failed Downloads"),
          DTOutput("failed_downloads_table")
        )
      )
    )
  )
)

# ===============================================================
# Server
# ===============================================================

server <- function(input, output, session) {
  
  # -------------------------------------------------------------
  # Reactive objects
  # -------------------------------------------------------------
  
  wash_HH <- reactiveVal(data.frame())
  wash_Schools <- reactiveVal(data.frame())
  wash_Health <- reactiveVal(data.frame())
  wash_combine_final <- reactiveVal(data.frame())
  failed_downloads <- reactiveVal(data.frame(
    DATAFLOW = character(),
    COUNTRY = character(),
    ERROR = character(),
    stringsAsFactors = FALSE
  ))
  
  processing_status <- reactiveVal("Waiting for processing to start...")
  
  # -------------------------------------------------------------
  # Status output
  # -------------------------------------------------------------
  
  output$status <- renderText({
    processing_status()
  })
  
  # =============================================================
  # Process data
  # =============================================================
  
  observeEvent(input$process, {
    # -----------------------------------------------------------
    # Reset objects
    # -----------------------------------------------------------
    wash_HH(data.frame())
    wash_Schools(data.frame())
    wash_Health(data.frame())
    wash_combine_final(data.frame())
    failed_downloads(
      data.frame(
        DATAFLOW = character(),
        COUNTRY = character(),
        ERROR = character(),
        stringsAsFactors = FALSE
      )
    )
    
    processing_status("Starting WASH data processing...")
    
    # -----------------------------------------------------------
    # Temporary storage
    # -----------------------------------------------------------
    
    all_failed <- data.frame(
      DATAFLOW = character(),
      COUNTRY = character(),
      ERROR = character(),
      stringsAsFactors = FALSE
    )
    
    # ===========================================================
    # Process all dataflows
    # ===========================================================
    
    withProgress(message = "Downloading UNICEF WASH data",
      value = 0,
      {
        total_tasks <- length(dataflows) * length(country)
        current_task <- 0
        
        for (flow in dataflows) {
          
          # -----------------------------------------------------
          # Temporary dataframe for current dataflow
          # -----------------------------------------------------
          
          flow_data <- data.frame()
          
          # -----------------------------------------------------
          # Process countries
          # -----------------------------------------------------
          
          for (ctry in country) {
            
            current_task <- current_task + 1
            
            incProgress(
              1 / total_tasks,
              detail = paste(
                flow,
                "-",
                ctry
              )
            )
            
            processing_status(
              paste(
                "Processing:",
                flow,
                "-",
                ctry
              )
            )
            
            # ---------------------------------------------------
            # Download SDMX data
            # ---------------------------------------------------
            
            Wash_Data <- tryCatch({
              
              as.data.frame(
                readSDMX(
                  providerId = "UNICEF",
                  resource = "data",
                  flowRef = flow,
                  key = ctry
                )
              )
              
            }, error = function(e) {
              
              error_message <- conditionMessage(e)
              
              all_failed <<- bind_rows(
                all_failed,
                data.frame(
                  DATAFLOW = flow,
                  COUNTRY = ctry,
                  ERROR = error_message,
                  stringsAsFactors = FALSE
                )
              )
              
              return(NULL)
            })
            
            # ---------------------------------------------------
            # Continue only if download succeeded
            # ---------------------------------------------------
            
            if (!is.null(Wash_Data)) {
              
              # ================================================
              # Common filters
              # ================================================
              
              required_common <- c(
                "SERVICE_TYPE",
                "RESIDENCE"
              )
              
              if (
                all(required_common %in% names(Wash_Data))
              ) {
                
                Wash_Data <- Wash_Data |>
                  filter(
                    SERVICE_TYPE %in% c(
                      "HYG",
                      "SAN",
                      "WAT"
                    ),
                    RESIDENCE == "_T"
                  )
                
              } else {
                
                all_failed <<- bind_rows(
                  all_failed,
                  data.frame(
                    DATAFLOW = flow,
                    COUNTRY = ctry,
                    ERROR = paste(
                      "Required columns missing:",
                      paste(
                        setdiff(
                          required_common,
                          names(Wash_Data)
                        ),
                        collapse = ", "
                      )
                    ),
                    stringsAsFactors = FALSE
                  )
                )
                
                next
              }
              
              # ================================================
              # Dataflow-specific filters
              # ================================================
              
              if (flow == "WASH_HOUSEHOLDS") {
                
                if ("WEALTH_QUINTILE" %in% names(Wash_Data)) {
                  
                  Wash_Data <- Wash_Data |>
                    filter(
                      WEALTH_QUINTILE == "_T"
                    )
                  
                } else {
                  
                  all_failed <<- bind_rows(
                    all_failed,
                    data.frame(
                      DATAFLOW = flow,
                      COUNTRY = ctry,
                      ERROR = "WEALTH_QUINTILE column not found",
                      stringsAsFactors = FALSE
                    )
                  )
                  
                  next
                }
              }
              
              if (flow == "WASH_SCHOOLS") {
                
                if ("SCH_TYPE" %in% names(Wash_Data)) {
                  
                  Wash_Data <- Wash_Data |>
                    filter(
                      SCH_TYPE == "_T"
                    )
                  
                } else {
                  
                  all_failed <<- bind_rows(
                    all_failed,
                    data.frame(
                      DATAFLOW = flow,
                      COUNTRY = ctry,
                      ERROR = "SCH_TYPE column not found",
                      stringsAsFactors = FALSE
                    )
                  )
                  
                  next
                }
              }
              
              if (flow == "WASH_HEALTHCARE_FACILITY") {
                
                if ("HCF_TYPE" %in% names(Wash_Data)) {
                  
                  Wash_Data <- Wash_Data |>
                    filter(
                      HCF_TYPE == "_T"
                    )
                  
                } else {
                  
                  all_failed <<- bind_rows(
                    all_failed,
                    data.frame(
                      DATAFLOW = flow,
                      COUNTRY = ctry,
                      ERROR = "HCF_TYPE column not found",
                      stringsAsFactors = FALSE
                    )
                  )
                  
                  next
                }
              }
              
              # ================================================
              # Append data
              # ================================================
              
              flow_data <- bind_rows(
                flow_data,
                Wash_Data
              )
            }
          }
          
          # -----------------------------------------------------
          # Store current dataflow
          # -----------------------------------------------------
          
          if (flow == "WASH_HOUSEHOLDS") {
            
            wash_HH(flow_data)
            
          } else if (flow == "WASH_SCHOOLS") {
            
            wash_Schools(flow_data)
            
          } else if (
            flow == "WASH_HEALTHCARE_FACILITY"
          ) {
            
            wash_Health(flow_data)
          }
        }
      }
    )
    
    # ===========================================================
    # Save failed downloads
    # ===========================================================
    
    failed_downloads(all_failed)
    
    # ===========================================================
    # Finalise individual dataframes
    # ===========================================================
    
    hh_data <- wash_HH()
    
    schools_data <- wash_Schools()
    
    health_data <- wash_Health()
    
    # -----------------------------------------------------------
    # WASH Households
    # -----------------------------------------------------------
    
    if (nrow(hh_data) > 0) {
      
      wash_HH_final <- hh_data |>
        select(
          REF_AREA,
          INDICATOR,
          SERVICE_TYPE,
          UNIT_MEASURE,
          TIME_PERIOD,
          OBS_VALUE,
          DATA_SOURCE
        )
      
    } else {
      
      wash_HH_final <- data.frame(
        REF_AREA = character(),
        INDICATOR = character(),
        SERVICE_TYPE = character(),
        UNIT_MEASURE = character(),
        TIME_PERIOD = character(),
        OBS_VALUE = numeric(),
        DATA_SOURCE = character()
      )
    }
    
    # -----------------------------------------------------------
    # WASH Schools
    # -----------------------------------------------------------
    
    if (nrow(schools_data) > 0) {
      
      wash_Schools_final <- schools_data |>
        select(
          REF_AREA,
          INDICATOR,
          SERVICE_TYPE,
          UNIT_MEASURE,
          TIME_PERIOD,
          OBS_VALUE,
          DATA_SOURCE
        )
      
    } else {
      
      wash_Schools_final <- data.frame(
        REF_AREA = character(),
        INDICATOR = character(),
        SERVICE_TYPE = character(),
        UNIT_MEASURE = character(),
        TIME_PERIOD = character(),
        OBS_VALUE = numeric(),
        DATA_SOURCE = character()
      )
    }
    
    # -----------------------------------------------------------
    # WASH Healthcare
    # -----------------------------------------------------------
    
    if (nrow(health_data) > 0) {
      
      wash_Health_final <- health_data |>
        select(
          REF_AREA,
          INDICATOR,
          SERVICE_TYPE,
          UNIT_MEASURE,
          TIME_PERIOD,
          OBS_VALUE,
          DATA_SOURCE
        )
      
    } else {
      
      wash_Health_final <- data.frame(
        REF_AREA = character(),
        INDICATOR = character(),
        SERVICE_TYPE = character(),
        UNIT_MEASURE = character(),
        TIME_PERIOD = character(),
        OBS_VALUE = numeric(),
        DATA_SOURCE = character()
      )
    }
    
    # ===========================================================
    # Combine datasets
    # ===========================================================
    
    wash_combine <- bind_rows(
      wash_HH_final,
      wash_Schools_final,
      wash_Health_final
    ) |>
      rename(
        COU = REF_AREA
      )
    
    # ===========================================================
    # Read country reference file
    # ===========================================================
    
    country_file <- file.path(
      repository,
      "country.csv"
    )
    
    if (!file.exists(country_file)) {
      
      stop(
        paste(
          "Country reference file not found:",
          country_file
        )
      )
    }
    
    countries <- read.csv(
      country_file,
      stringsAsFactors = FALSE
    )
    
    # ===========================================================
    # Merge with country reference
    # ===========================================================
    
    wash_combine_merge <- merge(
      wash_combine,
      countries,
      by = "COU"
    )
    
    # -----------------------------------------------------------
    # Remove country reference columns if present
    # -----------------------------------------------------------
    
    remove_columns <- intersect(
      c(
        "Country",
        "ctyCur",
        "Region",
        "COU",
        "REF_AREA"
      ),
      names(wash_combine_merge)
    )
    
    wash_combine_merge <- wash_combine_merge |>
      select(
        -all_of(remove_columns)
      )
    
    # ===========================================================
    # Create final SDMX dataframe
    # ===========================================================
    
    wash_final <- wash_combine_merge |>
      mutate(
        DATAFLOW = "SPC:DF_WASH(1.0)",
        FREQ = "A",
        UNIT_MEASURE = "PERCENT",
        UNIT_MULT = "",
        OBS_STATUS = "",
        OBS_COMMENT = ""
      ) |>
      select(
        DATAFLOW,
        FREQ,
        GEO_PICT,
        INDICATOR,
        TIME_PERIOD,
        OBS_VALUE,
        UNIT_MEASURE,
        UNIT_MULT,
        OBS_STATUS,
        DATA_SOURCE,
        OBS_COMMENT
      )
    
    # ===========================================================
    # Store final dataframe
    # ===========================================================
    
    wash_combine_final(wash_final)
    
    # ===========================================================
    # OneDrive output folder
    # ===========================================================
    
    current_time <- Sys.time()
    
    myYear <- format(
      current_time,
      "%Y"
    )
    
    myMonth <- format(
      current_time,
      "%m"
    )
    
    myDay <- format(
      current_time,
      "%d"
    )
    
    myHour <- format(
      current_time,
      "%H"
    )
    
    myMin <- format(
      current_time,
      "%M"
    )
    
    mySecond <- format(
      current_time,
      "%S"
    )
    
    oneDrivePath <- paste0(
      "C:/Users/",
      username,
      "/OneDrive - SPC/DotStat/REFDB/DF_WASH"
    )
    
    folderName <- paste0(
      myYear,
      myMonth,
      myDay,
      "_",
      myHour,
      myMin,
      mySecond,
      "_data_Update"
    )
    
    newFolder <- file.path(
      oneDrivePath,
      folderName
    )
    
    newFile <- file.path(
      newFolder,
      "DF_WASH_data.CSV"
    )
    
    # ===========================================================
    # Write final CSV
    # ===========================================================
    
    dir.create(
      newFolder,
      recursive = TRUE,
      showWarnings = FALSE
    )
    
    write.csv(
      wash_final,
      newFile,
      row.names = FALSE
    )
    
    # ===========================================================
    # Update status
    # ===========================================================
    
    processing_status(
      paste0(
        "PROCESSING COMPLETE\n\n",
        "WASH_HOUSEHOLDS: ",
        nrow(hh_data),
        " rows\n",
        "WASH_SCHOOLS: ",
        nrow(schools_data),
        " rows\n",
        "WASH_HEALTHCARE_FACILITY: ",
        nrow(health_data),
        " rows\n\n",
        "FINAL DATA: ",
        nrow(wash_final),
        " rows\n\n",
        "FAILED DOWNLOADS: ",
        nrow(all_failed),
        "\n\n",
        "CSV written to:\n",
        newFile
      )
    )
    
    # ===========================================================
    # Display notification
    # ===========================================================
    
    showNotification(
      paste(
        "WASH processing completed.",
        nrow(wash_final),
        "final observations created."
      ),
      type = "message",
      duration = 8
    )
    
  }, ignoreInit = TRUE)
  
  # =============================================================
  # Summary table
  # =============================================================
  
  output$summary_table <- renderDT({
    
    data.frame(
      DATAFLOW = c(
        "WASH_HOUSEHOLDS",
        "WASH_SCHOOLS",
        "WASH_HEALTHCARE_FACILITY",
        "FINAL COMBINED"
      ),
      ROWS = c(
        nrow(wash_HH()),
        nrow(wash_Schools()),
        nrow(wash_Health()),
        nrow(wash_combine_final())
      )
    )
    
  }, options = list(
    pageLength = 10,
    scrollX = TRUE
  ))
  
  # =============================================================
  # Final data preview
  # =============================================================
  
  output$final_preview <- renderDT({
    
    req(
      nrow(wash_combine_final()) > 0
    )
    
    datatable(
      wash_combine_final(),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      filter = "top"
    )
    
  })
  
  # =============================================================
  # WASH Households table
  # =============================================================
  
  output$wash_hh_table <- renderDT({
    
    req(
      nrow(wash_HH()) > 0
    )
    
    datatable(
      wash_HH(),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      filter = "top"
    )
    
  })
  
  # =============================================================
  # WASH Schools table
  # =============================================================
  
  output$wash_schools_table <- renderDT({
    
    req(
      nrow(wash_Schools()) > 0
    )
    
    datatable(
      wash_Schools(),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      filter = "top"
    )
    
  })
  
  # =============================================================
  # WASH Healthcare table
  # =============================================================
  
  output$wash_health_table <- renderDT({
    
    req(
      nrow(wash_Health()) > 0
    )
    
    datatable(
      wash_Health(),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      filter = "top"
    )
    
  })
  
  # =============================================================
  # Failed downloads table
  # =============================================================
  
  output$failed_downloads_table <- renderDT({
    
    req(
      nrow(failed_downloads()) > 0
    )
    
    datatable(
      failed_downloads(),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      filter = "top"
    )
    
  })
  
  # =============================================================
  # Download final CSV
  # =============================================================
  
  output$download_final <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "DF_WASH_",
        format(
          Sys.Date(),
          "%Y%m%d"
        ),
        ".CSV"
      )
      
    },
    
    content = function(file) {
      
      req(
        nrow(wash_combine_final()) > 0
      )
      
      write.csv(
        wash_combine_final(),
        file,
        row.names = FALSE
      )
    }
  )
}

# ===============================================================
# Run application
# ===============================================================

shinyApp(
  ui = ui,
  server = server
)