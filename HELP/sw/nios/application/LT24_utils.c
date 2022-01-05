/**
 * @file    LT24_utils.c
 * @brief   Definitions of functions to control the LT24 TFT Display
 * @note    Board: DE0-Nano-SoC, display on GPIO_0
 * @note    Display: TerasIC LT24 - 2.4" LCD touch module
 */

// C standard header files
#include <io.h>
#include <stdio.h>
#include <unistd.h>

// Design header files
#include <system.h>

// Module header files
#include "LT24_utils.h"

/*===========================================================================*/
/* Module constants.                                                         */
/*===========================================================================*/

// Register addresses in Avalon Slave
#define ADDR_START_ADDRESS      (0*AS_ADDR_WIDTH ) // 000
#define ADDR_COMMAND_OR_DATA    (1*AS_ADDR_WIDTH ) // 001
#define ADDR_COMMAND_DATA       (2*AS_ADDR_WIDTH ) // 010
#define ADDR_BURST_TOT          (3*AS_ADDR_WIDTH ) // 011
#define ADDR_LCD_ON             (4*AS_ADDR_WIDTH ) // 100

/*===========================================================================*/
/* Module local functions.                                                   */
/*===========================================================================*/

/**
 * @brief                   Writes data to the LCD.
 * @param[in]   data        Data to write to LCD.
 */
void LCD_write_data(uint32_t data) {

    // Write to RegCommandData
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_COMMAND_DATA, data);
    // RegCommandOrData = 10b to write data
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_COMMAND_OR_DATA, 0x00000002);
}

/**
 * @brief                   Writes a command to the LCD.
 * @param[in]   command     Command to write to LCD.
 */
void LCD_write_command(uint32_t command) {

    // Write to RegCommandData
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_COMMAND_DATA, command);
    // RegCommandOrData = 01b to write data
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_COMMAND_OR_DATA, 0x00000001);
}

/**
 * @brief                   Turns LCD ON (hardware).
 */
void LCD_turn_on(void) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_LCD_ON, 1);
}

/**
 * @brief                   Turns LCD OFF (hardware).
 */
void LCD_turn_off(void) {
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_LCD_ON, 0);
}

/**
 * @brief                   Configures RegStartAddress and RegBurstTot registers.
 */
void LCD_write_registers(void) {

    printf("Writing to registers...\n");

    // Provide start address (RegStartAddress)
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_START_ADDRESS, REG_START_ADDRESS);
    printf("RegStartAddress = %d \n", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_START_ADDRESS));

    // Provide number of bursts per transfer (RegBurstTot)
    IOWR_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_BURST_TOT, REG_BURST_TOT);
    printf("RegBurstTot = %d \n", IORD_32DIRECT(LCD_CONTROLLER_0_BASE, ADDR_BURST_TOT));
}

/**
 * @brief                   Configures LCD parameters.
 */
void LCD_configure(void) {

    printf("Configuring LCD...\n");

    // Software Reset
    LCD_write_command(0x00000001);
    // Wait 5 ms
    usleep(5000);

    // Exit Sleep
    LCD_write_command(0x00000011);

    // Power Control B
    LCD_write_command(0x000000CF);
        LCD_write_data(0x00000000);
        LCD_write_data(0x00000081);
        LCD_write_data(0x000000C0);

    // Power On Sequence Control
    LCD_write_command(0x000000ED);
        LCD_write_data(0x00000064); // Soft StartKeep 1 frame
        LCD_write_data(0x00000003);
        LCD_write_data(0x00000012);
        LCD_write_data(0x00000081);

    // Driver Timing Control A
    LCD_write_command(0x000000E8);
        LCD_write_data(0x00000085);
        LCD_write_data(0x00000001);
        LCD_write_data(0x00000798);

    // Power Control A
    LCD_write_command(0x000000CB);
        LCD_write_data(0x00000039);
        LCD_write_data(0x0000002C);
        LCD_write_data(0x00000000);
        LCD_write_data(0x00000034);
        LCD_write_data(0x00000002);

    // Pump Ratio Control
    LCD_write_command(0x000000F7);
        LCD_write_data(0x00000020);

    // Driver Timing Control B
    LCD_write_command(0x000000EA);
        LCD_write_data(0x00000000);
        LCD_write_data(0x00000000);

    // Frame Control (In Normal Mode)
    LCD_write_command(0x000000B1);
        LCD_write_data(0x00000000);
        LCD_write_data(0x0000001B);

    // Display Function Control
    LCD_write_command(0x000000B6);
        LCD_write_data(0x0000000A);
        LCD_write_data(0x000000A2);

    // Power Control 1
    LCD_write_command(0x000000C0);
        LCD_write_data(0x00000005); // VRH[5:0]

    // Power Control 2
    LCD_write_command(0x000000C1);
        LCD_write_data(0x00000011); // SAP[2:0]; BT[3:0]

    // VCM Control 1
    LCD_write_command(0x000000C5);
        LCD_write_data(0x00000045); // 3F
        LCD_write_data(0x00000045); // 3C

    // VCM Control 2
    LCD_write_command(0x000000C7);
        LCD_write_data(0x000000A2);

    // Memory Access Control
    LCD_write_command(0x00000036);
        // BGR Order
        // Change Row Address Order
        // Exchange Row/Column
        LCD_write_data(0x000000A8);

    // Enable 3G
    LCD_write_command(0x000000F2);
        LCD_write_data(0x00000000); // 3Gamma Function Disable

    // Gamma Set
    LCD_write_command(0x00000026);
        LCD_write_data(0x00000001); // Gamma Curve Selected

    // Positive Gamma Correction, Set Gamma
    LCD_write_command(0x000000E0);
        LCD_write_data(0x0000000F);
        LCD_write_data(0x00000026);
        LCD_write_data(0x00000024);
        LCD_write_data(0x0000000B);
        LCD_write_data(0x0000000E);
        LCD_write_data(0x00000008);
        LCD_write_data(0x0000004B);
        LCD_write_data(0x000000A8);
        LCD_write_data(0x0000003B);
        LCD_write_data(0x0000000A);
        LCD_write_data(0x00000014);
        LCD_write_data(0x00000006);
        LCD_write_data(0x00000010);
        LCD_write_data(0x00000009);
        LCD_write_data(0x00000000);

    // Negative Gamma Correction, Set Gamma
    LCD_write_command(0x000000E1);
        LCD_write_data(0x00000000);
        LCD_write_data(0x0000001C);
        LCD_write_data(0x00000020);
        LCD_write_data(0x00000004);
        LCD_write_data(0x00000010);
        LCD_write_data(0x00000008);
        LCD_write_data(0x00000034);
        LCD_write_data(0x00000047);
        LCD_write_data(0x00000044);
        LCD_write_data(0x00000005);
        LCD_write_data(0x0000000B);
        LCD_write_data(0x00000009);
        LCD_write_data(0x0000002F);
        LCD_write_data(0x00000036);
        LCD_write_data(0x0000000F);

    // Column Address Set
    LCD_write_command(0x0000002A);
        // SC[15:0] = 0x0000 = 0
        LCD_write_data(0x00000000);
        LCD_write_data(0x00000000);
        // EC[15:0] = 0x013F = 319
        LCD_write_data(0x00000001);
        LCD_write_data(0x0000003F);

    // Page Address Set
    LCD_write_command(0x0000002B);
        // SP[15:0] = 0x0000 = 0
        LCD_write_data(0x00000000);
        LCD_write_data(0x00000000);
        // EP[15:0] = 0x00EF = 239
        LCD_write_data(0x00000000);
        LCD_write_data(0x000000EF);

    // COLMOD: Pixel Format Set
    LCD_write_command(0x0000003A);
        LCD_write_data(0x00000055);

    // Interface Control
    LCD_write_command(0x000000F6);
        LCD_write_data(0x00000001);
        LCD_write_data(0x00000030);
        LCD_write_data(0x00000000);

    // Display ON
    LCD_write_command(0x00000029);

    printf("LCD configuration completed.\n");
}

/*===========================================================================*/
/* Module exported functions.                                                */
/*===========================================================================*/

void LCD_display(void) {

    printf("Displaying image.\n");

    // 0x2C Display Command
    LCD_write_command(0x0000002C);
}

void LCD_init(void) {

    printf("Initializing LCD...\n");

    LCD_turn_on();
    LCD_write_registers();

    LCD_configure();

    printf("Initialization completed.\n");

}
