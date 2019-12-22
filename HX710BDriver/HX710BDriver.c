//
//  HX710BDriver.c
//  HX710BDriver
//
//  Created by Zilvinas Sebeika on 22/08/2018.
//  Copyright © 2018 GARAZAS. All rights reserved.
//

#include <string.h>
#include <ftdi.h>
#include "HX710BDriver.h"

// [00000001, 00000010, 00000100, 00001000, 00010000, 00100000, 01000000, 10000000]
unsigned char mask_table[] = { 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80 };

typedef int bool;
bool get_bitForPin(unsigned char byte, int idx) {
    int mask_idx = 7 - idx;
    return ( byte & mask_table[mask_idx] ) != 0x00;
}

int startReading(int *stop, void (*ptr)(struct Readings readings))
{
    int ret;
    struct ftdi_context ftdiContext;
    ftdi_init(&ftdiContext);
    unsigned char pinsStatus; // 1 byte in circumventing the read buffer
    
    printf("opening device...\n");
    ret = ftdi_usb_open(&ftdiContext,
                        0x0403,         //VENDOR
                        0x6014);        //PRODUCT (6014 stands for FT232H)
    
    if(ret < 0) {
        fprintf(stderr, "unable to open ftdi device: %d (%s)\n", ret, ftdi_get_error_string(&ftdiContext));
        return EXIT_FAILURE;
    }
    
    /* Enable bit-bang mode, where 8 UART pins (RX, TX, RTS etc.) become
     * general-purpose I/O pins.
     */
    printf("reseting...\n");
    ret = ftdi_usb_reset(&ftdiContext);
    
    printf("selecting asynchronous bit-bang mode.\n");
    ret = ftdi_set_bitmode(&ftdiContext,
                           0x0F,    /* 0x0F sets last 4 pins as outputs (for CLK) 0 0 0 0 1 1 1 1
                                       First 4 pins will be available for reading only (writing to them has no effect)
                                     */
                           0x01);   /* 0x01 - FT_BITMODE_ASYNC_BITBANG, 0x04 - FT_BITMODE_SYNC_BITBANG */
    
    /* In bit-bang mode, setting the baud rate gives a clock rate
     * 16 times higher, e.g. baud = 9600 gives 153600 bytes per second.
     */
    unsigned int baudRate = 9600;
    printf("setting bound rate to %d\n", baudRate * 16);
    ret = ftdi_set_baudrate(&ftdiContext, baudRate);
    
    printf("reading...\n");
    while (!*stop)
    {
        // Ping all sensors by setting clock pins to 0 - writing 1 byte of zeros
        unsigned char ping[1] = { 0x00 };
        ret = ftdi_write_data(&ftdiContext, ping, 1);
        
        int pin_n0 = 1;
        int pin_n1 = 1;
        int pin_n2 = 1;
        int pin_n3 = 1;
        
        // Wait till data pins for all 4 sensors becomes 0 - that means sensors are ready to be read
        while (pin_n0 || pin_n1 || pin_n2 || pin_n3) {
            ret = ftdi_read_pins(&ftdiContext, &pinsStatus);
            pin_n0 = get_bitForPin(pinsStatus, 0);
            pin_n1 = get_bitForPin(pinsStatus, 1);
            pin_n2 = get_bitForPin(pinsStatus, 2);
            pin_n3 = get_bitForPin(pinsStatus, 3);
        }
        
        // Ready to get data bit by bit
        
        // Set pulse count
        int pulse_count = 27;
                        //24 - Errors;
                        //25 - 1092081 (Slow 10sps);
                        //26 - 901875 (40sps);
                        //27 - 1091310 (42sps);
                        //28 - 2184120 (Slow 10sps);
                        //29 - 2182541 (41sps);
                        //30 - 2183801 (41sps);
                        //31 - 2182988 (41sps);
                        //32 - 2182936 (42sps);
                        //33 - 2183280 (42sps);
        
        // Array of 4 placeholders for 24 bit data from 4 sensors
        int32_t rawOutput[] = { 0, 0, 0, 0 };
        
        // Creating a pulse (turn clock pins ON and OFF imediately) - writing 2 bytes (0x0F and zero)
        unsigned char pulse[2] = { 0x0F, 0x00 };
        
        for (int i=0; i<pulse_count; i++) {
            // Execute a pulse on all CLK pins
            ret = ftdi_write_data(&ftdiContext, pulse, 2);
                        
            // Read 24 bits of data
            if (i<24) {
                // libFTDI return bits in circumventing the read buffer
                // The state for last pin comes first, then the 7th, and so on
                // So the last 4 bits (pins AD4, AD3, AD2 and AD0) will be 0 because they are used for CLK
                ret = ftdi_read_pins(&ftdiContext, &pinsStatus);
                rawOutput[0] = (rawOutput[0]<<1) | get_bitForPin(pinsStatus, 0);;
                rawOutput[1] = (rawOutput[1]<<1) | get_bitForPin(pinsStatus, 1);;
                rawOutput[2] = (rawOutput[2]<<1) | get_bitForPin(pinsStatus, 2);;
                rawOutput[3] = (rawOutput[3]<<1) | get_bitForPin(pinsStatus, 3);;
            } else {
                // Additional pulses prepares sensors for next read cycle
                // 1 - 10 samples per second
                // 2 - 40 samples but returns constant values
                // 3 - 40 samples per second
            }
        }
                
        // Container for 4 numbers converted from two's supplement (raw data)
        int32_t signed_data[] = { 0, 0, 0, 0 };
        int32_t MIN_VALUE = 0x800000; // -8388608
        int32_t MAX_VALUE = 0x7FFFFF; // +8388607
        
        for (int i=0; i<4; i++) {
            if (rawOutput[i] == MIN_VALUE) {
                // Minimum value
                signed_data[i] = -MIN_VALUE;
            } else if (rawOutput[i] == MAX_VALUE) {
                // Maximum value
                signed_data[i] = MAX_VALUE;
            } else {
                // Check the first bit
                if (rawOutput[i] & 0x800000) {
                    // If it's 1 - than we have a negative number.
                    // Invert all bits and +1 to the result
                    signed_data[i] = -((rawOutput[i] ^ 0xFFFFFF) + 1);
                } else {
                    signed_data[i] = rawOutput[i];
                }
            }
        }
        
        // printf("%d, %d, %d, %d\n", signed_data[0], signed_data[1], signed_data[2], signed_data[3]);
        struct Readings r;
        r.sensor1 = signed_data[0];
        r.sensor2 = signed_data[1];
        r.sensor3 = signed_data[2];
        r.sensor4 = signed_data[3];
        
        // Execute callback function and pass the readings
        (*ptr) (r);
    }

exit:
    /* Return chip to default (UART) mode. */
    (void)ftdi_set_bitmode(&ftdiContext, 0x00, 0x00);
    (void)ftdi_usb_close(&ftdiContext);
    return 0;
}
