#include "compass_dir.h"

compass_dir_t compass_dir_from_degrees(uint32_t degrees) {
    uint32_t n = degrees % 360;
    if (n < 45 || n >= 315) return COMPASS_NORTH;
    if (n < 135)            return COMPASS_EAST;
    if (n < 225)            return COMPASS_SOUTH;
    return COMPASS_WEST;
}

bool compass_dir_is_cardinal(compass_dir_t dir) {
    return dir == COMPASS_NORTH || dir == COMPASS_EAST ||
           dir == COMPASS_SOUTH || dir == COMPASS_WEST;
}

const char *compass_dir_name(compass_dir_t dir) {
    switch (dir) {
        case COMPASS_NORTH: return "North";
        case COMPASS_EAST:  return "East";
        case COMPASS_SOUTH: return "South";
        case COMPASS_WEST:  return "West";
        default:            return "Invalid";
    }
}

compass_flags_t compass_flags_get(compass_dir_t dir) {
    compass_flags_t f = {0};
    f.is_valid    = (dir != COMPASS_INVALID) ? 1 : 0;
    f.is_cardinal = compass_dir_is_cardinal(dir) ? 1 : 0;
    return f;
}

void compass_reading_process(compass_reading_t reading, compass_reading_cb_t cb, void *user_data) {
    if (cb) cb(reading, user_data);
}
