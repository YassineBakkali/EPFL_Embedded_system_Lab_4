/**
 * @file    LT24_utils.h
 * @brief   Headers of functions to control the LT24 TFT display.
 * @note    Board: DE0-Nano-SoC, display on GPIO_0
 * @note    Display: TerasIC LT24 - 2.4" LCD touch module
 */

#ifndef _LT24_UTILS_H_
#define _LT24_UTILS_H_

// C standard header files
#include <inttypes.h>

/*===========================================================================*/
/* Exported constants                                                        */
/*===========================================================================*/

// Memory and addresses widths
#define AVALON_SLAVE_WIDTH      32
#define SDRAM_WIDTH             32
#define WORD_BITS               8
#define AS_ADDR_WIDTH           (AVALON_SLAVE_WIDTH/WORD_BITS)
#define SDRAM_ADDR_WIDTH        (SDRAM_WIDTH/WORD_BITS)

// Register default values
#define REG_START_ADDRESS       HPS_0_BRIDGES_BASE // should be 0
#define REG_BURST_TOT           8

// Image dimensions in pixels
#define IMAGE_WIDTH             320
#define IMAGE_HEIGHT            240
#define NUM_PIXELS              (IMAGE_WIDTH*IMAGE_HEIGHT)

#define END_ADDRESS             (REG_START_ADDRESS + SDRAM_ADDR_WIDTH*NUM_PIXELS - 4)
#define BUFFER_LENGTH           (NUM_PIXELS * SDRAM_ADDR_WIDTH)

/*===========================================================================*/
/* External declarations.                                                    */
/*===========================================================================*/

/**
 * @brief                   Initializes the LCD.
 */
void LCD_init(void);

/**
 * @brief                   Displays SDRAM data on LCD.
 */
void LCD_display(void);

#endif /* _LT24_UTILS_H_ */
