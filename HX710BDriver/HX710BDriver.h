//
//  HX710BDriver.h
//  HX710BDriver
//
//  Created by Zilvinas Sebeika on 22/08/2018.
//  Copyright © 2018 GARAZAS. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>

struct Readings {
    int32_t sensor1;
    int32_t sensor2;
    int32_t sensor3;
    int32_t sensor4;
};

int startReading (int *stop, void (*ptr)(struct Readings readings));
