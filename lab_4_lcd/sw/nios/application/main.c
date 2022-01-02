/**
 * @file    main.c
 * @brief   Main file. Displays an image stored in SDRAM to the LCD.
 */

// Module headers
#include "LT24_utils.h"
#include "SD_utils.h"

// C standard headers
#include <unistd.h>

/*===========================================================================*/
/* Main function.                                                            */
/*===========================================================================*/

int main(void) {

    // Fill SDRAM buffer
//    SD_fill_color(GREEN);
//    SD_fill_rows_RGB();
    SD_import_image(IMAGE_PATH);

    // Initialize LCD display
    LCD_init();

    // Once it is initialized, display the contents of SDRAM
    LCD_display();

//    usleep(1000000);
//    SD_fill_rows_RGB();
//    LCD_display();
    return 0;
}
