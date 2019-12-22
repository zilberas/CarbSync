//
//  main.c
//  HX710BDriverTest
//
//  Created by Zilvinas Sebeika on 22/08/2018.
//  Copyright © 2018 GARAZAS. All rights reserved.
//

#import <IOKit/IOKitLib.h>
#include <stdio.h>
#include <unistd.h>
#include "HX710BDriver.h"

int sigint_received = 0;

void sigint_handler(int s)
{
    sigint_received = 1;
}

void callback(struct Readings readings) {
    printf("%d, %d, %d, %d \n", readings.sensor1, readings.sensor2, readings.sensor3, readings.sensor4);
}

int main(int argc, const char * argv[]) {
    signal(SIGINT, sigint_handler);
    startReading(&sigint_received, callback);
    
    return 0;
}
