# ===============================================================
# UIS DATA + METADATA PROCESSING SHINY APPLICATION
# ===============================================================

# ===============================================================
# Load libraries
# ===============================================================

library(shiny)
library(uisapi)
library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(purrr)
library(tibble)
library(readr)
library(DT)

# ===============================================================
# Working directory
# ===============================================================

repository <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

# ===============================================================
# Constant declarations
# ===============================================================

username <- Sys.getenv("USERNAME")

# ===============================================================
# Countries
# ===============================================================

country <- c(
  "COK",
  "FJI",
  "FSM",
  "KIR",
  "MHL",
  "NRU",
  "NIU",
  "PNG",
  "PCN",
  "PLW",
  "SLB",
  "TKL",
  "TON",
  "TUV",
  "VUT",
  "WLF",
  "WSM"
)

# ===============================================================
# UIS indicators
# ===============================================================

indicatorCode <- c(
  "AIR.1.GLAST",
  "AIR.1.GLAST.F",
  "AIR.1.GLAST.M",
  "AIR.2.GPV.GLAST",
  "AIR.2.GPV.GLAST.F",
  "AIR.2.GPV.GLAST.M",
  "CR.1",
  "CR.1.F",
  "CR.1.M",
  "CR.2",
  "CR.2.F",
  "CR.2.M",
  "CR.3",
  "CR.3.F",
  "CR.3.M",
  "GAR.5T8",
  "GAR.5T8.F",
  "GAR.5T8.M",
  "GER.0",
  "GER.01",
  "GER.01.F",
  "GER.01.M",
  "GER.02",
  "GER.02.F",
  "GER.02.M",
  "GER.0.F",
  "GER.0.M",
  "GER.5T8",
  "GER.5T8.F",
  "GER.5T8.M",
  "LR.AG15T24",
  "LR.AG15T24.F",
  "LR.AG15T24.M",
  "LR.AG15T99",
  "LR.AG15T99.F",
  "LR.AG15T99.M",
  "LR.AG25T64",
  "LR.AG25T64.F",
  "LR.AG25T64.M",
  "NERA.AGM1.CP",
  "NERA.AGM1.F.CP",
  "NERA.AGM1.M.CP",
  "OAEPG.1",
  "OAEPG.1.F",
  "OAEPG.2.GPV.M",
  "ODAFLOW.VOLUMESCHOLARSHIP",
  "PTRHC.1.QUALIFIED",
  "PTRHC.2.QUALIFIED",
  "PTRHC.3.QUALIFIED",
  "QUTP.02",
  "QUTP.02.F",
  "QUTP.02.M",
  "QUTP.1",
  "QUTP.1.F",
  "QUTP.1.M",
  "QUTP.2",
  "QUTP.2.F",
  "QUTP.2.M",
  "QUTP.2T3",
  "QUTP.2T3.F",
  "QUTP.2T3.M",
  "QUTP.3",
  "QUTP.3.F",
  "QUTP.3.M",
  "ROFST.1.CP",
  "ROFST.1.F.CP",
  "ROFST.1.M.CP",
  "ROFST.2T3.CP",
  "ROFST.H.1",
  "SCHBSP.1.WCOMPUT",
  "SCHBSP.1.WELEC",
  "SCHBSP.1.WINFSTUDIS",
  "SCHBSP.1.WWASH",
  "SCHBSP.1.WWATA",
  "SCHBSP.2.WELEC",
  "SCHBSP.2.WINFSTUDIS",
  "SCHBSP.2.WWASH",
  "SCHBSP.2.WWATA",
  "SCHBSP.3.WINFSTUDIS",
  "TRTP.02",
  "TRTP.02.F",
  "TRTP.02.M",
  "TRTP.1",
  "TRTP.1.F",
  "TRTP.1.M",
  "TRTP.2",
  "TRTP.2.F",
  "TRTP.2.M",
  "TRTP.2T3",
  "TRTP.2T3.F",
  "TRTP.2T3.M",
  "TRTP.3",
  "TRTP.3.F",
  "TRTP.3.M"
)

# ===============================================================
# Metadata processing function
# ===============================================================

metadata_function <- function(meta) {
  
  indicator_list <- indicatorCode
  
  # -------------------------------------------------------------
  # Null handling
  # -------------------------------------------------------------
  
  `%||%` <- function(x, y) {
    if (is.null(x)) y else x
  }
  
  # -------------------------------------------------------------
  # Indicator list
  # -------------------------------------------------------------
  
  indis <- tibble(
    indicatorCode = indicator_list
  )
  
  # -------------------------------------------------------------
  # UIS metadata API
  # -------------------------------------------------------------
  
  url <- paste0(
    "https://api.uis.unesco.org/api/public/definitions/indicators",
    "?disaggregations=true&glossaryTerms=true"
  )
  
  response <- request(url) |>
    req_perform()
  
  data <- response |>
    resp_body_json(
      simplifyVector = FALSE
    )
  
  # =============================================================
  # Indicator metadata
  # =============================================================
  
  indicators <- map_dfr(
    data,
    function(x) {
      
      tibble(
        indicatorCode =
          x$indicatorCode %||% NA_character_,
        
        name =
          x$name %||% NA_character_,
        
        theme =
          x$theme %||% NA_character_,
        
        lastDataUpdate =
          x$lastDataUpdate %||% NA_character_,
        
        lastDataUpdateDescription =
          x$lastDataUpdateDescription %||% NA_character_,
        
        dataAvailability =
          list(
            x$dataAvailability %||% list()
          ),
        
        disaggregations =
          list(
            x$disaggregations %||% list()
          ),
        
        glossaryTerms =
          list(
            x$glossaryTerms %||% list()
          )
      )
    }
  )
  
  # =============================================================
  # Glossary metadata
  # =============================================================
  
  glossary_terms <- map_dfr(
    data,
    function(x) {
      
      if (
        is.null(x$glossaryTerms) ||
        length(x$glossaryTerms) == 0
      ) {
        return(tibble())
      }
      
      map_dfr(
        x$glossaryTerms,
        function(g) {
          
          tibble(
            
            indicatorCode =
              x$indicatorCode %||% NA_character_,
            
            termId =
              g$termId %||% NA_integer_,
            
            termName =
              g$name %||% NA_character_,
            
            language =
              g$language %||% NA_character_,
            
            definition =
              g$definition %||% NA_character_,
            
            definitionSource =
              g$definitionSource %||% NA_character_,
            
            purpose =
              g$purpose %||% NA_character_,
            
            calculationMethod =
              g$calculationMethod %||% NA_character_,
            
            dataRequired =
              g$dataRequired %||% NA_character_,
            
            dataSource =
              g$dataSource %||% NA_character_,
            
            typesOfDisaggregation =
              g$typesOfDisaggregation %||% NA_character_,
            
            interpretation =
              g$interpretation %||% NA_character_,
            
            qualityStandards =
              g$qualityStandards %||% NA_character_,
            
            limitations =
              g$limitations %||% NA_character_,
            
            themes =
              paste(
                unlist(
                  g$themes %||% list()
                ),
                collapse = "; "
              )
          )
        }
      )
    }
  )
  
  # =============================================================
  # Remove nested metadata columns
  # =============================================================
  
  indicators <- indicators |>
    select(
      -c(
        "dataAvailability",
        "disaggregations",
        "glossaryTerms"
      )
    )
  
  # =============================================================
  # Merge indicator metadata and glossary metadata
  # =============================================================
  
  metadata <- merge(
    indicators,
    glossary_terms,
    by = "indicatorCode"
  )
  
  # =============================================================
  # Keep only requested indicators
  # =============================================================
  
  indicator_metadata <- merge(
    metadata,
    indis,
    by = "indicatorCode"
  )
  
  # =============================================================
  # Final metadata
  # =============================================================
  
  meta <- indicator_metadata
  
  return(meta)
}


# ===============================================================
# User Interface
# ===============================================================

ui <- fluidPage(
  
  titlePanel(
    "UIS Data and Metadata Processing Application"
  ),
  
  sidebarLayout(
    
    # ===========================================================
    # Sidebar
    # ===========================================================
    
    sidebarPanel(
      
      h4("UIS Data Processing"),
      
      p(
        "This application downloads UIS education indicators ",
        "for the selected Pacific Island countries."
      ),
      
      hr(),
      
      strong("Countries"),
      
      p(
        paste(
          length(country),
          "PICTs configured for download."
        )
      ),
      
      hr(),
      
      strong("Indicators"),
      
      p(
        paste(
          length(indicatorCode),
          "UIS indicators configured."
        )
      ),
      
      hr(),
      
      strong("Data period"),
      
      p("2000 to 2026"),
      
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
        outputId = "download_data",
        label = "Download UIS Data",
        class = "btn-success",
        width = "100%"
      ),
      
      br(),
      br(),
      
      downloadButton(
        outputId = "download_metadata",
        label = "Download Metadata",
        class = "btn-success",
        width = "100%"
      ),
      
      br(),
      br(),
      
      downloadButton(
        outputId = "download_both",
        label = "Download Both Files",
        class = "btn-info",
        width = "100%"
      ),
      
      hr(),
      
      h4("Status"),
      
      verbatimTextOutput(
        "status"
      )
    ),
    
    # ===========================================================
    # Main panel
    # ===========================================================
    
    mainPanel(
      
      tabsetPanel(
        
        # =======================================================
        # Summary
        # =======================================================
        
        tabPanel(
          "Summary",
          
          br(),
          
          h4("Processing Summary"),
          
          DTOutput(
            "summary_table"
          ),
          
          br(),
          
          h4("Final UIS Data"),
          
          DTOutput(
            "data_preview"
          )
        ),
        
        # =======================================================
        # UIS Data
        # =======================================================
        
        tabPanel(
          "UIS Data",
          
          br(),
          
          h4(
            "DF_UIS Data"
          ),
          
          DTOutput(
            "uis_data_table"
          )
        ),
        
        # =======================================================
        # Metadata
        # =======================================================
        
        tabPanel(
          "Metadata",
          
          br(),
          
          h4(
            "UIS Indicator Metadata"
          ),
          
          DTOutput(
            "metadata_table"
          )
        )
        
      )
    )
  )
)


# ===============================================================
# Server
# ===============================================================

server <- function(
    input,
    output,
    session
) {
  
  # =============================================================
  # Reactive objects
  # =============================================================
  
  data_final <- reactiveVal(
    data.frame()
  )
  
  metadata_dataframe <- reactiveVal(
    data.frame()
  )
  
  output_folder <- reactiveVal(
    NULL
  )
  
  processing_status <- reactiveVal(
    "Waiting for processing to start..."
  )
  
  # =============================================================
  # Status
  # =============================================================
  
  output$status <- renderText({
    
    processing_status()
    
  })
  
  
  # =============================================================
  # Process button
  # =============================================================
  
  observeEvent(
    input$process,
    {
      
      # ---------------------------------------------------------
      # Reset
      # ---------------------------------------------------------
      
      data_final(
        data.frame()
      )
      
      metadata_dataframe(
        data.frame()
      )
      
      processing_status(
        "Starting UIS processing..."
      )
      
      # ========================================================
      # Read country reference file
      # ========================================================
      
      country_file <- file.path(
        repository,
        "country.csv"
      )
      
      if (
        !file.exists(country_file)
      ) {
        
        showNotification(
          paste(
            "Country reference file not found:",
            country_file
          ),
          type = "error",
          duration = NULL
        )
        
        processing_status(
          paste(
            "ERROR: Country reference file not found:",
            country_file
          )
        )
        
        return()
      }
      
      countries <- read.csv(
        country_file,
        stringsAsFactors = FALSE
      )
      
      # ========================================================
      # Download UIS data
      # ========================================================
      
      result <- tryCatch(
        
        {
          
          withProgress(
            
            message = "Downloading UIS data",
            value = 0,
            
            {
              
              processing_status(
                "Downloading UIS data from UIS API..."
              )
              
              incProgress(
                0.2,
                detail = "Requesting UIS data..."
              )
              
              data <- uis_get(
                
                entities = country,
                
                indicators = indicatorCode,
                
                start_year = 2000,
                
                end_year = 2026
                
              )
              
              incProgress(
                0.6,
                detail = "Processing UIS observations..."
              )
              
              # ================================================
              # Finalise data
              # ================================================
              
              data_final_temp <- data |>
                
                mutate(
                  DATAFLOW = "SPC:DF_UIS(1.0)",
                  FREQ = "A",
                  UNIT_MEASURE = "",
                  UNIT_MULT = "",
                  OBS_STATUS = "",
                  DATA_SOURCE = "",
                  OBS_COMMENT = ""
                ) |>
                
                rename(
                  COU = entity_id,
                  TIME_PERIOD = year,
                  INDICATOR = indicator_id,
                  OBS_VALUE = value
                ) |>
                
                mutate(
                  INDICATOR =
                    gsub(
                      "\\.",
                      "_",
                      INDICATOR
                    ),
                  
                  OBS_VALUE =
                    round(
                      as.numeric(
                        OBS_VALUE
                      ),
                      2
                    )
                )
              
              # ================================================
              # Merge country codes
              # ================================================
              
              data_final_temp <-
                merge(
                  data_final_temp,
                  countries,
                  by = "COU"
                ) |>
                
                select(
                  -c(
                    "COU",
                    "ctyCur",
                    "Region",
                    "Country",
                    "REF_AREA"
                  )
                ) |>
                
                select(
                  DATAFLOW,
                  FREQ,
                  TIME_PERIOD,
                  GEO_PICT,
                  INDICATOR,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  DATA_SOURCE,
                  OBS_COMMENT
                )
              
              incProgress(
                0.2,
                detail = "UIS data processing complete."
              )
              
              data_final(
                data_final_temp
              )
            }
          )
          
          TRUE
          
        },
        
        error = function(e) {
          
          processing_status(
            paste(
              "UIS data download failed:",
              conditionMessage(e)
            )
          )
          
          showNotification(
            paste(
              "UIS data download failed:",
              conditionMessage(e)
            ),
            type = "error",
            duration = NULL
          )
          
          FALSE
        }
      )
      
      # ---------------------------------------------------------
      # Stop if UIS data failed
      # ---------------------------------------------------------
      
      if (!result) {
        return()
      }
      
      # ========================================================
      # Download metadata
      # ========================================================
      
      metadata_result <- tryCatch(
        
        {
          
          withProgress(
            
            message = "Downloading UIS metadata",
            value = 0,
            
            {
              
              processing_status(
                "Downloading UIS indicator metadata..."
              )
              
              incProgress(
                0.2,
                detail = "Connecting to UIS metadata API..."
              )
              
              metadata_dataframe_temp <-
                metadata_function(
                  indicatorCode
                )
              
              incProgress(
                0.7,
                detail = "Processing glossary metadata..."
              )
              
              metadata_dataframe(
                metadata_dataframe_temp
              )
              
              incProgress(
                0.1,
                detail = "Metadata processing complete."
              )
            }
          )
          
          TRUE
          
        },
        
        error = function(e) {
          
          processing_status(
            paste(
              "Metadata download failed:",
              conditionMessage(e)
            )
          )
          
          showNotification(
            paste(
              "Metadata download failed:",
              conditionMessage(e)
            ),
            type = "error",
            duration = NULL
          )
          
          FALSE
        }
      )
      
      # ---------------------------------------------------------
      # Stop if metadata failed
      # ---------------------------------------------------------
      
      if (!metadata_result) {
        return()
      }
      
      # ========================================================
      # Create OneDrive output folder
      # ========================================================
      
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
        "/OneDrive - SPC/DotStat/REFDB/DF_UIS"
      )
      
      folderName <- paste0(
        myYear,
        myMonth,
        myDay,
        "_",
        myHour,
        myMin,
        mySecond,
        "_UIS_data_Update"
      )
      
      newFolder <- file.path(
        oneDrivePath,
        folderName
      )
      
      newFile <- file.path(
        newFolder,
        "DF_UIS_data.CSV"
      )
      
      metaFile <- file.path(
        newFolder,
        "UIS_metadata.CSV"
      )
      
      # ========================================================
      # Create folder
      # ========================================================
      
      tryCatch(
        
        {
          
          dir.create(
            newFolder,
            recursive = TRUE,
            showWarnings = FALSE
          )
          
          # ==============================================
          # Write UIS data
          # ==============================================
          
          write.csv(
            data_final(),
            newFile,
            row.names = FALSE
          )
          
          # ==============================================
          # Write metadata
          # ==============================================
          
          write.csv(
            metadata_dataframe(),
            metaFile,
            row.names = FALSE
          )
          
          output_folder(
            newFolder
          )
          
          # ==============================================
          # Final status
          # ==============================================
          
          processing_status(
            
            paste0(
              
              "PROCESSING COMPLETE\n\n",
              
              "UIS DATA\n",
              "Rows: ",
              nrow(data_final()),
              "\n",
              "Columns: ",
              ncol(data_final()),
              "\n\n",
              
              "METADATA\n",
              "Rows: ",
              nrow(metadata_dataframe()),
              "\n",
              "Columns: ",
              ncol(metadata_dataframe()),
              "\n\n",
              
              "OUTPUT FOLDER\n",
              newFolder,
              "\n\n",
              
              "UIS DATA FILE\n",
              newFile,
              "\n\n",
              
              "METADATA FILE\n",
              metaFile
            )
          )
          
          showNotification(
            paste0(
              "Processing completed successfully. ",
              nrow(data_final()),
              " UIS observations and ",
              nrow(metadata_dataframe()),
              " metadata records created."
            ),
            type = "message",
            duration = 10
          )
          
        },
        
        error = function(e) {
          
          processing_status(
            paste(
              "ERROR writing output files:",
              conditionMessage(e)
            )
          )
          
          showNotification(
            paste(
              "Could not write output files:",
              conditionMessage(e)
            ),
            type = "error",
            duration = NULL
          )
        }
      )
    },
    
    ignoreInit = TRUE
  )
  
  
  # =============================================================
  # Summary table
  # =============================================================
  
  output$summary_table <- renderDT({
    
    req(
      nrow(data_final()) > 0
    )
    
    summary_data <- data.frame(
      
      ITEM = c(
        "Countries",
        "Indicators",
        "UIS observations",
        "Data columns",
        "Metadata records",
        "Metadata columns"
      ),
      
      VALUE = c(
        length(country),
        length(indicatorCode),
        nrow(data_final()),
        ncol(data_final()),
        nrow(metadata_dataframe()),
        ncol(metadata_dataframe())
      ),
      
      stringsAsFactors = FALSE
    )
    
    datatable(
      summary_data,
      rownames = FALSE,
      options = list(
        pageLength = 10,
        dom = "t"
      )
    )
    
  })
  
  
  # =============================================================
  # UIS data preview
  # =============================================================
  
  output$data_preview <- renderDT({
    
    req(
      nrow(data_final()) > 0
    )
    
    datatable(
      
      head(
        data_final(),
        100
      ),
      
      rownames = FALSE,
      
      options = list(
        pageLength = 10,
        scrollX = TRUE
      )
    )
    
  })
  
  
  # =============================================================
  # UIS data table
  # =============================================================
  
  output$uis_data_table <- renderDT({
    
    req(
      nrow(data_final()) > 0
    )
    
    datatable(
      
      data_final(),
      
      rownames = FALSE,
      
      filter = "top",
      
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        autoWidth = TRUE
      )
    )
    
  })
  
  
  # =============================================================
  # Metadata table
  # =============================================================
  
  output$metadata_table <- renderDT({
    
    req(
      nrow(metadata_dataframe()) > 0
    )
    
    datatable(
      
      metadata_dataframe(),
      
      rownames = FALSE,
      
      filter = "top",
      
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        autoWidth = TRUE
      )
    )
    
  })
  
  
  # =============================================================
  # Download UIS data
  # =============================================================
  
  output$download_data <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "DF_UIS_data_",
        format(
          Sys.Date(),
          "%Y%m%d"
        ),
        ".CSV"
      )
      
    },
    
    content = function(file) {
      
      req(
        nrow(data_final()) > 0
      )
      
      write.csv(
        data_final(),
        file,
        row.names = FALSE
      )
      
    }
  )
  
  
  # =============================================================
  # Download metadata
  # =============================================================
  
  output$download_metadata <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "UIS_metadata_",
        format(
          Sys.Date(),
          "%Y%m%d"
        ),
        ".CSV"
      )
      
    },
    
    content = function(file) {
      
      req(
        nrow(metadata_dataframe()) > 0
      )
      
      write.csv(
        metadata_dataframe(),
        file,
        row.names = FALSE
      )
      
    }
  )
  
  
  # =============================================================
  # Download both files as ZIP
  # =============================================================
  
  output$download_both <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "UIS_data_and_metadata_",
        format(
          Sys.Date(),
          "%Y%m%d"
        ),
        ".zip"
      )
      
    },
    
    content = function(file) {
      
      req(
        nrow(data_final()) > 0,
        nrow(metadata_dataframe()) > 0
      )
      
      temp_dir <- tempdir()
      
      data_file <- file.path(
        temp_dir,
        "DF_UIS_data.CSV"
      )
      
      metadata_file <- file.path(
        temp_dir,
        "UIS_metadata.CSV"
      )
      
      write.csv(
        data_final(),
        data_file,
        row.names = FALSE
      )
      
      write.csv(
        metadata_dataframe(),
        metadata_file,
        row.names = FALSE
      )
      
      utils::zip(
        zipfile = file,
        files = c(
          data_file,
          metadata_file
        ),
        flags = "-j"
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