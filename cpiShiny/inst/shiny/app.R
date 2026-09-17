# ============================================================
# COMBINED CPI DATA PROCESSING SHINY APPLICATION
# ============================================================
#
# Supports:
#
#   FREQ = M  -> Monthly CPI input
#   FREQ = Q  -> Quarterly CPI input
#
# Monthly input produces:
#   - Monthly CPI
#   - Monthly Inflation
#   - Quarterly CPI
#   - Quarterly Inflation
#   - Annual CPI
#   - Annual Inflation
#
# Quarterly input produces:
#   - Quarterly CPI
#   - Quarterly Inflation
#   - Annual CPI
#   - Annual Inflation
#
# One final CSV file is produced.
#
# ============================================================


# ============================================================
# 1. LOAD REQUIRED LIBRARIES
# ============================================================

library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(readxl)
library(DT)


# ============================================================
# 2. STATISTICS OFFICES
# ============================================================

stats_office <- data.frame(
  
  GEO_PICT = c(
    "AS","CK","FJ","FM","GU","KI","MH","MP","NC","NR","NU",
    "PF","PG","PN","PW","SB","TK","TO","TV","VU","WF","WS"
  ),
  
  office = c(
    
    "Data and Statistics American Samoa Department of Commerce",
    
    "Cook Islands Statistics Office",
    
    "Fiji Bureau of Statistics",
    
    "FSM Statistics",
    
    "The Bureau of Statistics and Plans - Guam",
    
    "Kiribati national Statistics Office",
    
    "Marshall Islands Economic Policy, Planning and Statistics Office (EPPSO)",
    
    "CNMI Department of Commerce",
    
    "Institut de la Statistique et des Etudes Economiques",
    
    "Nauru Bureau of Statistics",
    
    "Niue Statistics Office",
    
    "Institut de la statistique de la Polynésie française",
    
    "PNG National Statistics Office",
    
    "Pitcairn Statistics office",
    
    "Palau Statistics Office",
    
    "Solomon Islands National Statistics Office",
    
    "Tokelau Statistics Office",
    
    "Tonga Statistics Department",
    
    "Tuvalu Statistics Office",
    
    "Vanuatu Bureau of Statistics Office",
    
    "Wallis and Futuna Statistics Office",
    
    "Samoa Bureau of Statistics"
    
  ),
  
  stringsAsFactors = FALSE
)


# ============================================================
# 3. INFLATION CALCULATION FUNCTION
# ============================================================

calc_inflation <- function(df, comment, frequency = NULL) {
  
  result <- df |>
    
    arrange(
      GEO_PICT,
      COMMODITY,
      TIME_PERIOD
    ) |>
    
    group_by(
      GEO_PICT,
      COMMODITY
    ) |>
    
    mutate(
      
      OBS_VALUE =
        (
          OBS_VALUE /
            lag(OBS_VALUE)
          - 1
        ) * 100
      
    ) |>
    
    ungroup() |>
    
    filter(
      !is.na(OBS_VALUE)
    ) |>
    
    mutate(
      
      INDICATOR = "INF",
      
      UNIT_MEASURE = "PERCENT",
      
      OBS_STATUS = "E",
      
      OBS_COMMENT = comment,
      
      OBS_VALUE = round(
        OBS_VALUE,
        1
      )
      
    )
  
  if (!is.null(frequency)) {
    
    result <- result |>
      mutate(
        FREQ = frequency
      )
    
  }
  
  result
}


# ============================================================
# 4. QUARTERLY INFLATION FUNCTION
# ============================================================

calc_quarterly_inflation <- function(
    df,
    comment
) {
  
  df |>
    
    arrange(
      GEO_PICT,
      COMMODITY,
      TIME_PERIOD
    ) |>
    
    group_by(
      GEO_PICT,
      COMMODITY
    ) |>
    
    mutate(
      
      OBS_VALUE =
        (
          OBS_VALUE /
            lag(OBS_VALUE)
          - 1
        ) * 100
      
    ) |>
    
    ungroup() |>
    
    filter(
      !is.na(OBS_VALUE)
    ) |>
    
    mutate(
      
      FREQ = "Q",
      
      INDICATOR = "INF",
      
      UNIT_MEASURE = "PERCENT",
      
      OBS_STATUS = "E",
      
      OBS_COMMENT = comment,
      
      OBS_VALUE = round(
        OBS_VALUE,
        1
      )
      
    )
}


# ============================================================
# 5. USER INTERFACE
# ============================================================

ui <- fluidPage(
  
  titlePanel(
    "CPI Data Processing Application"
  ),
  
  sidebarLayout(
    
    # ========================================================
    # SIDEBAR
    # ========================================================
    
    sidebarPanel(
      
      h4(
        "1. Upload CPI Data"
      ),
      
      fileInput(
        
        inputId = "cpi_file",
        
        label = "Select CPI Excel file:",
        
        accept = c(
          ".xlsx",
          ".xls"
        )
        
      ),
      
      helpText(
        "The Excel file must contain a worksheet named 'cpi_data'."
      ),
      
      helpText(
        "The FREQ column must contain either M (monthly) or Q (quarterly)."
      ),
      
      hr(),
      
      h4(
        "Input Information"
      ),
      
      textOutput(
        "input_frequency"
      ),
      
      textOutput(
        "input_countries"
      ),
      
      textOutput(
        "input_period"
      ),
      
      hr(),
      
      h4(
        "2. Process Data"
      ),
      
      actionButton(
        
        inputId = "process",
        
        label = "Process CPI Data",
        
        icon = icon(
          "play"
        ),
        
        class = "btn-primary"
        
      ),
      
      hr(),
      
      h4(
        "3. Download"
      ),
      
      downloadButton(
        
        outputId = "download_csv",
        
        label = "Download Final CSV",
        
        class = "btn-success"
        
      ),
      
      hr(),
      
      h4(
        "Processing Status"
      ),
      
      verbatimTextOutput(
        "status"
      )
      
    ),
    
    
    # ========================================================
    # MAIN PANEL
    # ========================================================
    
    mainPanel(
      
      tabsetPanel(
        
        # ====================================================
        # SUMMARY
        # ====================================================
        
        tabPanel(
          
          title = "Summary",
          
          br(),
          
          fluidRow(
            
            column(
              
              width = 3,
              
              wellPanel(
                
                h4(
                  "Rows"
                ),
                
                textOutput(
                  "n_rows"
                )
                
              )
              
            ),
            
            column(
              
              width = 3,
              
              wellPanel(
                
                h4(
                  "Countries"
                ),
                
                textOutput(
                  "n_countries"
                )
                
              )
              
            ),
            
            column(
              
              width = 3,
              
              wellPanel(
                
                h4(
                  "Commodities"
                ),
                
                textOutput(
                  "n_commodities"
                )
                
              )
              
            ),
            
            column(
              
              width = 3,
              
              wellPanel(
                
                h4(
                  "Indicators"
                ),
                
                textOutput(
                  "n_indicators"
                )
                
              )
              
            )
            
          ),
          
          hr(),
          
          h4(
            "Indicator / Frequency Summary"
          ),
          
          DTOutput(
            "indicator_summary"
          )
          
        ),
        
        
        # ====================================================
        # FINAL DATA
        # ====================================================
        
        tabPanel(
          
          title = "Final Data",
          
          br(),
          
          DTOutput(
            "final_data"
          )
          
        ),
        
        
        # ====================================================
        # MONTHLY CPI
        # ====================================================
        
        tabPanel(
          
          title = "Monthly CPI",
          
          br(),
          
          DTOutput(
            "monthly_cpi_data"
          )
          
        ),
        
        
        # ====================================================
        # MONTHLY INFLATION
        # ====================================================
        
        tabPanel(
          
          title = "Monthly Inflation",
          
          br(),
          
          DTOutput(
            "monthly_inflation_data"
          )
          
        ),
        
        
        # ====================================================
        # QUARTERLY CPI
        # ====================================================
        
        tabPanel(
          
          title = "Quarterly CPI",
          
          br(),
          
          DTOutput(
            "quarterly_data"
          )
          
        ),
        
        
        # ====================================================
        # QUARTERLY INFLATION
        # ====================================================
        
        tabPanel(
          
          title = "Quarterly Inflation",
          
          br(),
          
          DTOutput(
            "quarterly_inflation_data"
          )
          
        ),
        
        
        # ====================================================
        # ANNUAL CPI
        # ====================================================
        
        tabPanel(
          
          title = "Annual CPI",
          
          br(),
          
          DTOutput(
            "annual_data"
          )
          
        ),
        
        
        # ====================================================
        # ANNUAL INFLATION
        # ====================================================
        
        tabPanel(
          
          title = "Annual Inflation",
          
          br(),
          
          DTOutput(
            "annual_inflation_data"
          )
          
        )
        
      )
      
    )
    
  )
  
)


# ============================================================
# 6. SERVER
# ============================================================

server <- function(
    input,
    output,
    session
) {
  
  
  # ==========================================================
  # REACTIVE VALUES
  # ==========================================================
  
  processed_data <- reactiveVal(NULL)
  
  monthly_cpi_data <- reactiveVal(NULL)
  
  monthly_inflation_data <- reactiveVal(NULL)
  
  quarterly_data <- reactiveVal(NULL)
  
  quarterly_inflation_data <- reactiveVal(NULL)
  
  annual_data <- reactiveVal(NULL)
  
  annual_inflation_data <- reactiveVal(NULL)
  
  input_frequency_value <- reactiveVal(NULL)
  
  input_data_value <- reactiveVal(NULL)
  
  
  # ==========================================================
  # INPUT FREQUENCY
  # ==========================================================
  
  output$input_frequency <- renderText({
    
    freq <- input_frequency_value()
    
    if (is.null(freq)) {
      
      return(
        "Frequency: Not detected"
      )
      
    }
    
    if (freq == "M") {
      
      "Frequency: M (Monthly)"
      
    } else if (freq == "Q") {
      
      "Frequency: Q (Quarterly)"
      
    } else {
      
      paste(
        "Frequency:",
        freq
      )
      
    }
    
  })
  
  
  # ==========================================================
  # INPUT COUNTRIES
  # ==========================================================
  
  output$input_countries <- renderText({
    
    df <- input_data_value()
    
    if (is.null(df)) {
      
      return(
        "Countries: -"
      )
      
    }
    
    paste(
      "Countries:",
      n_distinct(
        df$GEO_PICT
      )
    )
    
  })
  
  
  # ==========================================================
  # INPUT PERIOD
  # ==========================================================
  
  output$input_period <- renderText({
    
    df <- input_data_value()
    
    if (is.null(df)) {
      
      return(
        "Period: -"
      )
      
    }
    
    paste(
      "Period:",
      min(
        df$TIME_PERIOD,
        na.rm = TRUE
      ),
      "to",
      max(
        df$TIME_PERIOD,
        na.rm = TRUE
      )
    )
    
  })
  
  
  # ==========================================================
  # PROCESS DATA
  # ==========================================================
  
  observeEvent(
    
    input$process,
    
    {
      
      req(
        input$cpi_file
      )
      
      
      # ========================================================
      # IMPORTANT:
      # tryCatch() MUST contain the processing code.
      #
      # Do NOT put error = function(e) directly inside
      # observeEvent().
      # ========================================================
      
      tryCatch({
        
        withProgress(
          
          message = "Processing CPI data...",
          
          value = 0,
          
          {
            
            
            # ==================================================
            # READ EXCEL FILE
            # ==================================================
            
            incProgress(
              
              0.10,
              
              detail = "Reading Excel file..."
              
            )
            
            
            raw_data <- read_excel(
              
              input$cpi_file$datapath,
              
              sheet = "cpi_data"
              
            )
            
            
            # ==================================================
            # STANDARDISE COLUMN NAMES
            # ==================================================
            
            names(raw_data) <- toupper(
              names(raw_data)
            )
            
            
            # ==================================================
            # CHECK BASIC COLUMNS
            # ==================================================
            
            required_input_columns <- c(
              
              "DATAFLOW",
              "FREQ",
              "GEO_PICT",
              "TIME_PERIOD",
              "UNIT_MEASURE",
              "UNIT_MULT",
              "OBS_STATUS",
              "BASE_PER",
              "OBS_COMMENT"
              
            )
            
            
            missing_input_columns <- setdiff(
              
              required_input_columns,
              
              names(raw_data)
              
            )
            
            
            if (
              length(
                missing_input_columns
              ) > 0
            ) {
              
              stop(
                
                paste(
                  
                  "The following required columns are missing from the Excel file:",
                  
                  paste(
                    
                    missing_input_columns,
                    
                    collapse = ", "
                    
                  )
                  
                )
                
              )
              
            }
            
            
            # ==================================================
            # DETECT FREQUENCY
            # ==================================================
            
            frequencies <- unique(
              
              na.omit(
                
                as.character(
                  raw_data$FREQ
                )
                
              )
              
            )
            
            
            if (
              length(frequencies) != 1
            ) {
              
              stop(
                
                paste(
                  
                  "The Excel file must contain exactly one FREQ value.",
                  
                  "Detected:",
                  
                  paste(
                    
                    frequencies,
                    
                    collapse = ", "
                    
                  )
                  
                )
                
              )
              
            }
            
            
            freq <- frequencies[1]
            
            
            if (
              !freq %in% c("M", "Q")
            ) {
              
              stop(
                
                paste(
                  
                  "Unsupported FREQ:",
                  
                  freq,
                  
                  ". Only M and Q are supported."
                  
                )
                
              )
              
            }
            
            
            input_frequency_value(
              freq
            )
            
            
            # ==================================================
            # PIVOT WIDE CPI DATA TO LONG FORMAT
            # ==================================================
            #
            # THIS IS THE IMPORTANT FIX.
            #
            # The Excel input does NOT initially contain
            # OBS_VALUE.
            #
            # The commodity columns contain the CPI values.
            #
            # pivot_longer() creates:
            #
            #   COMMODITY
            #   OBS_VALUE
            #
            # This is what the original applications do.
            # ==================================================
            
            incProgress(
              
              0.10,
              
              detail = "Converting CPI data to long format..."
              
            )
            
            
            id_columns <- c(
              
              "DATAFLOW",
              "FREQ",
              "GEO_PICT",
              "INDICATOR",
              "TIME_PERIOD",
              "UNIT_MEASURE",
              "UNIT_MULT",
              "OBS_STATUS",
              "BASE_PER",
              "OBS_COMMENT"
              
            )
            
            
            id_columns <- intersect(
              
              id_columns,
              
              names(raw_data)
              
            )
            
            
            cpi_data <- raw_data |>
              
              pivot_longer(
                
                cols = -all_of(id_columns),
                
                names_to = "COMMODITY",
                
                values_to = "OBS_VALUE"
                
              )
            
            
            # ==================================================
            # CHECK LONG-FORMAT DATA
            # ==================================================
            
            required_long_columns <- c(
              
              "DATAFLOW",
              "FREQ",
              "GEO_PICT",
              "TIME_PERIOD",
              "COMMODITY",
              "OBS_VALUE",
              "UNIT_MEASURE",
              "UNIT_MULT",
              "OBS_STATUS",
              "BASE_PER",
              "OBS_COMMENT"
              
            )
            
            
            missing_long_columns <- setdiff(
              
              required_long_columns,
              
              names(cpi_data)
              
            )
            
            
            if (
              length(
                missing_long_columns
              ) > 0
            ) {
              
              stop(
                
                paste(
                  
                  "The following required columns could not be created:",
                  
                  paste(
                    
                    missing_long_columns,
                    
                    collapse = ", "
                    
                  )
                  
                )
                
              )
              
            }
            
            
            # ==================================================
            # SAVE INPUT DATA
            # ==================================================
            
            input_data_value(
              cpi_data
            )
            
            
            # ==================================================
            # CONVERT OBS_VALUE
            # ==================================================
            
            cpi_data <- cpi_data |>
              
              mutate(
                
                OBS_VALUE = as.numeric(
                  OBS_VALUE
                ),
                
                TIME_PERIOD = as.character(
                  TIME_PERIOD
                ),
                
                GEO_PICT = as.character(
                  GEO_PICT
                ),
                
                COMMODITY = as.character(
                  COMMODITY
                )
                
              ) |>
              
              filter(
                !is.na(OBS_VALUE)
              )
            
            
            # ==================================================
            # MONTHLY INPUT
            # ==================================================
            
            if (
              freq == "M"
            ) {
              
              
              # =================================================
              # PREPARE MONTHLY CPI
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Preparing monthly CPI..."
                
              )
              
              
              cpi <- cpi_data |>
                
                mutate(
                  
                  FREQ = "M",
                  
                  INDICATOR = "IDX",
                  
                  OBS_STATUS = "E",
                  
                  OBS_COMMENT =
                    "Monthly consumer price indexes sourced from "
                  
                ) |>
                
                mutate(
                  
                  Date = as.Date(
                    
                    paste0(
                      TIME_PERIOD,
                      "-01"
                    )
                    
                  ),
                  
                  Year = year(Date),
                  
                  Quarter = quarter(Date)
                  
                )
              
              
              # =================================================
              # VALIDATE MONTHLY DATES
              # =================================================
              
              invalid_dates <- cpi |>
                
                filter(
                  is.na(Date)
                )
              
              
              if (
                nrow(invalid_dates) > 0
              ) {
                
                stop(
                  
                  paste(
                    
                    "Invalid monthly TIME_PERIOD values detected.",
                    
                    "Expected format is YYYY-MM."
                    
                  )
                  
                )
                
              }
              
              
              # =================================================
              # MONTHLY CPI OUTPUT
              # =================================================
              
              monthly_cpi <- cpi |>
                
                select(
                  
                  DATAFLOW,
                  FREQ,
                  GEO_PICT,
                  INDICATOR,
                  COMMODITY,
                  TIME_PERIOD,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  BASE_PER,
                  OBS_COMMENT
                  
                ) |>
                
                mutate(
                  
                  OBS_VALUE = round(
                    OBS_VALUE,
                    1
                  )
                  
                )
              
              
              # =================================================
              # MONTHLY INFLATION
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Calculating monthly inflation..."
                
              )
              
              
              monthly_inflation <- calc_inflation(
                
                monthly_cpi,
                
                "Monthly inflation calculated from average monthly indexes sourced from "
                
              )
              
              
              # =================================================
              # QUARTERLY CPI
              # =================================================
              
              incProgress(
                
                0.15,
                
                detail = "Calculating quarterly CPI..."
                
              )
              
              
              quarterly_cpi <- cpi |>
                
                group_by(
                  
                  DATAFLOW,
                  GEO_PICT,
                  COMMODITY,
                  BASE_PER,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  Year,
                  Quarter
                  
                ) |>
                
                summarise(
                  
                  Months =
                    sum(
                      !is.na(
                        OBS_VALUE
                      )
                    ),
                  
                  OBS_VALUE =
                    ifelse(
                      
                      Months == 3,
                      
                      mean(
                        OBS_VALUE,
                        na.rm = TRUE
                      ),
                      
                      NA_real_
                      
                    ),
                  
                  .groups = "drop"
                  
                ) |>
                
                filter(
                  
                  Months == 3
                  
                ) |>
                
                mutate(
                  
                  FREQ = "Q",
                  
                  INDICATOR = "IDX",
                  
                  OBS_STATUS = "E",
                  
                  OBS_COMMENT =
                    "Quarterly average indexes calculated from average monthly indexes sourced from ",
                  
                  TIME_PERIOD =
                    paste0(
                      Year,
                      "-Q",
                      Quarter
                    )
                  
                ) |>
                
                select(
                  
                  DATAFLOW,
                  FREQ,
                  GEO_PICT,
                  INDICATOR,
                  COMMODITY,
                  TIME_PERIOD,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  BASE_PER,
                  OBS_COMMENT
                  
                ) |>
                
                mutate(
                  
                  OBS_VALUE =
                    round(
                      OBS_VALUE,
                      1
                    )
                  
                )
              
              
              # =================================================
              # QUARTERLY INFLATION
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Calculating quarterly inflation..."
                
              )
              
              
              quarterly_inflation <- calc_inflation(
                
                quarterly_cpi,
                
                "Quarterly average inflation calculated from average monthly indexes sourced from "
                
              )
              
              
              # =================================================
              # ANNUAL CPI
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Calculating annual CPI..."
                
              )
              
              
              annual_cpi <- quarterly_cpi |>
                
                mutate(
                  
                  Year =
                    substr(
                      TIME_PERIOD,
                      1,
                      4
                    )
                  
                ) |>
                
                group_by(
                  
                  DATAFLOW,
                  GEO_PICT,
                  COMMODITY,
                  BASE_PER,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  Year
                  
                ) |>
                
                summarise(
                  
                  Quarters =
                    n_distinct(
                      TIME_PERIOD
                    ),
                  
                  OBS_VALUE =
                    ifelse(
                      
                      Quarters == 4,
                      
                      mean(
                        OBS_VALUE,
                        na.rm = TRUE
                      ),
                      
                      NA_real_
                      
                    ),
                  
                  .groups = "drop"
                  
                ) |>
                
                filter(
                  
                  Quarters == 4
                  
                )
              
              
              # =================================================
              # ANNUAL CPI OUTPUT
              # =================================================
              
              incProgress(
                
                0.05,
                
                detail = "Preparing annual CPI..."
                
              )
              
              
              annual_cpi_out <- annual_cpi |>
                
                mutate(
                  
                  FREQ = "A",
                  
                  INDICATOR = "IDX",
                  
                  OBS_STATUS = "E",
                  
                  OBS_COMMENT =
                    "Annual average indexes calculated from average monthly indexes sourced from ",
                  
                  TIME_PERIOD =
                    as.character(
                      Year
                    )
                  
                ) |>
                
                select(
                  
                  DATAFLOW,
                  FREQ,
                  GEO_PICT,
                  INDICATOR,
                  COMMODITY,
                  TIME_PERIOD,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  BASE_PER,
                  OBS_COMMENT
                  
                ) |>
                
                mutate(
                  
                  OBS_VALUE =
                    round(
                      OBS_VALUE,
                      1
                    )
                  
                )
              
              
              # =================================================
              # ANNUAL INFLATION
              # =================================================
              
              incProgress(
                
                0.05,
                
                detail = "Calculating annual inflation..."
                
              )
              
              
              annual_inflation_out <- calc_inflation(
                
                annual_cpi_out,
                
                "Annual average inflation calculated from quarterly average indexes sourced from ",
                
                frequency = "A"
                
              ) |>
                
                filter(
                  COMMODITY == "_T"
                )
              
              
              # =================================================
              # COMBINE MONTHLY INPUT RESULTS
              # =================================================
              
              incProgress(
                
                0.05,
                
                detail = "Combining monthly CPI results..."
                
              )
              
              
              combined <- bind_rows(
                
                monthly_cpi,
                
                monthly_inflation,
                
                quarterly_cpi,
                
                quarterly_inflation,
                
                annual_cpi_out,
                
                annual_inflation_out
                
              )
              
              
              # =================================================
              # SAVE TABLE DATA
              # =================================================
              
              monthly_cpi_data(
                monthly_cpi
              )
              
              monthly_inflation_data(
                monthly_inflation
              )
              
              quarterly_data(
                quarterly_cpi
              )
              
              quarterly_inflation_data(
                quarterly_inflation
              )
              
              annual_data(
                annual_cpi_out
              )
              
              annual_inflation_data(
                annual_inflation_out
              )
              
            }
            
            
            # ==================================================
            # QUARTERLY INPUT
            # ==================================================
            
            else if (
              freq == "Q"
            ) {
              
              
              # =================================================
              # PREPARE QUARTERLY CPI
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Preparing quarterly CPI..."
                
              )
              
              
              cpi <- cpi_data |>
                
                mutate(
                  
                  FREQ = "Q",
                  
                  INDICATOR = "IDX",
                  
                  OBS_STATUS = "E",
                  
                  OBS_COMMENT =
                    "Quarterly consumer price indexes sourced from "
                  
                ) |>
                
                mutate(
                  
                  Year =
                    as.numeric(
                      substr(
                        TIME_PERIOD,
                        1,
                        4
                      )
                    ),
                  
                  Quarter =
                    as.numeric(
                      substr(
                        TIME_PERIOD,
                        7,
                        7
                      )
                    )
                  
                )
              
              
              # =================================================
              # VALIDATE QUARTERLY TIME PERIOD
              # =================================================
              
              invalid_periods <- cpi |>
                
                filter(
                  
                  is.na(Year) |
                    
                    is.na(Quarter) |
                    
                    !Quarter %in% c(
                      1,
                      2,
                      3,
                      4
                    )
                  
                )
              
              
              if (
                nrow(invalid_periods) > 0
              ) {
                
                stop(
                  
                  paste(
                    
                    "Invalid TIME_PERIOD values detected.",
                    
                    "Expected format is YYYY-Q1 to YYYY-Q4."
                    
                  )
                  
                )
                
              }
              
              
              # =================================================
              # QUARTERLY CPI OUTPUT
              # =================================================
              
              quarterly_cpi <- cpi |>
                
                select(
                  
                  DATAFLOW,
                  FREQ,
                  GEO_PICT,
                  INDICATOR,
                  COMMODITY,
                  TIME_PERIOD,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  BASE_PER,
                  OBS_COMMENT
                  
                ) |>
                
                mutate(
                  
                  OBS_VALUE =
                    round(
                      OBS_VALUE,
                      1
                    )
                  
                )
              
              
              # =================================================
              # QUARTERLY INFLATION
              # =================================================
              
              incProgress(
                
                0.15,
                
                detail = "Calculating quarterly inflation..."
                
              )
              
              
              quarterly_inflation <-
                
                calc_quarterly_inflation(
                  
                  quarterly_cpi,
                  
                  "Quarterly inflation calculated from quarterly indexes sourced from "
                  
                )
              
              
              # =================================================
              # ANNUAL CPI
              # =================================================
              
              incProgress(
                
                0.15,
                
                detail = "Calculating annual CPI..."
                
              )
              
              
              annual_cpi <- cpi |>
                
                group_by(
                  
                  DATAFLOW,
                  GEO_PICT,
                  COMMODITY,
                  BASE_PER,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  Year
                  
                ) |>
                
                summarise(
                  
                  Quarters =
                    n_distinct(
                      Quarter
                    ),
                  
                  OBS_VALUE =
                    ifelse(
                      
                      Quarters == 4,
                      
                      mean(
                        OBS_VALUE,
                        na.rm = TRUE
                      ),
                      
                      NA_real_
                      
                    ),
                  
                  .groups = "drop"
                  
                ) |>
                
                filter(
                  
                  Quarters == 4
                  
                )
              
              
              # =================================================
              # ANNUAL CPI OUTPUT
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Preparing annual CPI..."
                
              )
              
              
              annual_cpi_out <- annual_cpi |>
                
                mutate(
                  
                  FREQ = "A",
                  
                  INDICATOR = "IDX",
                  
                  OBS_STATUS = "E",
                  
                  OBS_COMMENT =
                    "Annual average indexes calculated from quarterly indexes sourced from ",
                  
                  TIME_PERIOD =
                    as.character(
                      Year
                    )
                  
                ) |>
                
                select(
                  
                  DATAFLOW,
                  FREQ,
                  GEO_PICT,
                  INDICATOR,
                  COMMODITY,
                  TIME_PERIOD,
                  OBS_VALUE,
                  UNIT_MEASURE,
                  UNIT_MULT,
                  OBS_STATUS,
                  BASE_PER,
                  OBS_COMMENT
                  
                ) |>
                
                mutate(
                  
                  OBS_VALUE =
                    round(
                      OBS_VALUE,
                      1
                    )
                  
                )
              
              
              # =================================================
              # ANNUAL INFLATION
              # =================================================
              
              incProgress(
                
                0.10,
                
                detail = "Calculating annual inflation..."
                
              )
              
              
              annual_inflation_out <- calc_inflation(
                
                annual_cpi_out,
                
                "Annual inflation calculated from annual average quarterly indexes sourced from ",
                
                frequency = "A"
                
              ) |>
                
                filter(
                  COMMODITY == "_T"
                )
              
              
              # =================================================
              # COMBINE QUARTERLY INPUT RESULTS
              # =================================================
              
              incProgress(
                
                0.05,
                
                detail = "Combining quarterly CPI results..."
                
              )
              
              
              combined <- bind_rows(
                
                quarterly_cpi,
                
                quarterly_inflation,
                
                annual_cpi_out,
                
                annual_inflation_out
                
              )
              
              
              # =================================================
              # SAVE TABLE DATA
              # =================================================
              
              quarterly_data(
                quarterly_cpi
              )
              
              quarterly_inflation_data(
                quarterly_inflation
              )
              
              annual_data(
                annual_cpi_out
              )
              
              annual_inflation_data(
                annual_inflation_out
              )
              
            }
            
            
            # ==================================================
            # ADD STATISTICS OFFICE
            # ==================================================
            
            incProgress(
              
              0.05,
              
              detail = "Adding statistics office names..."
              
            )
            
            
            combined <- combined |>
              
              left_join(
                
                stats_office,
                
                by = "GEO_PICT"
                
              ) |>
              
              filter(
                
                !is.na(
                  OBS_VALUE
                )
                
              ) |>
              
              mutate(
                
                OBS_VALUE =
                  round(
                    as.numeric(
                      OBS_VALUE
                    ),
                    1
                  ),
                
                OBS_COMMENT =
                  ifelse(
                    
                    !is.na(OBS_COMMENT) &
                      OBS_COMMENT != "",
                    
                    paste0(
                      
                      OBS_COMMENT,
                      
                      " ",
                      
                      ifelse(
                        
                        is.na(office),
                        
                        "",
                        
                        office
                        
                      )
                      
                    ),
                    
                    ifelse(
                      
                      is.na(office),
                      
                      "",
                      
                      office
                      
                    )
                    
                  )
                
              ) |>
              
              select(
                
                -office
                
              )
            
            
            # ==================================================
            # FINAL COLUMN ORDER
            # ==================================================
            
            final_columns <- c(
              
              "DATAFLOW",
              "FREQ",
              "GEO_PICT",
              "INDICATOR",
              "COMMODITY",
              "TIME_PERIOD",
              "OBS_VALUE",
              "UNIT_MEASURE",
              "UNIT_MULT",
              "OBS_STATUS",
              "BASE_PER",
              "OBS_COMMENT"
              
            )
            
            
            combined <- combined |>
              
              select(
                all_of(final_columns)
              )
            
            
            # ==================================================
            # SAVE FINAL DATA
            # ==================================================
            
            processed_data(
              combined
            )
            
            
            # ==================================================
            # COMPLETE
            # ==================================================
            
            incProgress(
              
              0.05,
              
              detail = "Processing complete!"
              
            )
            
          }
          
        )
        
        
        # ========================================================
        # SUCCESS MESSAGE
        # ========================================================
        
        output$status <- renderText({
          
          paste(
            
            "Processing completed successfully.",
            
            "\n",
            
            "Input frequency:",
            freq,
            
            "\n",
            
            "Output observations:",
            format(
              nrow(
                processed_data()
              ),
              big.mark = ","
            ),
            
            "\n",
            
            "The final dataset is ready for download."
            
          )
          
        })
        
        
        showNotification(
          
          paste(
            
            "Processing completed successfully.",
            
            nrow(
              processed_data()
            ),
            
            "observations produced."
            
          ),
          
          type = "message",
          
          duration = 5
          
        )
        
      },
      
      # ========================================================
      # ERROR HANDLER
      # ========================================================
      #
      # This is deliberately INSIDE tryCatch().
      # ========================================================
      
      error = function(e) {
        
        output$status <- renderText({
          
          paste(
            
            "ERROR:",
            
            e$message
            
          )
          
        })
        
        
        showNotification(
          
          paste(
            
            "ERROR:",
            
            e$message
            
          ),
          
          type = "error",
          
          duration = NULL
          
        )
        
      })
      
    }
    
  )
  
  
  # ==========================================================
  # SUMMARY - ROWS
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
  # SUMMARY - COUNTRIES
  # ==========================================================
  
  output$n_countries <- renderText({
    
    req(
      processed_data()
    )
    
    n_distinct(
      processed_data()$GEO_PICT
    )
    
  })
  
  
  # ==========================================================
  # SUMMARY - COMMODITIES
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
  # SUMMARY - INDICATORS
  # ==========================================================
  
  output$n_indicators <- renderText({
    
    req(
      processed_data()
    )
    
    n_distinct(
      processed_data()$INDICATOR
    )
    
  })
  
  
  # ==========================================================
  # INDICATOR SUMMARY
  # ==========================================================
  
  output$indicator_summary <- renderDT({
    
    req(
      processed_data()
    )
    
    
    processed_data() |>
      
      count(
        
        FREQ,
        
        INDICATOR,
        
        name =
          "Number of Observations"
        
      )
    
  },
  
  options = list(
    
    pageLength = 10,
    
    scrollX = TRUE
    
  ))
  
  
  # ==========================================================
  # FINAL DATA
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
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # MONTHLY CPI
  # ==========================================================
  
  output$monthly_cpi_data <- renderDT({
    
    req(
      monthly_cpi_data()
    )
    
    
    datatable(
      
      monthly_cpi_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # MONTHLY INFLATION
  # ==========================================================
  
  output$monthly_inflation_data <- renderDT({
    
    req(
      monthly_inflation_data()
    )
    
    
    datatable(
      
      monthly_inflation_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # QUARTERLY CPI
  # ==========================================================
  
  output$quarterly_data <- renderDT({
    
    req(
      quarterly_data()
    )
    
    
    datatable(
      
      quarterly_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # QUARTERLY INFLATION
  # ==========================================================
  
  output$quarterly_inflation_data <- renderDT({
    
    req(
      quarterly_inflation_data()
    )
    
    
    datatable(
      
      quarterly_inflation_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # ANNUAL CPI
  # ==========================================================
  
  output$annual_data <- renderDT({
    
    req(
      annual_data()
    )
    
    
    datatable(
      
      annual_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # ANNUAL INFLATION
  # ==========================================================
  
  output$annual_inflation_data <- renderDT({
    
    req(
      annual_inflation_data()
    )
    
    
    datatable(
      
      annual_inflation_data(),
      
      filter = "top",
      
      options = list(
        
        pageLength = 25,
        
        scrollX = TRUE
        
      ),
      
      rownames = FALSE
      
    )
    
  })
  
  
  # ==========================================================
  # STATUS
  # ==========================================================
  
  output$status <- renderText({
    
    if (
      is.null(
        processed_data()
      )
    ) {
      
      "Waiting for CPI Excel file..."
      
    } else {
      
      paste(
        
        "Processing completed successfully.",
        
        "\n",
        
        "The final CPI dataset is ready for download."
        
      )
      
    }
    
  })
  
  
  # ==========================================================
  # DOWNLOAD FINAL CSV
  # ==========================================================
  
  output$download_csv <- downloadHandler(
    
    filename = function() {
      
      paste0(
        
        "DF_CPI-data_",
        
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
# 7. RUN APPLICATION
# ============================================================

shinyApp(
  
  ui = ui,
  
  server = server
  
)