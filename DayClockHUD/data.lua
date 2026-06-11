local styles = data.raw["gui-style"]["default"]

styles["dayclock_frame"] = {
  type = "frame_style",
  parent = "frame",
  padding = 0,
  minimal_width = 210,
}

styles["dayclock_inner_frame"] = {
  type = "frame_style",
  parent = "inside_deep_frame",
  padding = 8,
  top_padding = 6,
  bottom_padding = 6,
}

styles["dayclock_header_flow"] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  vertical_align = "center",
  horizontal_spacing = 6,
  bottom_margin = 4,
}

styles["dayclock_row_flow"] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  vertical_align = "center",
  horizontal_spacing = 5,
  top_margin = 3,
}

styles["dayclock_day_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-large-semibold",
  font_color = {r = 1.0, g = 0.92, b = 0.3},
}

styles["dayclock_phase_badge"] = {
  type = "label_style",
  parent = "label",
  font = "default-bold",
  font_color = {r = 0.65, g = 0.65, b = 0.65},
  right_margin = 0,
}

styles["dayclock_time_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-semibold",
  font_color = {r = 1.0, g = 1.0, b = 1.0},
  minimal_width = 38,
}

styles["dayclock_dim_label"] = {
  type = "label_style",
  parent = "label",
  font = "default",
  font_color = {r = 0.55, g = 0.55, b = 0.55},
}

styles["dayclock_playtime_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-semibold",
  font_color = {r = 0.55, g = 1.0, b = 0.65},
}

styles["dayclock_progress"] = {
  type = "progressbar_style",
  parent = "progressbar",
  width = 100,
  height = 10,
  color = {r = 1.0, g = 0.85, b = 0.1},
  bar_width = 100,
}

styles["dayclock_divider"] = {
  type = "line_style",
  parent = "line",
  top_margin = 3,
  bottom_margin = 3,
}

styles["dayclock_icon_style"] = {
  type = "image_style",
  parent = "image",
  size = 18,
  stretch_image_to_widget_size = true,
}
