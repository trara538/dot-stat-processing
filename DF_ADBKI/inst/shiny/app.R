# ===============================================================
# ADB KEY INDICATORS PROCESSING SHINY APPLICATION
# ===============================================================

# ===============================================================
# Load required libraries
# ===============================================================

library(shiny)
library(readr)
library(dplyr)
library(tibble)
library(DT)

# ===============================================================
# Working directory
# ===============================================================

repository <- normalizePath(".", winslash = "/", mustWork = TRUE)

username <- Sys.getenv("USERNAME")

# ===============================================================
# Countries
# ===============================================================

country <- c(
  "ASM",
  "COO",
  "FIJ",
  "FSM",
  "GUM",
  "KIR",
  "MNP",
  "NAU",
  "NCL",
  "NIU",
  "PCN",
  "PLW",
  "PNG",
  "PYF",
  "RMI",
  "SAM",
  "SOL",
  "TKL",
  "TON",
  "TUV",
  "VAN",
  "WLF"
)

# ===============================================================
# ADB Indicators
# ===============================================================

indicatorCode <- c(
  "NGDPVA_R_ISIC4_A_XDC",
  "NGDPVA_R_ISIC4_B_XDC",
  "NGDPVA_R_ISIC4_C_XDC",
  "NGDPVA_R_ISIC4_D_XDC",
  "NGDPVA_R_ISIC4_E_XDC",
  "NGDPVA_R_ISIC4_F_XDC",
  "NGDPVA_WT_R_XDC_PS",
  "NGDPVA_RT_R_XDC_PS",
  "NGDPVA_R_ISIC4_G_XDC",
  "NGDPVA_R_ISIC4_I_XDC",
  "NGDPVA_R_ISIC4_H_XDC",
  "NGDPVA_R_ISIC4_J_XDC",
  "NGDPVA_R_ISIC4_K_XDC",
  "NGDPVA_R_ISIC4_L_XDC",
  "NGDPVA_R_ISIC4_M_XDC",
  "NGDPVA_R_ISIC4_N_XDC",
  "NGDPVA_R_ISIC4_O_XDC",
  "NGDPVA_R_ISIC4_P_XDC",
  "NGDPVA_R_ISIC4_Q_XDC",
  "NGDPVA_R_ISIC4_R_XDC",
  "NGDPVA_OSA_R_XDC_PS",
  "NGDPVA_R_ISIC4_T_XDC",
  "NGDPVA_R_ISIC4_U_XDC",
  "NGDPVA_R_XDC",
  "NGDP_R_PTX_PS",
  "NGDPVA_R_ISIC4_A_PC_CP_A_PT",
  "NGDPVA_IND_R_PTX_PS",
  "NGDPVA_SER_R_PTX_PS",
  "ENEL_PR_PS",
  "ENEL_CS_PS",
  "PCPI_IX",
  "PCPI_CP_01_IX",
  "PCPI_CP_02_IX",
  "PCPI_CP_03_IX",
  "PCPI_CP_04_IX",
  "PCPI_CP_05_IX",
  "PCPI_CP_06_IX",
  "PCPI_CP_07_IX",
  "PCPI_CP_08_IX",
  "PCPI_CP_09_IX",
  "PCPI_CP_10_IX",
  "PCPI_CP_11_IX",
  "PCPI_CP_13_IX"
)

# ===============================================================
# Country query
# ===============================================================

countries <- paste(country, collapse = "+")

# ===============================================================
# UI
# ===============================================================

ui <- fluidPage(
  titlePanel("ADB Key Indicators Processing Application"),
  
  sidebarLayout(
    
    # ===========================================================
    # Sidebar
    # ===========================================================
    
    sidebarPanel(
      
      h4("ADB Data Processing"),
      
      p(
        "This application downloads ADB Key Indicators ",
        "for Pacific Island countries and prepares the data ",
        "for the SPC DotStat REFDB."
      ),
      
      hr(),
      
      strong("Countries"),
      
      p(
        paste(
          length(country),
          "countries configured for download."
        )
      ),
      
      hr(),
      
      strong("Indicators"),
      
      p(
        paste(
          length(indicatorCode),
          "indicators configured."
        )
      ),
      
      hr(),
      
      strong("Data period"),
      
      p("2000 to 2026"),
      
      hr(),
      
      # ---------------------------------------------------------
      # Process button
      # ---------------------------------------------------------
      
      actionButton(
        inputId = "process",
        label = "Process Data",
        icon = icon("play"),
        class = "btn-primary",
        width = "100%"
      ),
      
      br(),
      br(),
      
      # ---------------------------------------------------------
      # Download button
      # ---------------------------------------------------------
      
      downloadButton(
        outputId = "download_data",
        label = "Download ADB Data",
        class = "btn-success",
        width = "100%"
      ),
      
      hr(),
      
      # ---------------------------------------------------------
      # Status
      # ---------------------------------------------------------
      
      h4("Status"),
      
      verbatimTextOutput("status")
    ),
    
    # ===========================================================
    # Main panel
    # ===========================================================
    
    mainPanel(
      
      tabsetPanel(
        
        # -------------------------------------------------------
        # Summary
        # -------------------------------------------------------
        
        tabPanel("Summary",
          br(),
          h4("Processing Summary"),
          DTOutput("summary_table"),
          br(),
          h4("Final ADB Data"),
          DTOutput("data_preview")
        ),
        
        # -------------------------------------------------------
        # ADB Data
        # -------------------------------------------------------
        
        tabPanel("ADB Data",
          br(),
          h4("DF_ADBKI Data"),
          DTOutput("adb_data_table")
        ),
        
        # -------------------------------------------------------
        # Processing Log
        # -------------------------------------------------------
        
        tabPanel("Processing Log",
          br(),
          h4("Processing Log"),
          verbatimTextOutput("processing_log")
        )
      )
    )
  )
)

# ===============================================================
# SERVER
# ===============================================================

server <- function(input, output, session) {
  
  # =============================================================
  # Reactive objects
  # =============================================================
  
  data_final <- reactiveVal(
    data.frame()
  )
  
  output_folder <- reactiveVal(
    NULL
  )
  
  processing_status <- reactiveVal("Waiting for processing to start...")
  processing_log <- reactiveVal("Application ready.")
  
  # =============================================================
  # Status output
  # =============================================================
  
  output$status <- renderText({
    processing_status()
    
  })
  
  # =============================================================
  # Processing log output
  # =============================================================
  
  output$processing_log <- renderText({
    processing_log()
    
  })
  
  # =============================================================
  # Process data
  # =============================================================
  
  observeEvent(
    input$process,
    {
      
      # ---------------------------------------------------------
      # Reset previous results
      # ---------------------------------------------------------
      
      data_final(data.frame())
      output_folder(NULL)
      processing_status("Starting ADB data processing...")
      processing_log(paste0("ADB processing started at ",
          format(
            Sys.time(), "%Y-%m-%d %H:%M:%S"),
          "\n"
        )
      )
      
      # ---------------------------------------------------------
      # Validate country.csv
      # ---------------------------------------------------------
      
      country_file <- file.path(repository, "country.csv")
      
      if (!file.exists(country_file)) {
        
        processing_status("ERROR: country.csv was not found.")
        processing_log(
          paste0(processing_log(), "\nERROR: country.csv was not found at:\n",
            country_file
          )
        )
        return()
      }
      
      # ---------------------------------------------------------
      # Read country mapping
      # ---------------------------------------------------------
      
      economy <- tryCatch(
        
        {
          read.csv(country_file, stringsAsFactors = FALSE) |>
            select(GEO_PICT, REF_AREA) |>
            rename(ECONOMY_CODE = REF_AREA)
        },
        
        error = function(e) {
          
          processing_status("ERROR reading country.csv.")
          processing_log(
            paste0(processing_log(), "\nERROR reading country.csv:\n", e$message)
          )
          return(NULL)
        }
      )
      
      if (is.null(economy)) {
         return()
      }
      
      # ---------------------------------------------------------
      # Check country mapping
      # ---------------------------------------------------------
      
      missing_countries <- setdiff(
        country,
        economy$ECONOMY_CODE
      )
      
      if (length(missing_countries) > 0) {
        
        processing_status(
          paste("ERROR: Some PICT country codes are missing from country.csv:",
            paste(missing_countries, collapse = ", ")
          )
        )
        
        processing_log(
          paste0(
            processing_log(),
            "\nERROR: Missing country codes in country.csv:\n",
            paste(missing_countries, collapse = ", ")
          )
        )
        return()
      }
      
      # ---------------------------------------------------------
      # Create country query
      # ---------------------------------------------------------
      
      countries <- paste(country, collapse = "+")
      
      # ---------------------------------------------------------
      # List to hold each downloaded indicator
      #
      # IMPORTANT:
      # This is the corrected syntax.
      # We store each dataset using the indicator code as
      # the list element name.
      # ---------------------------------------------------------
      
      downloaded_data <- list()
      
      # ---------------------------------------------------------
      # Start progress
      # ---------------------------------------------------------
      
      withProgress(
        message = "Downloading ADB Key Indicators",
        value = 0,
        {
          for (i in seq_along(indicatorCode)) {
            ind <- indicatorCode[i]
            
            # ---------------------------------------------------
            # Update progress
            # ---------------------------------------------------
            
            incProgress(1 / length(indicatorCode), detail = paste("Downloading", i, "of", length(indicatorCode), ":", ind))
            
            # ---------------------------------------------------
            # Build API URL
            # ---------------------------------------------------
            
            url <- paste0(
              "https://kidb.adb.org/api/v5/sdmx/data/",
              "ADB,DF_KIDB/",
              "A.",
              ind,
              ".",
              countries,
              "?version=3.0",
              "&format=sdmx-csv",
              "&startPeriod=2000"
              #"&endPeriod=2026"
            )
            
            # ---------------------------------------------------
            # Update status
            # ---------------------------------------------------
            
            processing_status(
              paste0("Downloading indicator ", i, " of ", length(indicatorCode), "\n\n", ind))
            
            # ---------------------------------------------------
            # Download data
            # ---------------------------------------------------
            
            data <- tryCatch(
              {
                read_csv(url, show_col_types = FALSE)
              },
              error = function(e) {
                processing_log(paste0(processing_log(), "\n\nERROR downloading ", ind, ":\n", e$message))
                return(NULL)
              }
            )
            
            # ---------------------------------------------------
            # Skip failed download
            # ---------------------------------------------------
            
            if (is.null(data)) {
              next
            }
            
            # ---------------------------------------------------
            # Skip empty result
            # ---------------------------------------------------
            
            if (nrow(data) == 0) {
              processing_log(paste0(processing_log(), "\n\nNo data returned for ", ind))
              next
            }
            
            # ---------------------------------------------------
            # Standardise data types
            #
            # This prevents bind_rows() errors caused by fields
            # such as BASE_YEAR being character in one download
            # and numeric in another.
            # ---------------------------------------------------
            
            data <- data |>
              mutate(
                DATAFLOW = as.character("SPC:DF_ADBKI(1.2)"),
                FREQ = as.character(FREQ),
                INDICATOR = as.character(INDICATOR),
                ECONOMY_CODE = as.character(ECONOMY_CODE),
                TIME_PERIOD = as.character(TIME_PERIOD),
                OBS_VALUE = as.numeric(OBS_VALUE),
                UNIT_MEASURE = as.character(ifelse(UNIT == "PCT", "PERCENT", UNIT)),
                UNIT_MULT = as.character(UNIT_MULT),
                DECIMALS = as.character(DECIMALS),
                FOOTNOTE = as.character(FOOTNOTE),
                OBS_STATUS = as.character(OBS_STATUS),
                REF_YEAR = as.character(REF_YEAR),
                BASE_PER = as.character(BASE_YEAR),
                OBS_DATA_SOURCE = as.character(DATA_SOURCE),
                METHODOLOGY = as.character(METHODOLOGY),
                OBS_COMMENT = as.character("")
                ) |>
              
              select(-any_of(c("UNIT", "BASE_YEAR", "DATA_SOURCE")))
            
            # ---------------------------------------------------
            # Merge PICT country information
            # ---------------------------------------------------
            
            data <- merge(data, economy, by = "ECONOMY_CODE")
            
            # ---------------------------------------------------
            # Remove ECONOMY_CODE
            # ---------------------------------------------------
            
            data <- data |>
              select(
                -ECONOMY_CODE
              )
            
            # ---------------------------------------------------
            # Round OBS_VALUE according to DECIMALS
            # ---------------------------------------------------
            
            data <- data |>
              mutate(
                
                OBS_VALUE = ifelse(
                  
                  is.na(OBS_VALUE),
                  
                  NA_real_,
                  
                  round(
                    OBS_VALUE,
                    as.numeric(
                      DECIMALS
                    )
                  )
                  
                )
                
              )
            
            # ---------------------------------------------------
            # Select final fields
            # ---------------------------------------------------
            
            data <- data |>
              select(
                
                DATAFLOW,
                FREQ,
                GEO_PICT,
                INDICATOR,
                TIME_PERIOD,
                OBS_VALUE,
                METHODOLOGY,
                BASE_PER,
                OBS_DATA_SOURCE,
                UNIT_MEASURE,
                UNIT_MULT,
                OBS_STATUS,
                OBS_COMMENT,
                DECIMALS,
                FOOTNOTE,
                REF_YEAR
                
              )
            
            # ---------------------------------------------------
            # Replace NA with blank for all fields except
            # OBS_VALUE
            # ---------------------------------------------------
            
            data <- data |>
              mutate(
                across(
                  -OBS_VALUE,
                  ~ replace(
                    .x,
                    is.na(.x),
                    ""
                  )
                )
              )
            
            # ---------------------------------------------------
            # CORRECTED downloaded_data assignment
            #
            # Instead of:
            #
            # downloaded_data[
            #   [length(downloaded_data) + 1]
            #
            # use:
            #
            # downloaded_data[[ind]] <- data
            #
            # ---------------------------------------------------
            
            downloaded_data[[ind]] <- data
            
            # ---------------------------------------------------
            # Log successful download
            # ---------------------------------------------------
            
            processing_log(paste0(processing_log(), "\n\nDownloaded ", nrow(data), " rows for ", ind, "."))
            
            # ---------------------------------------------------
            # Small delay between requests
            # ---------------------------------------------------
            
            Sys.sleep(2)
            
          }
          
        }
      )
      
      # =========================================================
      # Combine all downloaded datasets
      # =========================================================
      
      if (length(downloaded_data) == 0) {
        
        processing_status("No ADB data were successfully downloaded.")
        
        processing_log(
          paste0(
            processing_log(),
            "\n\n========================================",
            "\nPROCESSING COMPLETED",
            "\n========================================",
            "\nNo data were downloaded."
          )
        )
        
        return()
        
      }
      
      # ---------------------------------------------------------
      # Combine downloaded data
      #
      # This is where bind_rows() combines the list elements.
      # ---------------------------------------------------------
      
      final_data <- tryCatch(
        
        {
          
          bind_rows(
            downloaded_data
          )
          
        },
        
        error = function(e) {
          
          processing_status("ERROR combining downloaded data.")
          processing_log(paste0(processing_log(), "\n\nERROR combining downloaded data:\n", e$message))
          
          return(NULL)
          
        }
      )
      
      if (is.null(final_data)) {
        
        return()
        
      }
      
      # =========================================================
      # Save final reactive data
      # =========================================================
      
      data_final(
        final_data
      )
      
      # =========================================================
      # Create OneDrive output directory
      # =========================================================
      
      oneDrivePath <- paste0("C:/Users/", username, "/OneDrive - SPC/DotStat/REFDB/DF_ADBKI")
      
      myYear <- format(Sys.Date(), "%Y")
      myMonth <- format(Sys.Date(), "%m")
      myDay <- format(Sys.Date(), "%d")
      myHour <- format(Sys.time(), "%H")
      myMin <- format(Sys.time(), "%M")
      mySecond <- format(Sys.time(), "%S")
      
      folderName <- paste0(myYear, myMonth, myDay, "_", myHour, myMin, mySecond, "_data_Update")
      newFolder <- file.path(oneDrivePath, folderName)
      newFile <- file.path(newFolder, "DF_ADBKI-data.CSV")
      
      # ---------------------------------------------------------
      # Create output directory
      # ---------------------------------------------------------
      
      dir.create(
        newFolder,
        recursive = TRUE,
        showWarnings = FALSE
      )
      
      # =========================================================
      # Write final CSV
      # =========================================================
      
      write.csv(final_data, newFile, row.names = FALSE, na = "")
      
      # =========================================================
      # Save output folder
      # =========================================================
      
      output_folder(newFolder)
      
      # =========================================================
      # Final status
      # =========================================================
      
      processing_status(
        paste0(
          "Processing completed successfully.\n\n",
          "Countries: ",
          length(country),
          "\n",
          "Indicators: ",
          length(indicatorCode),
          "\n",
          "Observations: ",
          nrow(final_data),
          "\n",
          "Columns: ",
          ncol(final_data),
          "\n\n",
          "Output folder:\n",
          newFolder
        )
      )
      
      processing_log(
        paste0(
          processing_log(),
          
          "\n\n========================================",
          
          "\nDOWNLOAD COMPLETED",
          
          "\n========================================",
          
          "\nIndicators requested: ",
          length(indicatorCode),
          
          "\nIndicators successfully downloaded: ",
          length(downloaded_data),
          
          "\nCountries configured: ",
          length(country),
          
          "\nTotal rows downloaded: ",
          nrow(final_data),
          
          "\nTotal columns: ",
          ncol(final_data),
          
          "\n\nOutput file:",
          
          "\n",
          newFile
        )
      )
      
    }
  )
  
  # =============================================================
  # Summary table
  # =============================================================
  
  output$summary_table <- renderDT(
    
    {
      
      data <- data_final()
      
      if (nrow(data) == 0) {
        
        summary <- data.frame(
          Item = c(
            "Countries",
            "Indicators",
            "ADB observations",
            "Data columns"
          ),
          Value = c(
            length(country),
            length(indicatorCode),
            0,
            16
          )
        )
        
      } else {
        
        summary <- data.frame(
          Item = c(
            "Countries configured",
            "Indicators configured",
            "Countries in downloaded data",
            "Indicators in downloaded data",
            "ADB observations",
            "Data columns"
          ),
          Value = c(
            length(country),
            length(indicatorCode),
            dplyr::n_distinct(
              data$GEO_PICT
            ),
            dplyr::n_distinct(
              data$INDICATOR
            ),
            nrow(data),
            ncol(data)
          )
        )
        
      }
      
      datatable(
        summary,
        rownames = FALSE,
        options = list(pageLength = 10, dom = "t")
      )
    }
  )
  
  # =============================================================
  # Data preview
  # =============================================================
  
  output$data_preview <- renderDT(
    
    {
      data <- data_final()
      
      if (nrow(data) == 0) {
        
        return(
          datatable(
            data.frame(
              Message = "No data processed yet."
            ),
            rownames = FALSE,
            options = list(dom = "t")
          )
        )
        
      }
      
      datatable(
        head(
          data,
          100
        ),
        rownames = FALSE,
        filter = "top",
        extensions = "Buttons",
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel")
        )
      )
    }
  )
  
  # =============================================================
  # Full ADB data table
  # =============================================================
  
  output$adb_data_table <- renderDT(
    
    {
      data <- data_final()
      
      if (nrow(data) == 0) {
        
        return(
          datatable(
            data.frame(
              Message = "No data processed yet."
            ),
            rownames = FALSE,
            options = list(dom = "t")
          )
        )
      }
      
      datatable(
        data,
        rownames = FALSE,
        filter = "top",
        extensions = "Buttons",
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          scrollY = "600px",
          dom = "Bfrtip",
          buttons = c("copy", "csv", "excel")
        )
      )
    }
  )
  
  # =============================================================
  # Download final data from Shiny
  # =============================================================
  
  output$download_data <- downloadHandler(
    
    filename = function() {
      paste0("DF_ADBKI-data_", format(Sys.Date(),"%Y%m%d"), ".CSV")
    },
    
    content = function(file) {
      
      data <- data_final()
      
      if (nrow(data) == 0) {
        write.csv(data.frame(
            Message = "No data available. Please process the data first."
          ),
          file,
          row.names = FALSE
        )
      } else {
        write.csv(data, file, row.names = FALSE,  na = "")
      }
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