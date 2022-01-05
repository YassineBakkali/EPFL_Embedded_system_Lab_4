#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include "system.h"
#include "io.h"
#include "i2c/i2c.h"

#include "LT24_utils.h"
#include "camera_utils.h"

#include "SD_utils.h"

#include <stdio.h>

int main()
{
	i2c_dev i2c = camera_init();

    camera_capture(i2c);

    LCD_init();

	LCD_display();

  return 0;
}
