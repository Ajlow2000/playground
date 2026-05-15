#ifndef COMPASS_DIR_H
#define COMPASS_DIR_H

#include <stdint.h>
#include <stdbool.h>

typedef enum {
    COMPASS_NORTH   = 0,
    COMPASS_EAST    = 90,
    COMPASS_SOUTH   = 180,
    COMPASS_WEST    = 270,
    COMPASS_INVALID = 255,
} compass_dir_t;

typedef struct {
    float         latitude;
    float         longitude;
    compass_dir_t heading;
} compass_reading_t;

typedef struct {
    uint8_t is_cardinal : 1;
    uint8_t is_valid    : 1;
    uint8_t reserved    : 6;
} compass_flags_t;

typedef union {
    compass_dir_t dir;
    uint32_t      raw;
} compass_raw_u;

typedef void (*compass_reading_cb_t)(compass_reading_t reading, void *user_data);

compass_dir_t   compass_dir_from_degrees(uint32_t degrees);
bool            compass_dir_is_cardinal(compass_dir_t dir);
const char     *compass_dir_name(compass_dir_t dir);
compass_flags_t compass_flags_get(compass_dir_t dir);
void            compass_reading_process(compass_reading_t reading, compass_reading_cb_t cb, void *user_data);

#endif
