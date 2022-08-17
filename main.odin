package main

import "core:fmt"
import "core:os"
import "core:bufio"
import "core:math/rand"

WIDTH : u32 : 800
HEIGHT : u32 : 600

BRIGHT_RED     : [3]u8 : {251, 73, 52}
BRIGHT_GREEN   : [3]u8 : {184, 187, 38}
BRIGHT_YELLOW  : [3]u8 : {250, 189, 47}
BRIGHT_BLUE    : [3]u8 : {131, 165, 152}
BRIGHT_PURPLE  : [3]u8 : {211, 134, 155}
BRIGHT_AQUA    : [3]u8 : {142, 192, 124}
BRIGHT_ORANGE  : [3]u8 : {254, 128, 25}
BACKGROUND_COLOR : [3]u8 : {40, 40, 40}

PALETTE : [][3]u8 = {
    BRIGHT_RED,   
    BRIGHT_GREEN, 
    BRIGHT_YELLOW,
    BRIGHT_BLUE,  
    BRIGHT_PURPLE,
    BRIGHT_AQUA,
    BRIGHT_ORANGE,
    BACKGROUND_COLOR,
}

PALETTE_COUNT :: size_of(PALETTE) / size_of(PALETTE[0])

SEEDS_COUNT :: 10
SEED_MARKER_RADIUS :: 5
SEED_MARKER_COLOR : [3]u8 : {255, 255, 255}

Point :: struct {
    x, y : int,
}

image : [HEIGHT][WIDTH][3]u8;
seeds : [SEEDS_COUNT]Point;

fill_image :: proc(color: [3]u8) 
{
    for y : u32 = 0; y < HEIGHT; y += 1 {
        for x : u32 = 0; x < WIDTH; x += 1 {
            image[y][x] = color;
        } 
    }
}

generate_random_seeds :: proc() 
{
    ran := rand.create(1)
    for i:= 0; i < SEEDS_COUNT; i+=1{
        seeds[i].x = cast(int)(rand.uint32(&ran) % WIDTH)
        seeds[i].y = cast(int)(rand.uint32(&ran) % HEIGHT)
    }
}

render_seed_markers :: proc() 
{
    for i := 0; i < SEEDS_COUNT; i+=1 {
        fill_circle(seeds[i].x, seeds[i].y, SEED_MARKER_RADIUS, SEED_MARKER_COLOR)
    }
}

fill_circle :: proc(cx: int, cy: int, radius: int, color: [3]u8) 
{
    x0 := cx - radius
    y0 := cy - radius
    x1 := cx + radius
    y1 := cy + radius


    for x := x0; x <= x1; x+=1 {
        if 0 <= x && x < cast(int)WIDTH {
            for y := y0; y <= y1; y+=1 {
                if 0 <= y && y < cast(int)HEIGHT {
                    if sqr_dist(cx, cy, x, y) <= radius*radius {
                        image[y][x] = color
                    }
                }
            }
        }
    }
}

save_image_as_ppm :: proc(file_path:string)  
{
    file_handler, err := os.open(file_path, os.O_CREATE)
    if err != 0 {
        fmt.println("There was a problem opening the file : Error Code : ", err)
        os.exit(0)
    }
    fmt.println("open")
    defer os.close(file_handler)

    fmt.fprintf(file_handler, "P6\n%d %d 255\n", WIDTH, HEIGHT)
    for y : u32 = 0; y < HEIGHT; y += 1 {
        for x : u32 = 0; x < WIDTH; x += 1 {
            pixel := image[y][x]
            bytes := []u8{
                pixel[0],
                pixel[1],
                pixel[2],
            };
            
            os.write(file_handler, bytes);
        } 
    }
}

sqr_dist :: proc(x1: int, y1: int, x2: int, y2: int) -> int {
    dx := x1 - x2;
    dy := y1 - y2;

    return dx*dx + dy*dy
}

render_voronoid :: proc()
{
    for y := 0; y < cast(int)HEIGHT; y += 1 {
        for x := 0; x < cast(int)WIDTH; x += 1 {
            j := 0;
            for i := 1; i < SEEDS_COUNT; i += 1 {
                if sqr_dist(seeds[i].x, seeds[i].y, x, y) < sqr_dist(seeds[j].x, seeds[j].y, x, y) {
                    j = i;
                }
            }

            image[y][x] = PALETTE[j % PALETTE_COUNT];
        }
    }
}

main :: proc() 
{
    fill_image(BACKGROUND_COLOR)
    generate_random_seeds()
    render_voronoid()
    render_seed_markers()
    save_image_as_ppm("output.ppm")
}
