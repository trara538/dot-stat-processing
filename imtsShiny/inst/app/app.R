# ==============================================================================
# IMTS DATA PROCESSING SHINY APPLICATION
# ==============================================================================
#
# Purpose:
#   Process an IMTS Excel workbook and convert the individual worksheets into
#   one standardised IMTS dataset.
#
# Input:
#   IMTS Excel workbook (.xlsx)
#
# Output:
#   DF_IMTS_data.CSV
#
# Output location:
#   C:/Users/<USERNAME>/OneDrive - SPC/DotStat/REFDB/DF_IMTS/
#
# ==============================================================================


# ==============================================================================
# 1. LOAD REQUIRED LIBRARIES
# ==============================================================================

library(shiny)
library(readxl)
library(dplyr)
library(tidyr)
library(DT)


# ==============================================================================
# 2. APPLICATION SETTINGS
# ==============================================================================

# ------------------------------------------------------------------------------
# Dynamic repository path
# ------------------------------------------------------------------------------

repository <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)

setwd(repository)


# ------------------------------------------------------------------------------
# Windows username
# ------------------------------------------------------------------------------

username <- Sys.getenv("USERNAME")


# ------------------------------------------------------------------------------
# Output directory
# ------------------------------------------------------------------------------

output_base <- file.path(
  "C:/Users",
  username,
  "OneDrive - SPC",
  "DotStat",
  "REFDB",
  "DF_IMTS"
)


# ==============================================================================
# 3. ALLOWED IMTS WORKSHEETS
# ==============================================================================

allowed_sheets <- c(
  "bot",
  "imports",
  "exports",
  "reexports",
  "totexports",
  "bot_cty",
  "trade_reg",
  "mode_trspt",
  "x_sitc",
  "m_sitc"
)


# ==============================================================================
# 4. USER INTERFACE
# ==============================================================================

ui <- fluidPage(
  
  # ============================================================================
  # APPLICATION TITLE
  # ============================================================================
  
  titlePanel(
    "IMTS Data Processing Application"
  ),
  
  
  # ============================================================================
  # MAIN LAYOUT
  # ============================================================================
  
  sidebarLayout(
    
    # ==========================================================================
    # SIDEBAR
    # ==========================================================================
    
    sidebarPanel(
      
      width = 3,
      
      # ------------------------------------------------------------------------
      # Upload section
      # ------------------------------------------------------------------------
      
      h4("1. Upload IMTS Data"),
      
      fileInput(
        inputId = "excel_file",
        label = "Select IMTS Excel file:",
        accept = c(
          ".xlsx"
        )
      ),
      
      helpText(
        "Select the IMTS Excel workbook to be processed."
      ),
      
      hr(),
      
      
      # ------------------------------------------------------------------------
      # Process section
      # ------------------------------------------------------------------------
      
      h4("2. Process Data"),
      
      actionButton(
        inputId = "process",
        label = "Process IMTS Data",
        icon = icon("play"),
        class = "btn-primary",
        width = "100%"
      ),
      
      hr(),
      
      
      # ------------------------------------------------------------------------
      # Download section
      # ------------------------------------------------------------------------
      
      h4("3. Download Data"),
      
      downloadButton(
        outputId = "download_csv",
        label = "Download Final CSV",
        class = "btn-success",
        width = "100%"
      ),
      
      hr(),
      
      
      # ------------------------------------------------------------------------
      # Processing status
      # ------------------------------------------------------------------------
      
      h4("Processing Status"),
      
      verbatimTextOutput(
        outputId = "status"
      )
      
    ),
    
    
    # ==========================================================================
    # MAIN PANEL
    # ==========================================================================
    
    mainPanel(
      
      width = 9,
      
      tabsetPanel(
        
        # ======================================================================
        # SUMMARY TAB
        # ======================================================================
        
        tabPanel(
          
          title = "Summary",
          
          br(),
          
          fluidRow(
            
            column(
              width = 3,
              
              wellPanel(
                h4("Observations"),
                textOutput("n_rows")
              )
              
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Indicators"),
                textOutput("n_indicators")
              )
              
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Frequencies"),
                textOutput("n_freq")
              )
              
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Trade Flows"),
                textOutput("n_tradeflow")
              )
              
            )
            
          ),
          
          hr(),
          
          h4("Indicator Summary"),
          
          DTOutput(
            outputId = "indicator_summary"
          )
          
        ),
        
        
        # ======================================================================
        # FINAL DATA TAB
        # ======================================================================
        
        tabPanel(
          
          title = "IMTS Data",
          
          br(),
          
          DTOutput(
            outputId = "preview"
          )
          
        ),
        
        
        # ======================================================================
        # PROCESSING LOG TAB
        # ======================================================================
        
        tabPanel(
          
          title = "Processing Log",
          
          br(),
          
          verbatimTextOutput(
            outputId = "log"
          )
          
        )
        
      )
      
    )
    
  )
  
)


# ==============================================================================
# 5. SERVER
# ==============================================================================

server <- function(input, output, session) {
  
  
  # ============================================================================
  # REACTIVE VALUES
  # ============================================================================
  
  final_data <- reactiveVal(NULL)
  
  log_messages <- reactiveVal(
    "Waiting for IMTS data processing..."
  )
  
  output_folder <- reactiveVal(NULL)
  
  
  # ============================================================================
  # LOGGING FUNCTION
  # ============================================================================
  
  add_log <- function(message) {
    
    timestamp <- format(
      Sys.time(),
      "%Y-%m-%d %H:%M:%S"
    )
    
    new_message <- paste0(
      "[",
      timestamp,
      "] ",
      message
    )
    
    current_log <- log_messages()
    
    if (
      is.null(current_log) ||
      current_log == "Waiting for IMTS data processing..."
    ) {
      
      log_messages(
        new_message
      )
      
    } else {
      
      log_messages(
        paste(
          current_log,
          new_message,
          sep = "\n"
        )
      )
      
    }
    
  }
  
  
  # ============================================================================
  # PROCESS IMTS DATA
  # ============================================================================
  
  observeEvent(
    
    input$process,
    
    {
      
      req(input$excel_file)
      
      
      # ------------------------------------------------------------------------
      # Reset previous results
      # ------------------------------------------------------------------------
      
      final_data(NULL)
      output_folder(NULL)
      
      log_messages(
        "Starting IMTS data processing..."
      )
      
      
      # ------------------------------------------------------------------------
      # Process workbook
      # ------------------------------------------------------------------------
      
      tryCatch({
        
        withProgress(
          
          message = "Processing IMTS data...",
          
          value = 0,
          
          {
            
            # ==================================================================
            # STEP 1: READ EXCEL WORKBOOK
            # ==================================================================
            
            add_log(
              "Reading IMTS Excel workbook..."
            )
            
            file_path <- input$excel_file$datapath
            
            incProgress(
              amount = 0.10,
              detail = "Reading workbook..."
            )
            
            
            # ==================================================================
            # STEP 2: IDENTIFY WORKSHEETS
            # ==================================================================
            
            worksheet_names <- excel_sheets(
              file_path
            )
            
            add_log(
              paste(
                "Worksheets detected:",
                paste(
                  worksheet_names,
                  collapse = ", "
                )
              )
            )
            
            
            # ==================================================================
            # STEP 3: VALIDATE WORKSHEETS
            # ==================================================================
            
            invalid_sheets <- setdiff(
              worksheet_names,
              allowed_sheets
            )
            
            
            if (length(invalid_sheets) > 0) {
              
              error_message <- paste(
                "Unsupported worksheet(s):",
                paste(
                  invalid_sheets,
                  collapse = ", "
                )
              )
              
              
              add_log(
                paste(
                  "ERROR:",
                  error_message
                )
              )
              
              
              showNotification(
                error_message,
                type = "error",
                duration = NULL
              )
              
              
              return()
              
            }
            
            
            incProgress(
              amount = 0.10,
              detail = "Validating worksheets..."
            )
            
            
            # ==================================================================
            # STEP 4: PROCESS WORKSHEETS
            # ==================================================================
            
            add_log(
              "Processing IMTS worksheets..."
            )
            
            
            final_df <- data.frame()
            
            
            for (sheet_name in worksheet_names) {
              
              
              add_log(
                paste(
                  "Processing worksheet:",
                  sheet_name
                )
              )
              
              
              # ----------------------------------------------------------------
              # Read worksheet
              # ----------------------------------------------------------------
              
              df <- read_excel(
                file_path,
                sheet = sheet_name
              )
              
              
              # =================================================================
              # BALANCE OF TRADE
              # =================================================================
              
              if (sheet_name == "bot") {
                
                
                tmp <- df |>
                  
                  pivot_longer(
                    cols = -c(
                      DATAFLOW:OBS_COMMENT
                    ),
                    names_to = "TRADE_FLOW",
                    values_to = "OBS_VALUE"
                  ) |>
                  
                  mutate(
                    TIME_PERIOD = as.character(
                      TIME_PERIOD
                    )
                  )
                
                
                # =================================================================
                # COMMODITY-BASED WORKSHEETS
                # =================================================================
                
              } else if (
                
                sheet_name %in%
                c(
                  "imports",
                  "exports",
                  "reexports",
                  "totexports",
                  "x_sitc",
                  "m_sitc"
                )
                
              ) {
                
                
                tmp <- df |>
                  
                  pivot_longer(
                    cols = -c(
                      DATAFLOW:OBS_COMMENT
                    ),
                    names_to = "COMMODITY",
                    values_to = "OBS_VALUE"
                  ) |>
                  
                  mutate(
                    TIME_PERIOD = as.character(
                      TIME_PERIOD
                    )
                  )
                
                
                # =================================================================
                # BALANCE OF TRADE BY COUNTRY
                # =================================================================
                
              } else if (
                sheet_name == "bot_cty"
              ) {
                
                
                tmp <- df |>
                  
                  pivot_longer(
                    cols = -c(
                      DATAFLOW:OBS_COMMENT
                    ),
                    names_to = "TIME_PERIOD",
                    values_to = "OBS_VALUE"
                  ) |>
                  
                  mutate(
                    FREQ = ifelse(
                      nchar(TIME_PERIOD) > 4,
                      "M",
                      "A"
                    ),
                    TIME_PERIOD = as.character(
                      TIME_PERIOD
                    )
                  )
                
                
                # =================================================================
                # MODE OF TRANSPORT
                # =================================================================
                
              } else if (
                sheet_name == "mode_trspt"
              ) {
                
                
                tmp <- df |>
                  
                  pivot_longer(
                    cols = -c(
                      DATAFLOW:OBS_COMMENT
                    ),
                    names_to = "TRANSPORT",
                    values_to = "OBS_VALUE"
                  ) |>
                  
                  mutate(
                    TIME_PERIOD = as.character(
                      TIME_PERIOD
                    )
                  )
                
                
                # =================================================================
                # OTHER WORKSHEETS
                # =================================================================
                
              } else {
                
                
                tmp <- df |>
                  
                  pivot_longer(
                    cols = -c(
                      DATAFLOW:OBS_COMMENT
                    ),
                    names_to = "TIME_PERIOD",
                    values_to = "OBS_VALUE"
                  ) |>
                  
                  mutate(
                    FREQ = ifelse(
                      nchar(TIME_PERIOD) > 4,
                      "M",
                      "A"
                    ),
                    TIME_PERIOD = as.character(
                      TIME_PERIOD
                    )
                  )
                
              }
              
              
              # ----------------------------------------------------------------
              # Append processed worksheet
              # ----------------------------------------------------------------
              
              final_df <- bind_rows(
                final_df,
                tmp
              )
              
            }
            
            
            incProgress(
              amount = 0.60,
              detail = "Cleaning data..."
            )
            
            
            # ==================================================================
            # STEP 5: CLEAN FINAL DATASET
            # ==================================================================
            
            add_log(
              "Removing observations with missing values..."
            )
            
            
            final_df <- final_df |>
              
              filter(
                !is.na(OBS_VALUE)
              )
            
            
            # ------------------------------------------------------------------
            # Replace remaining NA values with empty strings
            # ------------------------------------------------------------------
            
            final_df[
              is.na(final_df)
            ] <- ""
            
            
            # ------------------------------------------------------------------
            # Convert observation values to numeric
            # ------------------------------------------------------------------
            
            final_df <- final_df |>
              
              mutate(
                OBS_VALUE = round(
                  as.numeric(
                    OBS_VALUE
                  ),
                  0
                )
              )
            
            
            # ------------------------------------------------------------------
            # Standardise final column order
            # ------------------------------------------------------------------
            
            final_df <- final_df |>
              
              select(
                DATAFLOW,
                FREQ,
                TIME_PERIOD,
                GEO_PICT,
                INDICATOR,
                TRADE_FLOW,
                COMMODITY,
                COUNTERPART,
                TRANSPORT,
                CURRENCY,
                OBS_VALUE,
                UNIT_MEASURE,
                UNIT_MULT,
                OBS_STATUS,
                DATA_SOURCE,
                OBS_COMMENT
              )
            
            
            # ==================================================================
            # STEP 6: STORE FINAL DATA
            # ==================================================================
            
            final_data(
              final_df
            )
            
            
            add_log(
              paste(
                "Final dataset contains",
                format(
                  nrow(final_df),
                  big.mark = ","
                ),
                "observations."
              )
            )
            
            
            # ==================================================================
            # STEP 7: CREATE OUTPUT DIRECTORY
            # ==================================================================
            
            timestamp <- format(
              Sys.time(),
              "%Y%m%d_%H%M%S"
            )
            
            
            folder_name <- paste0(
              timestamp,
              "_IMTS_data_Update"
            )
            
            
            folder_path <- file.path(
              output_base,
              folder_name
            )
            
            
            if (!dir.exists(output_base)) {
              
              dir.create(
                output_base,
                recursive = TRUE
              )
              
            }
            
            
            if (!dir.exists(folder_path)) {
              
              dir.create(
                folder_path,
                recursive = TRUE
              )
              
            }
            
            
            output_folder(
              folder_path
            )
            
            
            add_log(
              paste(
                "Output folder created:",
                folder_path
              )
            )
            
            
            # ==================================================================
            # STEP 8: SAVE FINAL CSV
            # ==================================================================
            
            output_file <- file.path(
              folder_path,
              "DF_IMTS_data.CSV"
            )
            
            
            write.csv(
              final_df,
              output_file,
              row.names = FALSE,
              na = ""
            )
            
            
            add_log(
              paste(
                "Final CSV saved:",
                output_file
              )
            )
            
            
            # ==================================================================
            # STEP 9: COMPLETE PROCESSING
            # ==================================================================
            
            incProgress(
              amount = 1,
              detail = "Processing completed."
            )
            
            
            add_log(
              "IMTS data processing completed successfully."
            )
            
            
            showNotification(
              "IMTS data processing completed successfully.",
              type = "message",
              duration = 5
            )
            
          }
          
        )
        
      },
      
      
      # ========================================================================
      # ERROR HANDLING
      # ========================================================================
      
      error = function(e) {
        
        error_message <- conditionMessage(
          e
        )
        
        
        add_log(
          paste(
            "ERROR:",
            error_message
          )
        )
        
        
        showNotification(
          paste(
            "Processing failed:",
            error_message
          ),
          type = "error",
          duration = NULL
        )
        
      }
      
      )
      
    }
    
  )
  
  
  # ============================================================================
  # SUMMARY - NUMBER OF OBSERVATIONS
  # ============================================================================
  
  output$n_rows <- renderText({
    
    req(final_data())
    
    format(
      nrow(final_data()),
      big.mark = ","
    )
    
  })
  
  
  # ============================================================================
  # SUMMARY - NUMBER OF INDICATORS
  # ============================================================================
  
  output$n_indicators <- renderText({
    
    req(final_data())
    
    dplyr::n_distinct(
      final_data()$INDICATOR
    )
    
  })
  
  
  # ============================================================================
  # SUMMARY - NUMBER OF FREQUENCIES
  # ============================================================================
  
  output$n_freq <- renderText({
    
    req(final_data())
    
    dplyr::n_distinct(
      final_data()$FREQ
    )
    
  })
  
  
  # ============================================================================
  # SUMMARY - NUMBER OF TRADE FLOWS
  # ============================================================================
  
  output$n_tradeflow <- renderText({
    
    req(final_data())
    
    dplyr::n_distinct(
      final_data()$TRADE_FLOW
    )
    
  })
  
  
  # ============================================================================
  # INDICATOR SUMMARY TABLE
  # ============================================================================
  
  output$indicator_summary <- renderDT({
    
    req(final_data())
    
    
    summary_df <- final_data() |>
      
      count(
        FREQ,
        INDICATOR,
        name = "Observations"
      )
    
    
    datatable(
      summary_df,
      
      filter = "top",
      
      extensions = "Buttons",
      
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c(
          "copy",
          "csv",
          "excel"
        )
      )
      
    )
    
  })
  
  
  # ============================================================================
  # FINAL DATA TABLE
  # ============================================================================
  
  output$preview <- renderDT({
    
    req(final_data())
    
    
    datatable(
      final_data(),
      
      filter = "top",
      
      extensions = "Buttons",
      
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = "Bfrtip",
        buttons = c(
          "copy",
          "csv",
          "excel"
        )
      )
      
    )
    
  })
  
  
  # ============================================================================
  # PROCESSING LOG
  # ============================================================================
  
  output$log <- renderText({
    
    log_messages()
    
  })
  
  
  # ============================================================================
  # PROCESSING STATUS
  # ============================================================================
  
  output$status <- renderText({
    
    if (is.null(final_data())) {
      
      "Waiting for IMTS Excel file..."
      
    } else {
      
      paste(
        "Processing completed successfully.",
        "The final dataset is ready for download.",
        sep = "\n"
      )
      
    }
    
  })
  
  
  # ============================================================================
  # DOWNLOAD FINAL CSV
  # ============================================================================
  
  output$download_csv <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "DF_IMTS_data_",
        format(
          Sys.time(),
          "%Y%m%d_%H%M%S"
        ),
        ".CSV"
      )
      
    },
    
    content = function(file) {
      
      req(final_data())
      
      
      write.csv(
        final_data(),
        file,
        row.names = FALSE,
        na = ""
      )
      
    }
    
  )
  
}


# ==============================================================================
# 6. RUN APPLICATION
# ==============================================================================

shinyApp(
  ui = ui,
  server = server
)