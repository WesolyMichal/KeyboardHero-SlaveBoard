/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */

package vga_pkg;

    // Parameters for VGA Display 800 x 600 @ 60fps using a 40 MHz clock;
    localparam HOR_PIXELS = 800;
    localparam VER_PIXELS = 600;
   
    localparam HOR_FRONT_PORCH  = 40;
    localparam HOR_SYNC_TIME    = 128;
    localparam HOR_BACK_PORCH   = 88;
    localparam HOR_BLANK_START = 800;
    localparam HOR_BLANK_TIME = 256;

    localparam VER_TOTAL_TIME   = 628;
    localparam VER_FRONT_PORCH  = 1;
    localparam VER_SYNC_TIME    = 4;
    localparam VER_BACK_PORCH   = 23;
    localparam VER_BLANK_START = 600;
    localparam VER_BLANK_TIME = 28;

    localparam HOR_SYNC_START   = HOR_PIXELS + HOR_FRONT_PORCH;
    localparam HOR_SYNC_END     = HOR_SYNC_START + HOR_SYNC_TIME;
    localparam HOR_TOTAL_TIME = HOR_PIXELS + HOR_FRONT_PORCH + HOR_SYNC_TIME + HOR_BACK_PORCH;
    localparam VER_SYNC_START   = VER_PIXELS + VER_FRONT_PORCH;
    localparam VER_SYNC_END     = VER_SYNC_START + VER_SYNC_TIME;

    // Add VGA timing parameters here and refer to them in other modules.

endpackage
