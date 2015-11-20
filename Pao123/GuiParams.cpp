//
//  GuiParams.cpp
//  Pao123
//
//  Created by Zhenyong Chen on 7/14/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#include "GuiParams.h"

// will set by AppDelegate during app start
double rate_pixel_to_point = 1.0;

//---- XJMainVC ----
int lo_main_heartratename_width = 106;
int lo_main_heartratename_height = 40;
int lo_main_heartratename_font_size = 20 * 2;
int lo_main_heartratevalue_width = 89;
int lo_main_heartratevalue_height = 48;
int lo_main_heartratevalue_origin_x_offset_from_center = 71;
int lo_main_heartratevalue_origin_y = 752;
int lo_main_heartratevalue_font_size = 26 * 2;

int lo_main_gps_origin_x_offset_from_center = lo_main_heartratevalue_origin_x_offset_from_center;
int lo_main_gpsname_width = 106;
int lo_main_gpsname_height = 40;
int lo_main_gpsname_font_size = lo_main_heartratename_font_size;
int lo_main_gpsvalue_width = 64;
int lo_main_gpsvalue_height = 48;
int lo_main_gpsvalue_font_size = lo_main_heartratevalue_font_size;

int lo_main_run_diameter = 434;
int lo_main_run_origin_y_from_bottom = 782;
int lo_main_run_font_size = 36 * 2;

//---- XJGoVC ----
int lo_go_pause_outerline_width = 9;
int lo_go_minordata_abs_y = (745-20);
int lo_go_minordata_height = 136;
int lo_go_pausebutton_center_y_to_bottom = 523; // from bottom to center of pause button (pixel)
int lo_go_pausebutton_size = 261.0/2;
int lo_go_pausebutton_font_size = 30 * 2;
int lo_go_resumebutton_size = 290;
int lo_go_resumebutton_font_size = 30 * 2;
int lo_go_resume_finish_center_distance = 410;

//---- Menu ----
int lo_menu_width = 793;
int lo_menu_header_height = 674 - 84;
int lo_menu_photo_y_offset = 97;
int lo_menu_photo_diameter = 272;
int lo_menu_nickname_y_offset = 422;
int lo_menu_nickname_height = 54;
int lo_menu_item_size = 305;

//---- XJSettingsVC ----
int lo_settings_icon_size = 205;
int lo_settings_icon_x_center_offset = 224;
int lo_settings_icon_y_center_offset = 342;
int lo_settings_table_y_offset = 569 - 160;
int lo_settings_cell_switch_width = 104;
int lo_settings_cell_switch_height = 64;


//---- realplayer ----
int lo_realplayer_topbar_width = 400;