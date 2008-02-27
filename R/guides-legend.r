gglegends <- function(legends, usage) {
  # Need to collapse legends describing same values into single data.frame
  # - first group by name
  if (length(legends) == 0) 
    return()
  
  legend_names <- unname(unlist(lapply(legends, "[", "name")))
  name_strings <- sapply(legend_names, deparse)
  names(legend_names) <- name_strings
  
  keys <- lapply(legends, "[[", "display")
  variables <- split(keys, name_strings)

  # - then merge data.frames
  keys_merged <- lapply(variables, merge_legends)
  legends_merged <- mapply(function(name, keys) list(name = legend_names[name], display=keys), names(keys_merged), keys_merged, SIMPLIFY = FALSE, USE.NAMES = FALSE)  
  
  lapply(legends_merged, gglegend, usage=usage)
}

merge_legends <- function(legends) {
  n <- length(legends)
  if (n < 2) return(legends[[1]])
  
  all <- legends[[1]]
  for(i in 2:n) 
    all <- merge(all, legends[[i]], by="label", sort="false")
  all
}

gglegend <- function(legend, usage=usage) {
  display <- legend$display

  aesthetics <- setdiff(names(legend$display), "label")
  
  legend_f <- function(x) {
    geom <- Geom$find(x)
    used <- names(Filter(function(geom) any(geom == x), usage))
    function(data) geom$draw_legend(data[used])
  }
  grobs <- lapply(unique(unlist(usage[aesthetics])), legend_f)

  title <- ggname("title", textGrob(legend$name[[1]], x = 0, y = 0.5, just = c("left", "centre"), 
    gp=gpar(fontface="bold")
  ))
  
  nkeys <- nrow(display)
  hgap <- vgap <- unit(0.3, "lines")

  
  label.heights <- do.call("unit.c", lapply(display$label, function(x) stringHeight(as.expression(x))))
  label.widths  <- do.call("unit.c", lapply(display$label, function(x) stringWidth(as.expression(x))))

  grobwidth <- if ("point" %in% usage[aesthetics] && !is.null(display$size)) {
    unit(max(display$size) / 2, "mm")
  } else {
    unit(0, "mm")
  }
  widths <- unit.c(
    unit(1.4, "lines"), 
    hgap, 
    max(
      unit.c(unit(1, "grobwidth", title) - unit(1.4, "lines") - 2 * hgap),
      label.widths,
      grobwidth 
    ),
    hgap
  )

  grobheight <- unit(nulldefault(display$size, 0), "mm")
  heights <- unit.c(
    unit(1, "grobheight", title) + 2 * vgap, 
    unit.pmax(unit(1.4, "lines"), vgap + label.heights, grobheight)
  )  

  # Layout the legend table
  legend.layout <- grid.layout(nkeys + 1, 4, widths = widths, heights = heights, just=c("left","top"))
  fg <- ggname("legend", frameGrob(layout = legend.layout))
  #fg <- placeGrob(fg, rectGrob(gp=gpar(fill="NA", col="NA", name="legend-background")))

  numeric_labels <- all(sapply(display$label, is.language)) || suppressWarnings(all(!is.na(sapply(display$label, "as.numeric"))))
  valign <- if(numeric_labels) "right" else "left"
  vpos   <- if(numeric_labels) 1 else 0

  fg <- placeGrob(fg, title, col=1:2, row=1)
  for (i in 1:nkeys) {
    df <- as.list(display[i,, drop=FALSE])
    for(grob in grobs) {
      fg <- placeGrob(fg, ggname("key", grob(df)), col = 1, row = i+1)      
    }
    fg <- placeGrob(fg, ggname("label", textGrob(display$label[[i]], x = vpos, y = 0.5, just = c(valign, "centre"))), col = 3, row = i+1)
  }

  fg
}