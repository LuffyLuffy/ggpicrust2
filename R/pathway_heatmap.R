#' Create pathway heatmap
#'
#' This function creates a heatmap of the predicted functional pathway abundance data. The function first makes the abundance data relative, then converts the abundance data to a long format and orders the samples based on the environment information. The heatmap is then created using the `ggplot2` library. The color palette, appearance and the color bar of the heatmap can be customized using the `scale_fill_gradientn`, `theme` and `guides` functions respectively.
#'
#' @name pathway_heatmap
#' @param abundance A matrix or data frame of pathway abundance data, where columns correspond to samples and rows correspond to pathways.
#' @param metadata A data frame of metadata, where each row corresponds to a sample and each column corresponds to a metadata variable.
#' @param group A character string specifying the column name in the metadata data frame that contains the group variable.
#'
#' @return A ggplot heatmap object. The output is a ggplot object representing the heatmap of the predicted functional pathway abundance data. The heatmap visualizes the z score of pathways in different samples.
#' @export
#'
#' @import dplyr
#' @import ggplot2
#' @import tidyr
#'
#' @examples
#' # Create example functional pathway abundance data
#' abundance_example <- matrix(rnorm(30), nrow = 10, ncol = 3)
#' rownames(abundance_example) <- paste0("Sample", 1:10)
#' colnames(abundance_example) <- c("PathwayA", "PathwayB", "PathwayC")
#'
#' # Create example metadata
#' # Please ensure the sample IDs in the metadata have the column name "sample_name"
#' metadata_example <- data.frame(sample_name = rownames(abundance_example),
#'                                group = factor(rep(c("Control", "Treatment"), each = 5)))
#'
#' # Create a heatmap
#' heatmap_plot <- pathway_heatmap(t(abundance_example), metadata_example, "group")
#' print(heatmap_plot)
utils::globalVariables(c("rowname","Sample","Value"))
pathway_heatmap <- function(abundance, metadata, group) {
   # Heatmaps use color changes to visualize changes in values. However, if the
   # data for plotting the heat map are too different, for example, if the heat
   # map is plotted using gene expression data, gene1 is expressed above 1000 in
   # all samples and gene2 is expressed between 1-10 in all samples, it is
   # difficult to plot the heat map with small changes in the expression of two
   # genes in different samples by the colors to reflect. Therefore, when
   # plotting a heat map, we usually normalize the gene expression data, that
   # is, we subtract the mean value of each gene expression from the expression
   # of this gene in all samples and divide it by its standard deviation, and
   # this normalization is called standard normalization or Z-score processing.
   # The processed values are reduced equally, and the expression of each gene
   # in all samples becomes a set of values with a mean of 0 and a standard
   # deviation of 1. At this point, the plotted heat map gives a good indication
   # of the variation in expression of all genes across samples.
  z_abundance <- t(apply(abundance, 1, scale))
  colnames(z_abundance) <- colnames(abundance)


  # Convert the abundance matrix to a data frame
  z_df <- as.data.frame(z_abundance)

  # Order the samples based on the environment information
  ordered_metadata <- metadata[order(metadata[, group]),]
  order <- ordered_metadata$sample_name


  # Convert the abundance data frame to a long format
  long_df <- z_df %>%
    tibble::rownames_to_column() %>%
    tidyr::pivot_longer(cols = -rowname,
                        names_to = "Sample",
                        values_to = "Value")

  # Set the order of the samples in the heatmap
  long_df$Sample <- factor(long_df$Sample, levels = order)

  # Create the heatmap using ggplot
  p <-
    ggplot2::ggplot(data = long_df,
                    mapping = ggplot2::aes(x = Sample, y = rowname, fill = Value)) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradientn(colours = c("#0571b0","#92c5de","white","#f4a582","#ca0020"), breaks = c(0,0.2, 0.4, 0.6)) +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::scale_y_discrete(expand = c(0, 0), position = "left") +
    ggplot2::scale_x_discrete(expand = c(0, 0)) +
    # Customize the appearance of the heatmap
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 12, color = "black"),
      axis.ticks = ggplot2::element_blank(),
      axis.text = ggplot2::element_text(
        color = "black",
        size = 10,
        face = "bold"
      ),
      legend.title = ggplot2::element_text(size = 12, color = "black",face = "bold"),
      legend.text = ggplot2::element_text(size = 12, color = "black",face = "bold"),
      panel.background = ggplot2::element_blank(),
      legend.margin = ggplot2::margin(l = 0, unit = "cm")
    ) +
    # Add a color bar to the heatmap
    ggplot2::guides(
      fill = ggplot2::guide_colorbar(
        direction = "vertical",
        reverse = F,
        barwidth = unit(0.6, "cm"),
        barheight = unit(9, "cm"),
        title = "Z Score",
        title.position = "top",
        title.hjust = -1,
        ticks = TRUE,
        label = TRUE
      )
    )


  return(p)
}
