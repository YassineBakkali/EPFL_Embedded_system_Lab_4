/**
 * @file  : camera_utils.h
 * @brief : Headers of functions to control the TRDB-D5M camera.
 * @note    Board: DE0-Nano-SoC, display on GPIO_1
 * @note    Camera: TerasIC TRDB-D5M
 */


#ifndef CAMERA_UTILS_H_
#define CAMERA_UTILS_H_

// C standard header files
#include <stdbool.h>
#include "i2c/i2c.h"

/*===========================================================================*/
/* Exported constants                                                        */
/*===========================================================================*/

#define I2C_FREQ              (50000000) /* Clock frequency driving the i2c core: 50 MHz in this example*/

#define TRDB_D5M_I2C_ADDRESS  (0xba) /* Camera's I2C address*/

/*===========================================================================*/
/* External declarations.                                                    */
/*===========================================================================*/

/**
 * @brief							Initializes the camera.
 * @param[out]   i2c        		i2c device structure.
 */
i2c_dev camera_init(void);

/**
 * @brief               			Captures image and stores it in the SDRAM.
 * @param[in]   i2c        			i2c device structure.
 */
void camera_capture(i2c_dev i2c);

#endif /* CAMERA_UTILS_H_ */
