# Figure specifications

fig_spec <- list()
fig_spec <- within(fig_spec, {
  
  # color coding
  colors <- list(
    sample =
      c(
        training = "grey70",
        test = "grey30"
      ),
    sex =
      c(
        `Male` = "#c60c30",
        `Female` = "#004B87"
      ),
    discrete =
      c('#D23737', # red
        '#3191C9', # blue
        '#D2BC2D', # yellow
        '#4EC93B', # green
        '#881F93', # purple
        '#C5752B') ,# orange
    discrete_light =
      c('#FCB3B3', # red
        '#A7DDFC', # blue
        '#FAEC8E'  # yellow
      )
  )
  
  MyGGplotTheme <-
    function (
      size = 8,
      family = 'sans',
      scaler = 1,
      axis = 'x',
      panel_border = FALSE,
      grid = 'y',
      show_legend = TRUE,
      ar = NA
    ) {
      
      size_med = size*scaler
      size_sml = round(size*0.7)*scaler
      base_linesize = 0.3*scaler
      
      list(
        theme_minimal(base_size = size_med, base_family = family),
        theme(
          # basic
          text = element_text(color = 'black'),
          line = element_line(size = base_linesize, lineend = 'square'),
          # axis
          #axis.line.y = element_blank(),
          axis.title = element_text(size = size_med, face = 'bold'),
          #axis.ticks = element_line(size = rel(0.5), color = 'black'),
          axis.text = element_text(size = size_med, color = 'black'),
          # strips
          strip.text = element_text(color = 'black', size = size_med),
          strip.background = element_blank(),
          # plot
          title = element_text(face = 'bold'),
          plot.subtitle = element_text(color = 'black', size = size_med, face = 'bold'),
          plot.caption = element_text(color = 'black', size = size_sml, face = 'plain'),
          plot.background = element_blank(),
          panel.background = element_blank(),
          #plot.margin = unit(c(1, 0.1, 0.5, 0.5), units = 'mm'),
          # grid
          panel.grid = element_blank()
        ),
        if (identical(grid, 'y')) {
          theme(panel.grid.major.y =
                  element_line(linetype = 3, color = 'grey80'))
        },
        if (identical(grid, 'x')) {
          theme(panel.grid.major.x =
                  element_line(linetype = 3, color = 'grey80'))
        },
        if (identical(grid, 'xy') | identical(grid, 'yx')) {
          theme(panel.grid.major.y =
                  element_line(linetype = 3, color = 'grey80'),
                panel.grid.major.x =
                  element_line(linetype = 3, color = 'grey80'))
        },
        if (isTRUE(panel_border)) {
          theme(
            panel.border =
              element_rect(fill = NA)
          )
        },
        if (!isTRUE(show_legend)) {
          theme(legend.position = 'none')
        },
        if (axis == 'x') {
          theme(
            axis.line.x = element_line(linetype = 1, color = 'black')
          )
        },
        if (axis == 'y') {
          theme(
            axis.line.y = element_line(linetype = 1, color = 'black')
          )
        },
        if (axis == 'xy') {
          theme(
            axis.line = element_line(linetype = 1, color = 'black')
          )
        },
        if (!is.na(ar)) {
          theme(
            aspect.ratio = ar
          )
        }
      )
    }
  
  fig_dims <- list(
    # figure width (mm)
    width = 170
  )
  
})
