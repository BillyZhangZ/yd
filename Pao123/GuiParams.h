//
//  GuiParams.h
//  Pao123
//
//  Created by Zhenyong Chen on 7/14/15.
//  Copyright (c) 2015 XingJian Software. All rights reserved.
//

#ifndef __Pao123__GuiParams__
#define __Pao123__GuiParams__

#include <stdio.h>

extern double rate_pixel_to_point;


//-----------------------------------------
// UI theme
//-----------------------------------------
// system status bar height: 20 pixels
#define STATUSBARHEIGHT 20
// height of title bar, button, etc.
#define TITLEBARHEIGHT 44

#define DEFBKCOLOR [UIColor colorWithRed:0x24/255.0 green:0x25/255.0 blue:0x2a/255.0 alpha:1.0]
//#define STATUSBARTINTCOLOR [UIColor colorWithRed:0.24 green:0.45 blue:0.76 alpha:1.0]
#define STATUSBARTINTCOLOR [UIColor colorWithRed:0.5 green:0.0 blue:0.5 alpha:0.0] // transparent
#define DEFFGCOLOR [UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:1.0]
#define DEFFGCOLORHALF [UIColor colorWithRed:0xf0/255.0 green:0x65/255.0 blue:0x22/255.0 alpha:0.8]

#define BACKGROUNDPIC_WIDTH (960.0/3)
#define BACKGROUNDPIC_HEIGHT (1099.0/3)
#define FIRE_WIDTH (56.0/2)
#define FIRE_HEIGHT (66.0/2)
#define FIRE_ABS_Y (343.0*rate_pixel_to_point) // absolute position
// major data (biggest font to show most important data)
#define MAJORDATA_TITLE_ABS_Y ((481.0-10)*rate_pixel_to_point)
#define MAJORDATA_TITLE_FONT_NAME @"Roboto-Light"
#define MAJORDATA_TITLE_FONT_SIZE (82*2*rate_pixel_to_point) // psd file: uses 2x DPI
#define NAVIGATIONBAR_LEFT_ICON_SIZE 44
#define NAVIGATIONBAR_TITLE_FONT_NAME @"UniSansThinCAPS"
//#define NAVIGATIONBAR_TITLE_FONT_NAME @"Helvetica"
#define NAVIGATIONBAR_TITLE_FONT_SIZE (26*2*rate_pixel_to_point)
#define NAVIGATIONBAR_SIDE_FONT_SIZE (20*2*rate_pixel_to_point)



// Parameters for XJMainVC
// icon: heart rate
#define HEART_WIDTH (35.0/2)
#define HEART_HEIGHT (31.0/2)

// label: heart rate name
extern int lo_main_heartratename_width;
extern int lo_main_heartratename_height;
#define LO_MAIN_HEARTRATENAME_TEXT_COLOR [UIColor colorWithRed:0xa7/255.0 green:0xa7/255.0 blue:0xa9/255.0 alpha:1.0]
extern int lo_main_heartratename_font_size;

// label: heart rate value
extern int lo_main_heartratevalue_origin_x_offset_from_center;
extern int lo_main_heartratevalue_origin_y;
extern int lo_main_heartratevalue_width;
extern int lo_main_heartratevalue_height;
#define LO_MAIN_HEARTRATEVALUE_TEXT_COLOR [UIColor colorWithRed:0xa7/255.0 green:0xa7/255.0 blue:0xa9/255.0 alpha:1.0]
extern int lo_main_heartratevalue_font_size;

// icon: gps
#define GPS_WIDTH (27.0/2)
#define GPS_HEIGHT (34.0/2)
extern int lo_main_gps_origin_x_offset_from_center;

// label: gps name
extern int lo_main_gpsname_width;
extern int lo_main_gpsname_height;
#define LO_MAIN_GPSNAME_TEXT_COLOR [UIColor colorWithRed:0xa7/255.0 green:0xa7/255.0 blue:0xa9/255.0 alpha:1.0]
extern int lo_main_gpsname_font_size;

// label: gps value
extern int lo_main_gpsvalue_width;
extern int lo_main_gpsvalue_height;
#define LO_MAIN_GPSVALUE_TEXT_COLOR [UIColor colorWithRed:0xa7/255.0 green:0xa7/255.0 blue:0xa9/255.0 alpha:1.0]
extern int lo_main_gpsvalue_font_size;

// button: run
extern int lo_main_run_diameter;
extern int lo_main_run_origin_y_from_bottom;
extern int lo_main_run_font_size;

// Parameters for XJGoVC
// circle track line width
extern int lo_go_pause_outerline_width;

#define MINORDATA_TITLE_FONT_SIZE (40*2*rate_pixel_to_point)
#define MINORDATA_SUBTITLE_FONT_SIZE (16*2*rate_pixel_to_point)
extern int lo_go_minordata_abs_y;
extern int lo_go_minordata_height;
#define MINORDATA_SPLIT_COLOR [UIColor colorWithRed:0x32/255.0 green:0x32/255.0 blue:0x37/255.0 alpha:1.0]
extern int lo_go_pausebutton_center_y_to_bottom;
extern int lo_go_pausebutton_size;
extern int lo_go_pausebutton_font_size;
extern int lo_go_resumebutton_size;
extern int lo_go_resumebutton_font_size;
#define RESUME_BUTTON_BACKGROUND_COLOR [UIColor colorWithRed:0xff/255.0 green:0x9a/255.0 blue:0x24/255.0 alpha:1.0]
extern int lo_go_resume_finish_center_distance;

// Parameters for menu
// menu width
#define MENU_BKIMG_WIDTH (529.0/2)
#define MENU_BKIMG_HEIGHT (1136.0/2)
extern int lo_menu_width;
extern int lo_menu_header_height;
extern int lo_menu_photo_y_offset;
extern int lo_menu_photo_diameter;
extern int lo_menu_nickname_y_offset;
extern int lo_menu_nickname_height;
#define MENU_NICKNAME_FONT_COLOR [UIColor whiteColor]
#define MENU_USER_NICKNAME_FONT_SIZE (23*2*rate_pixel_to_point)

extern int lo_menu_item_size;
#define MENU_ITEM_ICON_SIZE (96/2)
#define MENU_ITEM_TITLE_FONT_SIZE (21*2*rate_pixel_to_point)

// Parameters for settings
#define SETTINGS_NICKNAME_FONT_SIZE (22*2*rate_pixel_to_point)
#define SETTINGS_CELL_TITLE_FONT_SIZE (20*2*rate_pixel_to_point)
#define SETTINGS_CELL_SUBTITLE_FONT_SIZE (16*2*rate_pixel_to_point)
extern int lo_settings_icon_x_center_offset;
extern int lo_settings_icon_y_center_offset;
extern int lo_settings_icon_size;
extern int lo_settings_table_y_offset;
extern int lo_settings_cell_switch_width;
extern int lo_settings_cell_switch_height;

// Parameters for real player
extern int lo_realplayer_topbar_width;

#endif /* defined(__Pao123__GuiParams__) */
