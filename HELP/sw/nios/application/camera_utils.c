/**
 * @file    camera_utils.c
 * @brief   Definitions of functions to control the TRDB-D5M camera.
 * @note    Board: DE0-Nano-SoC, display on GPIO_1
 * @note    Camera: TerasIC TRDB-D5M
 */

// C standard header files
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

// Design header files
#include "camera_utils.h"
#include "system.h"
#include "io.h"

// Defines
#define INV_PX_CLK (1<<15)
#define DIV2_PX_CLK (1<<0)
#define COLOR_BINNING4 0x0033
#define INV_TRIG (1<<9)
#define SNAPSHOT_MODE (1<<8)
#define TRIGGER (1<<2)

/*===========================================================================*/
/* Module local functions.                                                   */
/*===========================================================================*/


/**
 * @brief                   		Writes into a register of the camera.
 * @param[in]   i2c        			i2c device structure.
 * @param[in]   register_offset     Address offset of register.
 * @param[in]   data        		Data to write.
 * @param[out]          			Indicates if the process was successful.
 */
bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

/**
 * @brief                  			Reads a register of the camera.
 * @param[in]   i2c        			i2c device structure.
 * @param[in]   register_offset     Address offset of register.
 * @param[in]   data        		Data to read.
 * @param[out]          			Indicates if the process was successful.
 */
bool trdb_d5m_read(i2c_dev *i2c, uint8_t register_offset, uint16_t *data) {
    uint8_t byte_data[2] = {0, 0};

    int success = i2c_read_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        *data = ((uint16_t) byte_data[0] << 8) + byte_data[1];
        return true;
    }
}


/*===========================================================================*/
/* Module exported functions.                                                */
/*===========================================================================*/

i2c_dev camera_init(void) {

	//Avalon configure image storage, address and length
		IOWR_32DIRECT(0x10000840, 0x00, HPS_0_BRIDGES_BASE); // address
		IOWR_32DIRECT(0x10000840, 0x04, 320*240*4); // data length

		i2c_dev i2c = i2c_inst((void *) I2C_0_BASE);
		i2c_init(&i2c, I2C_FREQ);

		bool success = true;

		//Write to registers

		//reset the camera
		success &= trdb_d5m_write(&i2c, 0x00D, 1); //start the reset
		usleep(1000);
		success &= trdb_d5m_write(&i2c, 0x00D, 0); //end the reset
		usleep(1000);

		//configure resolution
		success &= trdb_d5m_write(&i2c, 0x003, 1919); //1920 colors rows
		success &= trdb_d5m_write(&i2c, 0x004, 2559); //2560 colors columns
		success &= trdb_d5m_write(&i2c, 0x00A, INV_PX_CLK | DIV2_PX_CLK); //sample colors on rising edge and divide clock by 2
		success &= trdb_d5m_write(&i2c, 0x022, COLOR_BINNING4); //row binning by 4
		success &= trdb_d5m_write(&i2c, 0x023, COLOR_BINNING4); //column binning by 4

		//add RGB gains
		success &= trdb_d5m_write(&i2c, 0x02b, 16); //max analog green 1 gain
		success &= trdb_d5m_write(&i2c, 0x02c, 31); //blue analog gain
		success &= trdb_d5m_write(&i2c, 0x02d, 31);//red analog gain
		success &= trdb_d5m_write(&i2c, 0x02e, 16); //max analog green 2 gain

		//add RGB offset
		success &= trdb_d5m_write(&i2c, 0x060, 100);//green 1 offset
		success &= trdb_d5m_write(&i2c, 0x061, 100);//green 2 offset

		success &= trdb_d5m_write(&i2c, 0x01E, 0x4000 | INV_TRIG | SNAPSHOT_MODE); //snapshot mode and invert trigger
		printf("Snapshot mode configured \n");
	usleep(2000000); // Mandatory wait time for avoiding corrupted transfer
	return i2c;
}


void camera_capture(i2c_dev i2c){

		//start the capture
		trdb_d5m_write(&i2c, 0x00B, TRIGGER); //triggers the start of capture
		IOWR_32DIRECT(0x10000840, 0x0C,0); // stop = 0
		IOWR_32DIRECT(0x10000840, 0x08, 1); // start = 1

		int wait_t= 0;
		while(IORD_32DIRECT(0x10000840,0x14) == 0){
			usleep(1000);
			++wait_t;
		}

		printf("waited for [ms]: %d ", wait_t);

		IOWR_32DIRECT(0x10000840, 0x08, 0); // start = 0
		IOWR_32DIRECT(0x10000840, 0x0C, 1); // stop = 1

}
