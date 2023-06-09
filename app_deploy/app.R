library(shiny)
library(shinyjs)
library(shinyalert)
library(shinydashboard)
library(shinydashboardPlus)
library(htmltools)
library(htmlwidgets)
library(dplyr)
library(DT)
library(readr)
library(purrr)
library(reshape2)
library(tidyr)
library(ggplot2)
library(patchwork)
library(edgeR)
library(FBN)

#options(repos = append(BiocManager::repositories(), getOption("repos")))

shinyApp(
  ui = shinydashboardPlus::dashboardPage(
    options = list(sidebarExpandOnHover = TRUE),
    header = dashboardHeader(
      title = tags$span(
        class = "logo",
        tags$a(href = "#", "ChromoCorrect")
      ),
      tags$li(class = "dropdown",
              tags$a(href = "#", class = "dropdown-toggle", `data-toggle` = "dropdown",
                     icon("question-circle"), " Help"),
              tags$ul(class = "dropdown-menu",
                      tags$li(tags$a(href = "#", tabName = "Help", "Help")))
      )
    ),
    sidebar = dashboardSidebar(
      width = 300, minified = FALSE, collapsed = FALSE,
      conditionalPanel(
        condition = "input.tabs != 'Help'",
        h4("Upload files here"),
        uiOutput("mytab1"),
        uiOutput("mytab1.1"),
        uiOutput("mytab2"),
        uiOutput("mytab2.1")
      )
    ),
    body = dashboardBody(
      tags$head(tags$script('
                            var dimension = [0, 0];
                            $(document).on("shiny:connected", function(e) {
                                dimension[0] = window.innerWidth-300;
                                dimension[1] = window.innerHeight-300;
                                Shiny.onInputChange("dimension", dimension);
                            });
                            $(window).resize(function(e) {
                                dimension[0] = window.innerWidth-300;
                                dimension[1] = window.innerHeight-300;
                                setTimeout(function() {
                                  Shiny.onInputChange("dimension", dimension)
                                }, 500);
                            });
                        ')),
      h3('Detecting and correcting chromosomal location bias'),
      tabsetPanel(
        id = "tabs",
        tabPanel("Detecting",
                 br(),
                 textOutput("dimension_display"),
                 h4("Upload your log fold change output files to determine whether chromosomal location bias is affecting your data"),
                 p("If the overall trend of your fold changes does not match the red line, your data needs normalising."),
                 box(
                   title = "Locus by fold change scatterplot",
                   status = "primary",
                   width = 8, height = 6,
                   imageOutput("detec_fc", height = "100%", width = "100%")
                 ),
                 box(
                   width = 4,
                   title = "Decision",
                   status = "warning",
                   h4(htmlOutput(outputId = "detec_text"))
                 )
        ),
        tabPanel("Correcting",
                 br(),
                 h4("Upload your read files to correct the chromosomal location bias affecting your data"),
                 p("This requires two control files and two condition files, or one file of read counts containing all conditions of interest."),
                 box(
                   title = "Before and after normalisation",
                   status = "primary",
                   width = 12, height = 6,
                   imageOutput("corrected_plot", height = "100%", width = "100%")
                 ),
                 box(
                   title = "Normalised data",
                   downloadButton("downloadcsv", label = "download csv", class = "btn-secondary"),
                   br(),
                   status = "primary",
                   width = 12, height = 6,
                   DT::dataTableOutput("normdata")
                 )
        ),
        tabPanel("Help",
                 br(),
                 h2("Welcome to the ChromoCorrect Help Section!", style = "font-weight: bold;"),
                 br(),
                 h3("File Upload", style = "font-weight: bold;"),
                 p("To use ChromoCorrect, follow these steps to upload your files:"),
                 tags$ol(
                   tags$li("Click on the 'Detecting' tab."),
                   tags$li("In the sidebar, upload your output file(s). There must be columns called 'locus_tag' and 'logFC'."),
                   tags$li("Cycle through your files to determine which ones may be affected by chromosomal location bias. The message box on the right will guide you."),
                   tags$li("Click on the 'Correcting' tab if you have files affected by chromosomal location bias."),
                   tags$li("Upload your read counts files. These may be:",
                           tags$ul(
                             tags$li("TraDIS pipeline output files: a file per replicate. Files contain 'locus_tag' and 'read_count' columns."),
                             tags$li("One file containing read counts. The first column is 'locus_tag' and the four columns after are two biological replicates for two conditions. Replicate column names should end in _1 and _2. Anything before this will be used for the condition name.")
                           )
                   ),
                   tags$li("Choose which group is your control from the drop-down box. This is based on your file or column names."),
                   tags$li("Download your normalised data using the Download CSV button to get your data for downstream analysis.")
                 ),
                 br(),
                 h3("Example files", style = "font-weight: bold;"),
                 h4("Detecting tab - fold changes"),
                 h5("Example TraDIS output file. Contains locus_tag and logFC columns."),
                 p("Upload any number of files containing these columns in the Detecting tab to determine whether chromosomal location bias is affecting your data."),
                 DT::dataTableOutput("helpfc"),
                 br(),
                 h4("Correcting tab - read counts"),
                 h5("Example TraDIS read count file. Contains locus_tag and read_count columns."),
                 p("Upload two controls and two conditions into the TraDIS upload section of the Correcting tab."),
                 DT::dataTableOutput("helprc"),
                 h5("Example single read count file. Contains locus_tag and column names with group and replicate information."),
                 p("Each file must have at least two controls and two conditions, and no more than two groups."),
                 DT::dataTableOutput("helprc_single"),
                 h5("Example locus information file. Contains locus_tag column with any other descripive information."),
                 DT::dataTableOutput("helprc_locus"),
                 br(),
                 h3("Frequently Asked Questions (FAQ)", style = "font-weight: bold;"),
                 br(),
                 h4("I get an error 'more than two conditions detected' when trying to correct my data - what is this?"),
                 p("You need to follow the naming convention so the app can determine which files are replicates."),
                 p("Files should be named generally as 'condition_replicate.extension', such as 'MH_1.tradis.gene.insert.sites', without the extension when uploading one file of read counts: 'MH_1, MH_2, Cip_1, Cip_2'."),
                 br(),
                 h4("How do I interpret the scatterplot on the 'Detecting' tab?"),
                 p("The scatterplot shows the locus by fold change relationship. If the overall trend of your fold changes does not match the red line, it indicates a potential chromosomal location bias in your data. The decision tab will also let you know if it thinks your data needs correcting."),
                 br(),
                 h4("How can I download the normalised data?"),
                 p("On the 'Correcting' tab, you will find a 'Download CSV' button. Click on the button to download the normalised data as a CSV file."),
                 br(),
                 h4("Where can I find additional support?"),
                 p("If you have any further questions or need additional support, please refer to the",
                   tags$a(href = "https://htmlpreview.github.io/?https://github.com/gerisullivan/ChromoCorrect/blob/master/inst/Instructions.html", "documentation", target = "_blank"),
                 "or raise an issue on the", tags$a(href = "https://github.com/gerisullivan/ChromoCorrect/issues", "ChromoCorrect Github", target = "_blank"), ".")
        )
      )
    )
  ),

  server = function(input, output){

    output$mytab1 <- renderUI({
      tagList(
        conditionalPanel(condition = 'input.tabs=="Detecting"',
                         fileInput("uploadfc", "Upload your output file(s) here", buttonLabel = "Browse...", multiple = TRUE),
        ))
    })

    output$mytab1.1 <- renderUI({
      tagList(
        conditionalPanel(condition = 'input.tabs=="Detecting"',
                         selectizeInput("datasetsnorm", "Select dataset for visualising:",
                                        choices = gsub(".csv$", "", input$uploadfc$name))
        ))
    })

    output$helpfc <- DT::renderDataTable({
      dat <- read.delim("Cip_uncorrected.csv")
      DT::datatable(dat, rownames = F, options = list(paging = FALSE, searching = FALSE, ordering = FALSE))
    })

    output$helprc <- DT::renderDataTable({
      dat <- read.delim(file = "MH_2.tradis_gene_insert_sites.csv")
      DT::datatable(dat, rownames = F, options = list(paging = FALSE, searching = FALSE, ordering = FALSE))
    })

    output$helprc_single <- DT::renderDataTable({
      dat <- read.delim(file = "rc_example.txt")
      DT::datatable(dat, rownames = F, options = list(paging = FALSE, searching = FALSE, ordering = FALSE))
    })

    output$helprc_locus <- DT::renderDataTable({
      dat <- read.delim(file = "locusInfo.tsv")
      DT::datatable(dat, rownames = F, options = list(paging = FALSE, searching = FALSE, ordering = FALSE))
    })

    detecplot <- reactive({
      req(input$uploadfc)
      num <- grep(value = FALSE, pattern = input$datasetsnorm, fixed = T, x = input$uploadfc$name)
      if (length(num)>1){num <- 1}
      data <- read.csv(input$uploadfc$datapath[num])
      data$obs <- 1:nrow(data)
      data$`Significance (0.05)` <- ifelse(data$q.value<0.05, "Significant", "Not significant")
      ggplot(data, aes(x = obs, y = logFC, col = `Significance (0.05)`)) +
        geom_point(cex = 0.5) +
        geom_hline(yintercept = 0, col = "red") +
        theme_classic() +
        scale_color_manual(values = c("Significant" = "red", "Not significant" = "black")) +
        theme(plot.title = element_text(hjust = 0.5),
              text = element_text(size = 16)) +
        labs(x = "Locus", y = "Log2 Fold Change", title = paste("Fold change by locus scatterplot - ",
                                                                gsub(pattern = ".csv", "", input$uploadfc$name[[num]])))
    })

    output$detec_fc <- renderImage({
      req(input$uploadfc)
      outfile <- tempfile(fileext = ".png")
      png(outfile,
          width = 0.6*input$dimension[1]*8,
          height = 400*8,
          res = 72*8)
      print(detecplot())
      dev.off()

      list(src = outfile,
           contentType = 'image/png',
           width = 0.6*input$dimension[1],
           height = 400,
           alt = "This is alternate text")
    }, deleteFile = TRUE)

    output$detec_text <- renderText({
      req(input$uploadfc)
      num <- grep(pattern = input$datasetsnorm, x = input$uploadfc$name)
      if (length(num)>1){num <- 1}
      data <- read.csv(input$uploadfc$datapath[num])
      data$obs <- 1:nrow(data)
      length <- ceiling(nrow(data)/5)
      datcut <- split(data, rep(1:ceiling(nrow(data)/length), each=length, length.out=nrow(data)))
      summary <- data.frame()
      for (i in 1:length(datcut)){
        dat <- datcut[[i]]
        dat <- dat[complete.cases(dat$logFC),]
        dat.1 <- cut(dat$logFC, quantile(dat$logFC, c(0, 0.2, 0.8, 1)), include.lowest = TRUE, lab = c("lo", "mid", "hi"))
        dat.2 <- split(dat$logFC, dat.1)
        dat.2 <- as.data.frame(dat.2$mid)
        dat.2$ob <- 1:nrow(dat.2)
        model <- lm(dat.2$`dat.2$mid`~dat.2$ob)
        summary[i,1] <- summary(model)$coefficients[2,4]
        summary[i,2] <- median(dat.2$`dat.2$mid`)
        summary[i,3] <- mean(dat.2$`dat.2$mid`)
      }
      if (any(summary$V1<0.1) & (any(abs(summary$V2)>0.2) | any(abs(summary$V3)>0.2))){
        return(paste("<span style=\"color:red\">The trend line does not appear to be equal to 0.<br>Please consider proceeding to correction.</span>"))
      } else {
        return(paste("<span style=\"color:green\">The trend line appears to be approximately equal to 0.<br>Your data does not need correction.</span>"))
      }
    })

    output$mytab2 <- renderUI({
      tagList(
        conditionalPanel(condition = 'input.tabs=="Correcting"',
                         fileInput("uploadrc", "Upload your TraDIS read files here", multiple = TRUE, accept = c(".csv")),
                         fileInput("rcfile", "OR upload your read count table here", multiple = FALSE, accept = c(".csv", ".tsv", ".txt"))
        ))
    })

    output$mytab2.1 <- renderUI({
      tagList(
        conditionalPanel(condition = 'input.tabs=="Correcting"',
                         p("Your first column should be 'locus_tag', with read counts for replicates of a control and a condition in the following columns. Replicate column names should end with '_1', '_2' etc"),
                         h4("Choose condition for control here"),
                         if (!is.null(input$uploadrc)) {
                           selectizeInput("controlrc", "Select which condition is your control:",
                                          choices = c("Select one here", unique(gsub("_[0-9].tradis.gene.insert.sites.csv", "", input$uploadrc$name))))
                         } else if (!is.null(input$rcfile)) {
                           rc <- read.delim(input$rcfile$datapath)
                           selectizeInput("controlrc", "Select which condition is your control:",
                                          choices = c("Select one here", unique(gsub("_[0-9].*", "", colnames(rc)[2:ncol(rc)]))))
                         } else {
                           selectizeInput("controlrc", "Select which condition is your control:",
                                          choices = c("Select one here"))
                         },
                         uiOutput("button"),
                         hr(), h4("Optional"),
                         numericInput("minrc", "Minimum read count cutoff", value = 10),
                         fileInput("locusinfo", "Upload tab separate locus information", multiple = FALSE),
                         p("For example, a tab separated file with locus_tag, gene_name, function for extra information in the outputs.")
        ))
    })

    output$button <- renderUI({
      if (input$controlrc == "Select one here"){
        NULL
      } else if (!is.null(input$uploadrc$datapath)) {
        if (length(input$uploadrc$datapath)<4){
          shinyalert(text = "Less than 4 files detected. Please provide at least two replicates per control/condition.",
                     type = "error")
          NULL
        } else if (length(unique(gsub("_[0-9].tradis.gene.insert.sites.csv", "", input$uploadrc$name)))>2){
          shinyalert(text = "More than 2 conditions detected. Please provide at least two repliates for one control and one condition.",
                     type = "error")
          NULL
        } else {
          actionButton("run", "Start normalisation", class = "btn-primary btn-lg")
        }
      } else if (!is.null(input$rcfile)){
        rc <- read.delim(input$rcfile$datapath)
        uniq <- unique(gsub("_[0-9]$", "", colnames(rc)))
        if (length(uniq)<3) {
          shinyalert(text = "Not enough conditions detected. Please provide at least two repliates for a control and a condition.",
                     type = "error")
        } else if (length(uniq)>3) {
          shinyalert(text = "More than 2 conditions detected. Please provide at least two repliates for one control and one condition, or check your column names.",
                     type = "error")
        } else {
          actionButton("run", "Start normalisation", class = "btn-primary btn-lg")
        }
      }
    })

    readcounts <- eventReactive(input$run, {
      if (!is.null(input$uploadrc)){
        myfiles <- purrr::map(input$uploadrc$datapath, read.delim) %>%
          purrr::set_names(input$uploadrc$name)
        joined <- myfiles %>% purrr::reduce(full_join, by = "locus_tag")
        filenames <- input$uploadrc$name %>%
          gsub(pattern = ".tradis_gene_insert_sites.csv", replacement = "")
        rc <- joined %>% select(contains(c("locus_tag", "read_count")))
        colnames(rc)[2:ncol(rc)] <- filenames
      } else if (!is.null(input$rcfile)) {
        rc <- read.delim(input$rcfile$datapath)
      }
      rc
    })

    done <- FALSE

    correction <- reactive({
      window_size = 500
      while(TRUE){
        rc <- readcounts()
        rc <- cbind("locus_tag" = rc[,1], "ob" = 1:nrow(rc), rc[,2:ncol(rc)])
        norm_counts <- data.frame(row.names = rc$locus_tag)
        for (i in 3:ncol(rc)){
          calc <- rc[,c(1, 2, i)]
          back <- calc[1:1000,]
          back$keep <- nrow(calc)+1000
          front <- calc[((nrow(calc)-999):nrow(calc)),]
          front$keep <- nrow(calc)+1000
          calc$keep <- 1:nrow(calc)
          calc2 <- rbind(front, calc, back)

          calc2$pred <- FBN::medianFilter(inputData = calc2[,3], windowSize = window_size)
          calc2 <- calc2[!calc2$keep > nrow(rc),]
          calc2$ratio <- calc2$pred/mean(calc2$pred)
          calc2$norm <- as.integer(round(calc2[,3]/calc2$ratio))
          norm_counts[,i-2] <- calc2$norm
          rm(front, back, calc, calc2)
        }

        offset <- (log(norm_counts + 0.01) - log(rc[,3:(ncol(rc))] + 0.01))
        eff.lib <- calcNormFactors(norm_counts) * colSums(norm_counts)
        offset <- sweep(offset, 2, log(eff.lib), "-")
        colnames(offset) <- colnames(norm_counts) <- colnames(rc)[3:ncol(rc)]

        # norm_counts <- norm_counts[apply(apply(rc[3:ncol(rc)], 1, ">", 10), 2, any),]
        # offset <- offset[apply(apply(rc[3:ncol(rc)], 1, ">", 10), 2, any),]
        # rc <- rc[apply(apply(rc[3:ncol(rc)], 1, ">", 10), 2, any),]
        norm_counts <- norm_counts[apply(apply(rc[3:ncol(rc)], 1, ">", input$minrc), 2, any),]
        offset <- offset[apply(apply(rc[3:ncol(rc)], 1, ">", input$minrc), 2, any),]
        rc <- rc[apply(apply(rc[3:ncol(rc)], 1, ">", input$minrc), 2, any),]

        rownames(offset) <- rownames(rc) <- rc$locus_tag
        rc <- rc[,-c(1:2)]

        # Step 3 - edgeR (differential expression)
        group <- gsub("_[0-9]", replacement = "", x = colnames(rc))
        conds_edgeR <- as.factor(unique(group))
        #ctrl <- "MH"
        ctrl <- as.character(input$controlrc)
        conds_edgeR <- relevel(conds_edgeR, ref=ctrl)
        condition <- as.character(conds_edgeR[!conds_edgeR %in% ctrl])
        design <- model.matrix(~0+group)
        contrast <- makeContrasts(contrasts = paste0("group", condition, " - group", ctrl), levels = design)
        y <- DGEList(counts=rc, group=group, genes=rownames(rc))
        y <- scaleOffset(y, -as.matrix(offset))
        y <- estimateGLMCommonDisp(y, design)
        y <- estimateGLMTagwiseDisp(y, design)
        fit <- glmFit(y, design, robust=TRUE)
        lrt <- glmLRT(fit, contrast=contrast)
        tags_after <- lrt$table
        tags_after$q.value <- p.adjust(tags_after$PValue, method = "BH")
        tags_after <- subset(tags_after, select = -(LR))

        length <- ceiling(nrow(tags_after)/5)
        tagplot <- split(tags_after, rep(1:ceiling(nrow(tags_after)/length), each=length, length.out=nrow(tags_after)))

        summary <- data.frame()
        for (i in 1:length(tagplot)){
          dat <- tagplot[[i]]
          dat.2 <- cut(dat$logFC, quantile(dat$logFC, c(0, 0.2, 0.8, 1)), include.lowest = TRUE, lab = c("lo", "mid", "hi"))
          dat.2 <- split(dat$logFC, dat.2)
          dat.2 <- as.data.frame(dat.2$mid)
          dat.2$ob <- 1:nrow(dat.2)
          model <- lm(dat.2$`dat.2$mid`~dat.2$ob)
          summary[i,1] <- summary(model)$coefficients[2,4]
          summary[i,2] <- mean(dat.2$`dat.2$mid`)
          summary[i,3] <- summary(model)$coefficients[1,1]
          summary[i,4] <- max(dat.2$`dat.2$mid`)-min(dat.2$`dat.2$mid`)
        }
        #if (any(summary$V1<0.1) & (any(abs(summary$V2)>0.05) | any(abs(summary$V3)>0.05))){
        if (any(summary$V1<0.1) & any(abs(summary$V3)>0.05)) {
          if (window_size == 200){
            showNotification(paste("Window size of 200 is minimum to retain biological significance with operons. Stopping here."))
            break
          } else {
            showNotification(paste("Window size of ", window_size, " not correct, recomputing"))
            window_size <- window_size-100
            rm(norm_counts, offset, tags_after, tagplot, summary)
          }
        } else {
          showNotification(paste("Window size of ", window_size, " correct, finishing up"))
          break
        }
      }
      d <- DGEList(counts = rc, group=group)
      plotMDS.DGEList(d, labels=group)
      d <- calcNormFactors(d)
      d <- estimateCommonDisp(d)
      d <- estimateTagwiseDisp(d)
      de.tgw <- exactTest(d,pair=c(ctrl, condition))
      #de.tgw <- exactTest(d,pair=c("MH", "Cip"))
      tags_before <- data.frame(de.tgw$table)
      tags_before$q.value <- p.adjust(tags_before$PValue, method = "BH")
      tags_before$`Significance (0.05)` <- ifelse(tags_before$q.value < 0.05, "Significant", "Not significant")
      tags_before <<- tags_before
      tags_after$`Significance (0.05)` <- ifelse(tags_after$q.value < 0.05, "Significant", "Not significant")
      tags_after$ob <- 1:nrow(tags_after)
      cond <<- condition
      tags_before <<- tags_before
      tags_after <<- tags_after
      window_size <<- as.numeric(window_size)
    })

    corplot <- reactive({
      req(input$run)
      correction()
      before <- ggplot(tags_before, aes(x = 1:nrow(tags_before), y = logFC, col = `Significance (0.05)`)) +
        geom_point(size = 0.5) +
        theme_classic() +
        theme(text = element_text(size = 16),
              plot.title = element_text(hjust = 0.5, size = 18)) +
        labs(title = paste0("Uncorrected fold change plot by locus - ", cond),
             x = "Locus", y = "Log2 fold change") +
        scale_color_manual(values = c("Not significant" = "black", "Significant" = "red"), guide = "none")
      after <- ggplot(tags_after, aes(x = 1:nrow(tags_after), y = logFC, col = `Significance (0.05)`)) +
        geom_point(size = 0.5) +
        theme_classic() +
        theme(text = element_text(size = 16),
              plot.title = element_text(hjust = 0.5, size = 18),
              plot.subtitle = element_text(hjust = 0.5, size = 14)) +
        labs(title = paste0("Corrected fold change plot by locus - ", cond),
             x = "Locus", y = NULL, col = "Significant (0.05)", subtitle = paste("Sliding median window size of", as.numeric(window_size))) +
        scale_color_manual(values = c("Not significant" = "black", "Significant" = "red"))
      done <<- TRUE
      before+after
    })

    output$corrected_plot <- renderImage({
      req(input$run)
      outfile <- tempfile(fileext = ".png")
      png(outfile,
          width = 0.95*input$dimension[1]*8,
          height = 500*8,
          res = 72*8)
      print(corplot())
      dev.off()

      list(src = outfile,
           contentType = 'image/png',
           width = 0.95*input$dimension[1],
           height = 500,
           alt = "This is alternate text")
    }, deleteFile = TRUE)

    tableout <- reactive({
      req(input$run)
      corplot()
      if (done == TRUE) {
        tags_after <- cbind("locus_tag" = rownames(tags_after), tags_after[,c(1:(ncol(tags_after)-1))])
        rownames(tags_after) <- 1:nrow(tags_after)
        table_out <<- tags_after
        output$download <- renderUI(actionButton("download_attempt", "Download csv"))
        if (!is.null(input$locusinfo)){
          locusinfo <- read.delim(input$locusinfo$datapath)
          table_out <<- merge(locusinfo, table_out, by = "locus_tag", all.x = TRUE)
        }
      }
    })

    output$normdata <- DT::renderDataTable({
        tableout()
        table_out <- table_out[order(table_out$`Significance (0.05)`, -dat$logFC, decreasing = T),]
        DT::datatable(table_out[,1:ncol(table_out)], rownames = FALSE, options = list(pageLength = 15)) %>% DT::formatRound(columns = c((ncol(table_out)-3):(ncol(table_out))), digits = c(2,2,4,4))
      })

    output$downloadcsv <- downloadHandler(
      filename = function() {
        paste0(cond, "_ChromoCorrect.csv")
      },
      content = function(file) {
        write.csv(table_out, file, row.names=FALSE)
      })
  }
)

