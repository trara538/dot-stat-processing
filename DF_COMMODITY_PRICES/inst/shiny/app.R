# ============================================================
# WORLD BANK COMMODITY PRICES
# SHINY DATA PROCESSING APPLICATION
# ============================================================

# ============================================================
# Load required libraries
# ============================================================

library(shiny)
library(dplyr)
library(readxl)
library(readr)
library(DT)
library(tidyr)


# ============================================================
# Application settings
# ============================================================

username <- Sys.getenv("USERNAME")

# Current application directory
app_dir <- normalizePath(
  ".",
  winslash = "/",
  mustWork = TRUE
)


# ============================================================
# Commodity price list
# ============================================================

commodity_list_file <- file.path(
  app_dir,
  "CPriceList.csv"
)

if (!file.exists(commodity_list_file)) {
  
  stop(
    paste0(
      "CPriceList.csv was not found.\n\n",
      "Expected location:\n",
      commodity_list_file
    )
  )
}

comPriceList <- read.csv(
  commodity_list_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)


# ============================================================
# World Bank URLs
# ============================================================

annual_url <- paste0(
  "https://thedocs.worldbank.org/en/doc/",
  "74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/",
  "related/CMO-Historical-Data-Annual.xlsx"
)

monthly_url <- paste0(
  "https://thedocs.worldbank.org/en/doc/",
  "74e8be41ceb20fa0da750cda2f6b9e4e-0050012026/",
  "related/CMO-Historical-Data-Monthly.xlsx"
)


# ============================================================
# Function: Download annual prices
# ============================================================

aPrices <- function() {
  
  destfile <- file.path(
    tempdir(),
    "CMO-Historical-Data-Annual.xlsx"
  )
  
  download.file(
    url = annual_url,
    destfile = destfile,
    mode = "wb",
    quiet = TRUE
  )
  
  data <- read_excel(
    destfile,
    sheet = "Annual Prices (Nominal)"
  )
  
  # ----------------------------------------------------------
  # Remove unwanted rows
  # ----------------------------------------------------------
  
  data <- data[-c(1:5), ]
  
  # ----------------------------------------------------------
  # Use first remaining row as column names
  # ----------------------------------------------------------
  
  colnames(data) <- as.character(
    unlist(data[1, ])
  )
  
  data <- data[-1, ]
  
  # ----------------------------------------------------------
  # Transpose
  # ----------------------------------------------------------
  
  data_t <- t(data)
  
  # ----------------------------------------------------------
  # Use first row as column names
  # ----------------------------------------------------------
  
  colnames(data_t) <- as.character(
    unlist(data_t[1, ])
  )
  
  data_t <- data_t[-1, ]
  
  # ----------------------------------------------------------
  # Move row names into first column
  # ----------------------------------------------------------
  
  data_t <- cbind(
    Label = rownames(data_t),
    data_t
  )
  
  rownames(data_t) <- NULL
  
  # ----------------------------------------------------------
  # Rename first three columns
  # ----------------------------------------------------------
  
  colnames(data_t)[1:3] <- c(
    "Name",
    "unit",
    "code"
  )
  
  # ----------------------------------------------------------
  # Return
  # ----------------------------------------------------------
  
  data_t
}


# ============================================================
# Function: Download monthly prices
# ============================================================

mPrices <- function() {
  
  destfile <- file.path(
    tempdir(),
    "CMO-Historical-Data-Monthly.xlsx"
  )
  
  download.file(
    url = monthly_url,
    destfile = destfile,
    mode = "wb",
    quiet = TRUE
  )
  
  mdata <- read_excel(
    destfile,
    sheet = "Monthly Prices"
  )
  
  # ----------------------------------------------------------
  # Remove unwanted rows
  # ----------------------------------------------------------
  
  mdata <- mdata[-c(1:3), ]
  
  # ----------------------------------------------------------
  # Use first remaining row as column names
  # ----------------------------------------------------------
  
  colnames(mdata) <- as.character(
    unlist(mdata[1, ])
  )
  
  mdata <- mdata[-1, ]
  
  # ----------------------------------------------------------
  # Transpose
  # ----------------------------------------------------------
  
  mdata_t <- t(mdata)
  
  # ----------------------------------------------------------
  # Use first row as column names
  # ----------------------------------------------------------
  
  colnames(mdata_t) <- as.character(
    unlist(mdata_t[1, ])
  )
  
  mdata_t <- mdata_t[-1, ]
  
  # ----------------------------------------------------------
  # Move row names into first column
  # ----------------------------------------------------------
  
  mdata_t <- cbind(
    Label = rownames(mdata_t),
    mdata_t
  )
  
  rownames(mdata_t) <- NULL
  
  # ----------------------------------------------------------
  # Rename first three columns
  # ----------------------------------------------------------
  
  colnames(mdata_t)[1:3] <- c(
    "Name",
    "unit",
    "code"
  )
  
  # ----------------------------------------------------------
  # Convert monthly periods
  #
  # Example:
  # 2025M01 -> 2025-01
  # ----------------------------------------------------------
  
  colnames(mdata_t)[-(1:2)] <- gsub(
    "^([0-9]{4})M([0-9]{2})$",
    "\\1-\\2",
    colnames(mdata_t)[-(1:2)]
  )
  
  # ----------------------------------------------------------
  # Return
  # ----------------------------------------------------------
  
  mdata_t
}


# ============================================================
# Function: Process annual commodity prices
# ============================================================

process_annual <- function(comPrice, comPriceList) {
  
  # ----------------------------------------------------------
  # Merge with commodity reference list
  # ----------------------------------------------------------
  
  commodityPrices <- merge(
    comPrice,
    comPriceList,
    by = "Name"
  )
  
  # ----------------------------------------------------------
  # Move Id to first column
  # ----------------------------------------------------------
  
  commodityPrices <- commodityPrices[
    ,
    c(
      ncol(commodityPrices),
      1:(ncol(commodityPrices) - 1)
    )
  ]
  
  # ----------------------------------------------------------
  # Identify time-period columns
  # ----------------------------------------------------------
  
  value_columns <- colnames(
    commodityPrices
  )[
    !(
      colnames(commodityPrices) %in%
        c(
          "Id",
          "Name",
          "unit",
          "UNIT_MEASURE",
          "code"
        )
    )
  ]
  
  # ----------------------------------------------------------
  # Convert wide data to long format
  # ----------------------------------------------------------
  
  CPrice_long <- purrr::map_dfr(
    value_columns,
    function(col) {
      
      data.frame(
        COMMODITY = commodityPrices$Id,
        UNIT_MEASURE = commodityPrices$UNIT_MEASURE,
        TIME_PERIOD = col,
        OBS_VALUE = commodityPrices[[col]],
        stringsAsFactors = FALSE
      )
    }
  )
  
  # ----------------------------------------------------------
  # Clean observations
  # ----------------------------------------------------------
  
  CPrice_long$OBS_VALUE <- as.numeric(
    CPrice_long$OBS_VALUE
  )
  
  CPrice_long <- CPrice_long |>
    filter(
      !is.na(OBS_VALUE),
      UNIT_MEASURE != ""
    )
  
  # ----------------------------------------------------------
  # Add SDMX fields
  # ----------------------------------------------------------
  
  CPrice_long <- CPrice_long |>
    mutate(
      DATAFLOW = "SPC:DF_COMMODITY_PRICES(1.0)",
      FREQ = "A",
      INDICATOR = "COMPRICE",
      UNIT_MULT = "",
      OBS_STATUS = "",
      DATA_SOURCE = "",
      OBS_COMMENT = ""
    ) |>
    select(
      DATAFLOW,
      FREQ,
      TIME_PERIOD,
      COMMODITY,
      INDICATOR,
      OBS_VALUE,
      UNIT_MEASURE,
      UNIT_MULT,
      OBS_STATUS,
      DATA_SOURCE,
      OBS_COMMENT
    ) |>
    mutate(
      OBS_VALUE = round(
        as.numeric(OBS_VALUE),
        2
      )
    )
  
  CPrice_long
}


# ============================================================
# Function: Process monthly commodity prices
# ============================================================

process_monthly <- function(comPrice_m, comPriceList) {
  
  # ----------------------------------------------------------
  # Merge with commodity reference list
  # ----------------------------------------------------------
  
  commodityPrices_m <- merge(
    comPrice_m,
    comPriceList,
    by = "Name"
  )
  
  # ----------------------------------------------------------
  # Move Id to first column
  # ----------------------------------------------------------
  
  commodityPrices_m <- commodityPrices_m[
    ,
    c(
      ncol(commodityPrices_m),
      1:(ncol(commodityPrices_m) - 1)
    )
  ]
  
  # ----------------------------------------------------------
  # Identify time-period columns
  # ----------------------------------------------------------
  
  value_columns <- colnames(
    commodityPrices_m
  )[
    !(
      colnames(commodityPrices_m) %in%
        c(
          "Id",
          "Name",
          "unit",
          "UNIT_MEASURE",
          "code"
        )
    )
  ]
  
  # ----------------------------------------------------------
  # Convert wide data to long format
  # ----------------------------------------------------------
  
  CPrice_long_m <- purrr::map_dfr(
    value_columns,
    function(col) {
      
      data.frame(
        COMMODITY = commodityPrices_m$Id,
        UNIT_MEASURE = commodityPrices_m$UNIT_MEASURE,
        TIME_PERIOD = col,
        OBS_VALUE = commodityPrices_m[[col]],
        stringsAsFactors = FALSE
      )
    }
  )
  
  # ----------------------------------------------------------
  # Clean observations
  # ----------------------------------------------------------
  
  CPrice_long_m$OBS_VALUE <- as.numeric(
    CPrice_long_m$OBS_VALUE
  )
  
  CPrice_long_m <- CPrice_long_m |>
    filter(
      !is.na(OBS_VALUE)
    ) |>
    mutate(
      OBS_VALUE = round(
        OBS_VALUE,
        2
      )
    )
  
  # ----------------------------------------------------------
  # Add SDMX fields
  # ----------------------------------------------------------
  
  CPrice_long_m <- CPrice_long_m |>
    mutate(
      DATAFLOW = "SPC:DF_COMMODITY_PRICES(1.0)",
      FREQ = "M",
      INDICATOR = "COMPRICE",
      UNIT_MULT = "",
      OBS_STATUS = "",
      DATA_SOURCE = "",
      OBS_COMMENT = ""
    ) |>
    select(
      DATAFLOW,
      FREQ,
      TIME_PERIOD,
      COMMODITY,
      INDICATOR,
      OBS_VALUE,
      UNIT_MEASURE,
      UNIT_MULT,
      OBS_STATUS,
      DATA_SOURCE,
      OBS_COMMENT
    )
  
  CPrice_long_m
}


# ============================================================
# UI
# ============================================================

ui <- fluidPage(
  
  # ==========================================================
  # Title
  # ==========================================================
  
  titlePanel(
    "World Bank Commodity Prices Data Processing Application"
  ),
  
  sidebarLayout(
    
    # ========================================================
    # Sidebar
    # ========================================================
    
    sidebarPanel(
      
      h4("1. Commodity Price Reference"),
      
      helpText(
        paste0(
          "Commodity reference file: ",
          "CPriceList.csv"
        )
      ),
      
      tags$small(
        paste0(
          "Location: ",
          commodity_list_file
        )
      ),
      
      hr(),
      
      h4("2. Download World Bank Data"),
      
      helpText(
        "The application downloads the latest annual and monthly commodity price workbooks directly from the World Bank."
      ),
      
      actionButton(
        inputId = "process",
        label = "Download & Process Data",
        icon = icon("play"),
        class = "btn-primary"
      ),
      
      hr(),
      
      h4("3. Download Final CSV"),
      
      downloadButton(
        outputId = "download_csv",
        label = "Download Final CSV",
        class = "btn-success"
      ),
      
      hr(),
      
      h4("4. Processing Status"),
      
      verbatimTextOutput(
        "status"
      )
    ),
    
    
    # ========================================================
    # Main panel
    # ========================================================
    
    mainPanel(
      
      tabsetPanel(
        
        # ====================================================
        # Summary
        # ====================================================
        
        tabPanel(
          title = "Summary",
          
          br(),
          
          fluidRow(
            
            column(
              width = 3,
              
              wellPanel(
                h4("Rows"),
                textOutput("n_rows")
              )
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Commodities"),
                textOutput("n_commodities")
              )
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Annual Observations"),
                textOutput("n_annual")
              )
            ),
            
            column(
              width = 3,
              
              wellPanel(
                h4("Monthly Observations"),
                textOutput("n_monthly")
              )
            )
          ),
          
          hr(),
          
          h4("Frequency / Indicator Summary"),
          
          DTOutput(
            "indicator_summary"
          ),
          
          hr(),
          
          h4("Commodity Summary"),
          
          DTOutput(
            "commodity_summary"
          )
        ),
        
        
        # ====================================================
        # Final Data
        # ====================================================
        
        tabPanel(
          title = "Final Data",
          
          br(),
          
          DTOutput(
            "final_data"
          )
        ),
        
        
        # ====================================================
        # Annual Data
        # ====================================================
        
        tabPanel(
          title = "Annual Data",
          
          br(),
          
          DTOutput(
            "annual_data"
          )
        ),
        
        
        # ====================================================
        # Monthly Data
        # ====================================================
        
        tabPanel(
          title = "Monthly Data",
          
          br(),
          
          DTOutput(
            "monthly_data"
          )
        )
      )
    )
  )
)


# ============================================================
# SERVER
# ============================================================

server <- function(input, output, session) {
  
  # ==========================================================
  # Reactive values
  # ==========================================================
  
  processed_data <- reactiveVal(NULL)
  
  annual_data <- reactiveVal(NULL)
  
  monthly_data <- reactiveVal(NULL)
  
  processing_status <- reactiveVal(
    "Waiting for processing..."
  )
  
  
  # ==========================================================
  # Process World Bank commodity data
  # ==========================================================
  
  observeEvent(
    input$process,
    {
      
      withProgress(
        
        message = "Processing World Bank commodity prices...",
        
        value = 0,
        
        {
          
          # ==================================================
          # Download annual data
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Downloading annual World Bank commodity prices..."
          )
          
          annual_raw <- tryCatch(
            
            {
              aPrices()
            },
            
            error = function(e) {
              
              showNotification(
                paste(
                  "Annual data download failed:",
                  e$message
                ),
                type = "error",
                duration = NULL
              )
              
              stop(
                e
              )
            }
          )
          
          
          # ==================================================
          # Process annual data
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Processing annual commodity prices..."
          )
          
          annual_processed <- process_annual(
            annual_raw,
            comPriceList
          )
          
          
          # ==================================================
          # Download monthly data
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Downloading monthly World Bank commodity prices..."
          )
          
          monthly_raw <- tryCatch(
            
            {
              mPrices()
            },
            
            error = function(e) {
              
              showNotification(
                paste(
                  "Monthly data download failed:",
                  e$message
                ),
                type = "error",
                duration = NULL
              )
              
              stop(
                e
              )
            }
          )
          
          
          # ==================================================
          # Process monthly data
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Processing monthly commodity prices..."
          )
          
          monthly_processed <- process_monthly(
            monthly_raw,
            comPriceList
          )
          
          
          # ==================================================
          # Combine datasets
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Combining annual and monthly data..."
          )
          
          DF_COMMODITIES <- bind_rows(
            annual_processed,
            monthly_processed
          ) |>
            mutate(
              OBS_VALUE = round(
                as.numeric(OBS_VALUE),
                2
              )
            )
          
          
          # ==================================================
          # Save reactive data
          # ==================================================
          
          annual_data(
            annual_processed
          )
          
          monthly_data(
            monthly_processed
          )
          
          processed_data(
            DF_COMMODITIES
          )
          
          
          # ==================================================
          # Save to OneDrive
          # ==================================================
          
          incProgress(
            0.15,
            detail = "Saving final CSV to OneDrive..."
          )
          
          oneDrivePath <- paste0(
            "C:/Users/",
            username,
            "/OneDrive - SPC/DotStat/REFDB/DF_COMMODITY_PRICES"
          )
          
          
          # --------------------------------------------------
          # Create timestamp
          # --------------------------------------------------
          
          folderName <- format(
            Sys.time(),
            "%Y%m%d_%H%M%S_WB_data_Update"
          )
          
          
          newFolder <- file.path(
            oneDrivePath,
            folderName
          )
          
          
          newFile <- file.path(
            newFolder,
            "DF_COMMODITY_PRICES.CSV"
          )
          
          
          # --------------------------------------------------
          # Create folder
          # --------------------------------------------------
          
          dir.create(
            newFolder,
            recursive = TRUE,
            showWarnings = FALSE
          )
          
          
          # --------------------------------------------------
          # Write CSV
          # --------------------------------------------------
          
          write.csv(
            DF_COMMODITIES,
            newFile,
            row.names = FALSE,
            na = ""
          )
          
          
          # ==================================================
          # Final status
          # ==================================================
          
          processing_status(
            
            paste0(
              "Processing completed successfully.\n\n",
              "Annual observations: ",
              format(
                nrow(annual_processed),
                big.mark = ","
              ),
              "\n",
              "Monthly observations: ",
              format(
                nrow(monthly_processed),
                big.mark = ","
              ),
              "\n",
              "Total observations: ",
              format(
                nrow(DF_COMMODITIES),
                big.mark = ","
              ),
              "\n\n",
              "OneDrive output:\n",
              newFile
            )
          )
          
          
          incProgress(
            0.10,
            detail = "Processing complete!"
          )
          
          
          # ==================================================
          # Notification
          # ==================================================
          
          showNotification(
            paste0(
              "Commodity price processing completed successfully.\n",
              "Rows: ",
              format(
                nrow(DF_COMMODITIES),
                big.mark = ","
              )
            ),
            type = "message",
            duration = 8
          )
        }
      )
    }
  )
  
  
  # ==========================================================
  # Summary: Number of rows
  # ==========================================================
  
  output$n_rows <- renderText({
    
    req(
      processed_data()
    )
    
    format(
      nrow(
        processed_data()
      ),
      big.mark = ","
    )
  })
  
  
  # ==========================================================
  # Summary: Number of commodities
  # ==========================================================
  
  output$n_commodities <- renderText({
    
    req(
      processed_data()
    )
    
    n_distinct(
      processed_data()$COMMODITY
    )
  })
  
  
  # ==========================================================
  # Summary: Annual observations
  # ==========================================================
  
  output$n_annual <- renderText({
    
    req(
      annual_data()
    )
    
    format(
      nrow(
        annual_data()
      ),
      big.mark = ","
    )
  })
  
  
  # ==========================================================
  # Summary: Monthly observations
  # ==========================================================
  
  output$n_monthly <- renderText({
    
    req(
      monthly_data()
    )
    
    format(
      nrow(
        monthly_data()
      ),
      big.mark = ","
    )
  })
  
  
  # ==========================================================
  # Indicator summary
  # ==========================================================
  
  output$indicator_summary <- renderDT({
    
    req(
      processed_data()
    )
    
    processed_data() |>
      count(
        FREQ,
        INDICATOR,
        name = "Number of Observations"
      )
    
  },
  
  options = list(
    pageLength = 10,
    scrollX = TRUE
  ))
  
  
  # ==========================================================
  # Commodity summary
  # ==========================================================
  
  output$commodity_summary <- renderDT({
    
    req(
      processed_data()
    )
    
    processed_data() |>
      count(
        COMMODITY,
        UNIT_MEASURE,
        name = "Number of Observations"
      ) |>
      arrange(
        COMMODITY
      )
    
  },
  
  options = list(
    pageLength = 15,
    scrollX = TRUE
  ))
  
  
  # ==========================================================
  # Final data
  # ==========================================================
  
  output$final_data <- renderDT({
    
    req(
      processed_data()
    )
    
    datatable(
      
      processed_data(),
      
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
  
  
  # ==========================================================
  # Annual data
  # ==========================================================
  
  output$annual_data <- renderDT({
    
    req(
      annual_data()
    )
    
    datatable(
      
      annual_data(),
      
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
  
  
  # ==========================================================
  # Monthly data
  # ==========================================================
  
  output$monthly_data <- renderDT({
    
    req(
      monthly_data()
    )
    
    datatable(
      
      monthly_data(),
      
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
  
  
  # ==========================================================
  # Status
  # ==========================================================
  
  output$status <- renderText({
    
    processing_status()
    
  })
  
  
  # ==========================================================
  # Download final CSV
  # ==========================================================
  
  output$download_csv <- downloadHandler(
    
    filename = function() {
      
      paste0(
        "DF_COMMODITY_PRICES_",
        format(
          Sys.time(),
          "%Y%m%d_%H%M%S"
        ),
        ".csv"
      )
    },
    
    content = function(file) {
      
      req(
        processed_data()
      )
      
      write.csv(
        processed_data(),
        file,
        row.names = FALSE,
        na = ""
      )
    }
  )
}


# ============================================================
# Run application
# ============================================================

shinyApp(
  ui = ui,
  server = server
)
