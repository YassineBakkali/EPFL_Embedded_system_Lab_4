#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include "system.h"
#include "io.h"
#include "i2c/i2c.h"

#include <stdio.h>

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz in this example (ADAPT TO YOUR DESIGN) */
#define TRDB_D5M_I2C_ADDRESS  (0xba)

#define TRDB_D5M_0_I2C_0_BASE (0x10000808)   /* i2c base address from system.h (ADAPT TO YOUR DESIGN) */

#define HPS_0_BRIDGES_BASE (0x00000000)//0x00080000            /* address_span_expander base address from system.h (ADAPT TO YOUR DESIGN) */


bool trdb_d5m_write(i2c_dev *i2c, uint8_t register_offset, uint16_t data) {
    uint8_t byte_data[2] = {(data >> 8) & 0xff, data & 0xff};

    int success = i2c_write_array(i2c, TRDB_D5M_I2C_ADDRESS, register_offset, byte_data, sizeof(byte_data));

    if (success != I2C_SUCCESS) {
        return false;
    } else {
        return true;
    }
}

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

int main(void) {


    i2c_dev i2c = i2c_inst((void *) TRDB_D5M_0_I2C_0_BASE);
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
	printf("%d ", success);

    success &= trdb_d5m_write(&i2c, 0x003, 0x077F);
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x004, 0x09FF);
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x00A, 0x8001); //success &= trdb_d5m_write(&i2c, 0x00A, 0x8000);
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x022, 0x0033);
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x023, 0x0033);
    printf("%d ", success);

    //add RGB gains
    success &= trdb_d5m_write(&i2c, 0x02b, 0x03F); // green 1
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x02c, 0x0010); //Blue
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x02d, 0x0010);//red
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x02e, 0x03F);//green 2
    printf("%d ", success);

    //add rgb shift
    success &= trdb_d5m_write(&i2c, 0x060, 100);//green 1 offset
    printf("%d ", success);
    success &= trdb_d5m_write(&i2c, 0x061, 100);//green 2 offset
    printf("%d ", success);




    success &= trdb_d5m_write(&i2c, 0x01E, 0x4300); //snapshot mode had 4106 et the end
    printf("Snapshit mode configured \n");
    usleep(2000000);
    IOWR_32DIRECT(0x10000840, 0x00, HPS_0_BRIDGES_BASE); // address
    IOWR_32DIRECT(0x10000840, 0x04, 320*240*4); // data length
    //reset camera cursor to pixel 0 by i2c

    IOWR_32DIRECT(0x10000840, 0x0C,0); // stop = 0
    success &= trdb_d5m_write(&i2c, 0x00B, 0x004);//restart sensor at position 0 and software trigger
    IOWR_32DIRECT(0x10000840, 0x08, 1); // start = 1

    int wait_t= 0;
    while(IORD_32DIRECT(0x10000840,0x14) == 0){
        usleep(10000);
        ++wait_t;

    }
    printf("waited for [ms]: %d ", wait_t);
    //usleep(wait*10000);
    IOWR_32DIRECT(0x10000840, 0x08, 0); // start = 0
    IOWR_32DIRECT(0x10000840, 0x0C, 1); // stop = 1

    int color_number = 0;
    for(int i = 0; i< 240*320; ++i){
    	color_number = IORD_32DIRECT(HPS_0_BRIDGES_BASE, 4*i);
    	fprintf(foutput, "%d %d %d ", (color_number & 0x0000f800)>>8 /*R*/,(color_number & 0x000007E0)>>3 /*G*/, (color_number & 0x0000001f)<<3/*B*/); //R
    	//fprintf(foutput, "%d %d %d ", (color_number & 0x0000f800)>>5 /*R*/,(color_number & 0x000007E0)>>0 /*G*/, (color_number & 0x0000001f)<<6/*B*/); //R
    	//fprintf(foutput, "%d ", (color_number & 0x000007E0)>>3); //G
    	//fprintf(foutput, "%d ", (color_number & 0x0000001f)<<2); //B
    	if(i%32 == 0){
    		fprintf(foutput, "\n");
    		printf("%d \n", i/32);
    	}
    }
    fclose(foutput);
    /* read from register 10, put data in readdata */
    uint16_t readdata = 0;
    success &= trdb_d5m_read(&i2c, 10, &readdata);

    if (success) {
        return EXIT_SUCCESS;
    } else {
        return EXIT_FAILURE;
    }
}
