# Participant-level inference for the primary lexical-by-MDD RSA model.
# Usage: Rscript participant_inference.R /path/original_coefficients.csv /path/new_results.csv
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript participant_inference.R INPUT.csv NEW_OUTPUT.csv")
}
if (!file.exists(args[1])) stop("Input file does not exist")
if (file.exists(args[2])) stop("Output already exists; choose a new file")
if (!dir.exists(dirname(args[2]))) stop("Output parent directory does not exist")

dat <- read.csv(args[1], check.names = FALSE, stringsAsFactors = FALSE)
rois <- c("IFG_L", "IFG_R", "IFGorb_L", "IFGorb_R", "MFG_L", "MFG_R",
          "AntTemp_L", "AntTemp_R", "PostTemp_L", "PostTemp_R")
terms <- c("Lexical", "Syntactic", "Interaction")
expected <- unlist(lapply(rois, function(roi) paste(roi, terms, sep = "_")))
if (anyDuplicated(names(dat)) || !setequal(names(dat), c("Subjects", expected))) {
  stop("Expected Subjects and exactly 30 ROI_term coefficient columns")
}
if (nrow(dat) != 12L || anyNA(dat$Subjects) ||
    any(!nzchar(trimws(as.character(dat$Subjects)))) || anyDuplicated(dat$Subjects)) {
  stop("Expected 12 nonmissing, nonempty, unique participant identifiers")
}
if (!all(vapply(dat[expected], is.numeric, logical(1)))) {
  stop("Coefficient columns must be numeric")
}
if (!all(is.finite(as.matrix(dat[expected])))) stop("Coefficients must be finite")

signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), nrow(dat))))
rows <- lapply(expected, function(label) {
  term <- sub(".*_", "", label)
  roi <- sub("_[^_]+$", "", label)
  x <- dat[[label]]
  if (sd(x) == 0) stop(paste("Zero coefficient variance:", label))
  test <- t.test(x, alternative = "two.sided", mu = 0)
  # Sum and mean yield identical comparisons because n is fixed in every draw.
  flip_p <- mean(abs(signs %*% x) >= abs(sum(x)) - 1e-13)
  data.frame(roi = roi, term = term, n = length(x), mean_beta = mean(x),
             sd_beta = sd(x), sem_beta = sd(x) / sqrt(length(x)),
             ci95_low = test$conf.int[1], ci95_high = test$conf.int[2],
             t = unname(test$statistic), df = unname(test$parameter),
             p = test$p.value, cohen_d = mean(x) / sd(x),
             n_positive = sum(x > 0), n_negative = sum(x < 0),
             n_zero = sum(x == 0), sign_flip_p = flip_p)
})
stats <- do.call(rbind, rows)
stats$q_bh <- stats$sign_flip_q_bh <- NA_real_
for (term in terms) {
  i <- stats$term == term
  stats$q_bh[i] <- p.adjust(stats$p[i], method = "BH")
  stats$sign_flip_q_bh[i] <- p.adjust(stats$sign_flip_p[i], method = "BH")
}
write.csv(stats, args[2], row.names = FALSE)
