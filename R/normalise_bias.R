#' @title Normalise bias
#'
#' @description Normalises chromosomal location bias in read counts
#'
#' @author Geraldine J Sullivan
#'
#' @param x Readcounts from structure_rc(). Required.
#' @param control Name of the condition that is to be used for the control during comparisons. No replicate information desired. Required.
#' @param windowSize Specify the window size for the sliding median normalisation. Either "auto" or a number. Minimum 200, maximum 1000. Optional. Default: auto.
#' @param minrc Minimum read count for filtering out low values. Optional. Default: 10.
#' @param locusInfo TRUE or FALSE. Whether locus information should be added to locus tags. Only possible if structure_rc() set getLocusInfo to TRUE. Path to file must be specified in path variable. Optional. Default: TRUE.
#' @param path Path to folder containing locusInfo.tsv, and path where plots will be saved. Required if locusInfo = TRUE. Default: "./readcounts.
#' @param writePlots TRUE or FALSE. Write out locus by fold change scatterplots to observe peaks and troughs in data. Plots are written to path specified in path variable. Optional. Default: TRUE.
#'
#' @references Will add here later
#'
normalise_bias <- function(x,
                           control = "",
                         windowSize = "auto",
                         minrc = 10,
                         writePlots = TRUE,
                         locusInfo = TRUE,
                         path = "./readcounts/")
{
  if (windowSize == "auto") {window = 500} else {window = windowSize}
  if (control == "") {stop("Please specify the name of your control file. This will be any text that is before '_1.csv'")}
  if (length(unique(gsub("_[0-9]$", "", colnames(x)[2:ncol(x)]))) > 2) {stop("More than 2 conditions detected. Please rerun the read count script with files from only two conditions, or delete extra columns.")}
  message("Minimum read count set to 10 (default)")
  while(TRUE){
    rc <- cbind("locus_tag" = x[,1], "ob" = 1:nrow(x), x[,2:ncol(x)])
    norm_counts <- data.frame(row.names = rc$locus_tag)
    for (i in 3:ncol(rc)){
      calc <- rc[,c(1, 2, i)]
      calc[(nrow(calc)+1):(nrow(calc)+1000),] <- calc[1:1000,]
      calc$keep <- 1:nrow(calc)
      calc$pred <- FBN::medianFilter(inputData = calc[,3], windowSize = window)
      calc <- calc[!calc$keep > nrow(rc),]
      calc$ratio <- calc$pred/mean(calc$pred)
      calc$norm <- as.integer(round(calc[,3]/calc$ratio))
      norm_counts[,i-2] <- calc$norm
    }

    offset <- (log(norm_counts + 0.01) - log(rc[,3:(ncol(rc))] + 0.01))
    eff.lib <- calcNormFactors(norm_counts) * colSums(norm_counts)
    offset <- sweep(offset, 2, log(eff.lib), "-")
    colnames(offset) <- colnames(norm_counts) <- colnames(rc)[3:ncol(rc)]

    norm_counts <- norm_counts[apply(apply(rc[3:ncol(rc)], 1, ">", minrc), 2, any),]
    offset <- offset[apply(apply(rc[3:ncol(rc)], 1, ">", minrc), 2, any),]
    rc <- rc[apply(apply(rc[3:ncol(rc)], 1, ">", minrc), 2, any),]

    rownames(offset) <- rownames(rc) <- rc$locus_tag
    rc <- rc[,-c(1:2)]

    # Step 3 - edgeR (differential expression) to get negative control genes
    group <- gsub("_[0-9]", replacement = "", x = colnames(rc))
    conds_edgeR <- as.factor(unique(group))
    conds_edgeR <- relevel(conds_edgeR, ref=control)
    condition <- as.character(conds_edgeR[!conds_edgeR %in% control])

    design <- model.matrix(~0+group)
    contrast <- makeContrasts(contrasts = paste0("group", condition, " - group", control), levels = design)
    y <- DGEList(counts=rc, group=group, genes=rownames(rc))
    y <- scaleOffset(y, -as.matrix(offset))
    y <- estimateGLMCommonDisp(y, design)
    y <- estimateGLMTagwiseDisp(y, design)
    fit <- glmFit(y, design, robust=TRUE)
    lrt <- glmLRT(fit, contrast=contrast)
    tags <- lrt$table
    tags$ob <- 1:nrow(tags)

    if (writePlots == TRUE){
      name <- paste0(condition, "vs", control)
      png(paste0(path, "/window", window, " - ", name, ".png"), res = 300, height = 2000, width = 3000)
      plot(loess(tags$logFC~tags$ob), pch = 20, cex = 0.5, col = ifelse(tags$PValue<0.05, "red", "black"),
           xlab = "Locus", ylab = "Log2 fold change", main = paste0(name, " - window size ", window))
      legend("topright", legend = c("not significant", "significant"), col = c("black", "red"),
             pch = 20)
      abline(h = 0, col = "red")
      dev.off()
    }

    length <- ceiling(nrow(tags)/5)
    tagplot <- split(tags, rep(1:ceiling(nrow(tags)/length), each=length, length.out=nrow(tags)))

    summary <- data.frame()
    for (i in 1:length(tagplot)){
      dat <- tagplot[[i]]
      dat.2 <- cut(dat$logFC, quantile(dat$logFC, c(0, 0.4, 0.6, 1)), include.lowest = TRUE, lab = c("lo", "mid", "hi"))
      dat.2 <- split(dat$logFC, dat.2)
      dat.2 <- as.data.frame(dat.2$mid)
      dat.2$ob <- 1:nrow(dat.2)
      model <- lm(dat.2$`dat.2$mid`~dat.2$ob)
      summary[i,1] <- summary(model)$coefficients[2,4]
      summary[i,2] <- median(dat.2$`dat.2$mid`)
      summary[i,3] <- mean(dat.2$`dat.2$mid`)
    }

    tags$locus_tag <- rownames(tags)
    rownames(tags) <- NULL

    suppressWarnings(mtry <- try(read.delim(paste0(path, "/locusInfo.tsv")), silent = TRUE))
    if (class(mtry) != "try-error") {
      locusinfo <- read.delim(paste0(path, "/locusInfo.tsv"))
      outdf <- merge(locusinfo, tags[,-c(ncol(tags)-1)], by = "locus_tag", all.x = TRUE)
    } else {
      outdf <- tags[,c(ncol(tags), 2:(ncol(tags)-2))]
      if (locusInfo == TRUE) {
        warning("No locus annotation file provided but locusInfo left to default True. Consider changing the flag or providing the path to locusInfo.tsv")
        locusInfo = FALSE
      }
    }

    if (any(summary$V1<0.1) & (any(abs(summary$V2)>0.2) | any(abs(summary$V3)>0.2))){
      if (windowSize != "auto") {
        message("Window size of ", window, "doesn't seem suitable, please consider using the windowSize = auto setting instead. Writing to file anyway.")
        break
      } else if (window == 200){
        message("Window size of 200 is minimum to retain biological significance with operons. Stopping here.")
      } else {
        message("Window size of ", window, " not correct, recomputing")
        window <- window-100
        rm(rc, norm_counts, offset)
      }
    } else {
      message("Window size of ", window, " correct, finishing up")
      break
    }
  }
  return(outdf)
}