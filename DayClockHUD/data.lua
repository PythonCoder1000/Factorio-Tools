local styles = data.raw["gui-style"]["default"]

styles["dayclock_frame"] = {
  type = "frame_style",
  parent = "frame",
  padding = 0,
  minimal_width = 232,
}

styles["dayclock_inner_frame"] = {
  type = "frame_style",
  parent = "inside_deep_frame",
  padding = 10,
  top_padding = 7,
  bottom_padding = 8,
}

styles["dayclock_header_flow"] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  vertical_align = "center",
  horizontal_spacing = 6,
}

styles["dayclock_body_flow"] = {
  type = "vertical_flow_style",
  parent = "vertical_flow",
  vertical_spacing = 3,
  top_margin = 2,
}

styles["dayclock_row_flow"] = {
  type = "horizontal_flow_style",
  parent = "horizontal_flow",
  vertical_align = "center",
  horizontal_spacing = 6,
}

styles["dayclock_day_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-large-semibold",
  font_color = {r = 1.0, g = 0.93, b = 0.4},
}

styles["dayclock_hdr_time"] = {
  type = "label_style",
  parent = "label",
  font = "default-semibold",
  font_color = {r = 0.78, g = 0.82, b = 0.88},
  left_margin = 2,
}

styles["dayclock_phase_badge"] = {
  type = "label_style",
  parent = "label",
  font = "default-bold",
  font_color = {r = 0.7, g = 0.7, b = 0.7},
  right_margin = 2,
}

styles["dayclock_value_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-semibold",
  font_color = {r = 0.92, g = 0.92, b = 0.92},
  horizontal_align = "right",
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
  font_color = {r = 0.58, g = 0.58, b = 0.6},
  minimal_width = 52,
}

styles["dayclock_playtime_label"] = {
  type = "label_style",
  parent = "label",
  font = "default-semibold",
  font_color = {r = 0.55, g = 1.0, b = 0.65},
  horizontal_align = "right",
}

styles["dayclock_progress"] = {
  type = "progressbar_style",
  parent = "progressbar",
  height = 12,
  horizontally_stretchable = "on",
  color = {r = 1.0, g = 0.85, b = 0.1},
}

styles["dayclock_divider"] = {
  type = "line_style",
  parent = "line",
  top_margin = 2,
  bottom_margin = 2,
}

styles["dayclock_icon_style"] = {
  type = "image_style",
  parent = "image",
  size = 18,
  stretch_image_to_widget_size = true,
}

styles["dayclock_toggle_button"] = {
  type = "button_style",
  parent = "frame_action_button",
  size = 20,
  padding = 0,
  left_margin = 2,
  font = "default-bold",
  default_font_color = {r = 0.7, g = 0.7, b = 0.7},
  hovered_font_color = {r = 1.0, g = 1.0, b = 1.0},
  clicked_font_color = {r = 1.0, g = 1.0, b = 1.0},
}
