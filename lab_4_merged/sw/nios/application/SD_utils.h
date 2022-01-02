/**
 * @file    SD_utils.h
 * @brief   Headers of functions to write data to SDRAM.
 * @note    Board: DE0-Nano-SoC, display on GPIO_0
 * @note    Display: TerasIC LT24 - 2.4" LCD touch module
 */

#ifndef _SD_UTILS_H_
#define _SD_UTILS_H_

// C standard header files
#include <inttypes.h>

/*===========================================================================*/
/* Exported constants                                                        */
/*===========================================================================*/

// Colors in RGB565 format. One pixel per 4 addresses of SDRAM (32 bits)
// Only the [15:0] bits are used to encode a pixel
#define RED     		0x0000F800 // 0000000000000000 1111100000000000
#define GREEN   		0x000007E0 // 0000000000000000 0000011111100000
#define BLUE    		0x0000001F // 0000000000000000 0000000000011111

#define IMAGE_PATH   	"/mnt/host/img/image.bin"
/*===========================================================================*/
/* External declarations.                                                    */
/*===========================================================================*/


/**
 * @brief                   Fills the SDRAM with a RGB565 image (240H x 320W).
 * @param[in]   path        Path of image to be displayed.
 */
void SD_import_image(char* path);

/**
 * @brief                   Fills a range within the SDRAM in a certain color.
 * @param[in]   start_addr  Address of range lower bound.
 * @param[in]   end_addr    Address of range upper bound.
 * @param[in]   color       RGB565 color.
 */
void SD_fill_range(uint32_t start_addr, uint32_t end_addr, uint16_t color);

/**
 * @brief                   Fills SDRAM with specified color.
 * @param[in]   color       RGB565 color.
 */
void SD_fill_color(uint16_t color);

/**
 * @brief                   Test function. Fills rows of SDRAM with red, green and blue.
 */
void SD_fill_rows_RGB(void);

#endif /* _SD_UTILS_H_ */
