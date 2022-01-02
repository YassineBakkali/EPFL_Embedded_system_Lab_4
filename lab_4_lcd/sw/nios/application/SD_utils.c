/**
 * @file    SD_utils.c
 * @brief   Definition of functions to write data to SDRAM.
 * @note    Board: DE0-Nano-SoC, display on GPIO_0
 * @note    Display: TerasIC LT24 - 2.4" LCD touch module
 */

// C standard header files
#include <io.h>
#include <stdio.h>
#include <stdlib.h>

// Design header files
#include <system.h>

// Module header files
#include "SD_utils.h"
#include "LT24_utils.h"

/*===========================================================================*/
/* Module exported functions.                                                */
/*===========================================================================*/

void SD_import_image(char* path){

	FILE *file = fopen(path, "r");
	printf("Image file opened.\n");

	if (!file) {
		printf("Error: could not open file for writing.\n");
		exit(1);
	}

	// Read the first 320 x 240 pixels of the image, each being 4 bytes (32 bits per pixel)
	int read_image = fread(REG_START_ADDRESS, SDRAM_ADDR_WIDTH, NUM_PIXELS, file);

	// Write image to SDRAM
	printf("%d\n", read_image);

	fclose (file);
}


void SD_fill_range(uint32_t start_addr, uint32_t end_addr, uint16_t color) {

    if (end_addr <= END_ADDRESS) {
        uint32_t addr;
        for (addr = start_addr; addr < end_addr; addr += SDRAM_ADDR_WIDTH) {
            IOWR_32DIRECT(HPS_0_BRIDGES_BASE, addr, color);
        }
    } else {
        printf("Error: end address is outside of allowed zone: %"PRIu32" > %d.\n", end_addr, END_ADDRESS);
    }
}

void SD_fill_color(uint16_t color) {
    SD_fill_range(REG_START_ADDRESS, END_ADDRESS, color);
}

void SD_fill_rows_RGB(void) {
    SD_fill_range(REG_START_ADDRESS, REG_START_ADDRESS + BUFFER_LENGTH/3 - 1, RED);
    SD_fill_range(REG_START_ADDRESS + BUFFER_LENGTH/3, REG_START_ADDRESS + 2*BUFFER_LENGTH/3 - 1, GREEN);
    SD_fill_range(REG_START_ADDRESS + 2*BUFFER_LENGTH/3, END_ADDRESS, BLUE);
}
