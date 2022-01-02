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

/**
 * @brief               			Configures address and data length registers.
 * @param[in]   i2c        			i2c device structure.
 */
void camera_write_registers(i2c_dev i2c){

	IOWR_32DIRECT(0x10000840, 0x00, HPS_0_BRIDGES_BASE); // address
	IOWR_32DIRECT(0x10000840, 0x04, 320*240*4); // data length
	//reset camera cursor to pixel 0 by i2c

	IOWR_32DIRECT(0x10000840, 0x0C,0); // stop = 0
	trdb_d5m_write(&i2c, 0x00B, 0x004);//restart sensor at position 0 and software trigger
}


/*===========================================================================*/
/* Module exported functions.                                                */
/*===========================================================================*/


i2c_dev camera_init(void) {

	i2c_dev i2c = i2c_inst((void *) I2C_0_BASE);
	i2c_init(&i2c, I2C_FREQ);

	bool success = true;

	//Write to registers
	//reset register
	success &= trdb_d5m_write(&i2c, 0x00D, 0x001);
	usleep(1000);

	success &= trdb_d5m_write(&i2c, 0x00D, 0x000);
	usleep(1000);
	//register values

	//random thing
	success &= trdb_d5m_write(&i2c, 0x009, 10000);

	success &= trdb_d5m_write(&i2c, 0x003, 0x077F);
	success &= trdb_d5m_write(&i2c, 0x004, 0x09FF);
	success &= trdb_d5m_write(&i2c, 0x00A, 0x8001); //success &= trdb_d5m_write(&i2c, 0x00A, 0x8000);
	success &= trdb_d5m_write(&i2c, 0x022, 0x0033);
	success &= trdb_d5m_write(&i2c, 0x023, 0x0033);

	//add RGB gains
	success &= trdb_d5m_write(&i2c, 0x02b, 0x03F); // green 1
	success &= trdb_d5m_write(&i2c, 0x02c, 0x0010); //Blue
	success &= trdb_d5m_write(&i2c, 0x02d, 0x0010);//red
	success &= trdb_d5m_write(&i2c, 0x02e, 0x03F);//green 2

	//add rgb shift
	success &= trdb_d5m_write(&i2c, 0x060, 100);//green 1 offset
	success &= trdb_d5m_write(&i2c, 0x061, 100);//green 2 offset

	success &= trdb_d5m_write(&i2c, 0x01E, 0x4300); //snapshot mode had 4106 et the end
	printf("Snapshot mode configured \n");
	usleep(2000000);
	return i2c;
}


void camera_capture(i2c_dev i2c){

		camera_write_registers(i2c);

		IOWR_32DIRECT(0x10000840, 0x08, 1); // start = 1

		int wait_t= 0;
		while(IORD_32DIRECT(0x10000840,0x14) == 0){
			usleep(10000);
			++wait_t;
		}

		printf("waited for [ms]: %d ", wait_t);

		IOWR_32DIRECT(0x10000840, 0x08, 0); // start = 0
		IOWR_32DIRECT(0x10000840, 0x0C, 1); // stop = 1

}
