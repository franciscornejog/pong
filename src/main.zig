//! raylib - classic game: pong
//!
//! Game developed by Francisco Cornejo Garcia
//!
//! This game has been created using raylib v5.6-dev and Zig 0.14.1
//!
//! Copyright (c) 2025 Francisco Cornejo Garcia (@franciscornejog)

const rl = @import("raylib");
const std = @import("std");

/// Structures
const Score = struct {
    position: rl.Vector2,
    score: u32 = 0,
    font_size: f32 = 75,
    color: rl.Color = .white,

    pub fn init(x: f32, y: f32) Score {
        return Score{
            .position = rl.Vector2{ .x = x, .y = y } 
        };
    }

    pub fn draw(self: Score) void {
        rl.drawTextEx(rl.getFontDefault() catch unreachable, rl.textFormat("%i", .{ self.score }), self.position, self.font_size, 10, self.color);
    }
};

const Player = struct {
    position: rl.Vector2,
    size: rl.Vector2,
    speed: f32 = 10,
    color: rl.Color = .white,

    pub fn init(x: f32, y: f32) Player {
        const width = 12;
        const height = 40;
        return Player{
            .position = rl.Vector2{ .x = x - width / 2, .y = y - height / 2 },
            .size = rl.Vector2{ .x = width, .y = height },
        };
    }

    pub fn draw(self: Player) void {
        rl.drawRectangleV(self.position, self.size, self.color);
    }
};

const Ball = struct {
    position: rl.Vector2,
    size: f32 = 10,
    color: rl.Color = .white,
    velocity: rl.Vector2 = rl.Vector2{ .x = 5, .y = 5 },

    pub fn init(x: f32, y: f32) Ball {
        return Ball{ .position = rl.Vector2{ .x = x, .y = y, }, };
    }

    pub fn draw(self: Ball) void {
        rl.drawCircleV(self.position, self.size, self.color);
    }
};

/// Global Variables Declaration
const screen_width: u16 = 800;
const screen_height: u16 = 450;
const line_width: u8 = 8;

var game_over: bool = false;

pub fn main() !void {
    rl.setConfigFlags(rl.ConfigFlags{ .window_highdpi = true });
    rl.initWindow(screen_width, screen_height, "Pong");
    defer rl.closeWindow();

    // if platform_web emscripten_set_main_loop(updatedrawframe, 60, 1);
    
    rl.setTargetFPS(60);

    var p1: Player = .init(100, screen_height / 2);
    var p2: Player = .init(700, screen_height / 2);

    var s1: Score = .init(190, 25);
    var s2: Score = .init(590, 25);

    var ball: Ball = .init(screen_width / 2, screen_height / 2);

    initGame();
    defer unloadGame();

    while (!rl.windowShouldClose()) {
        updateDrawFrame();

        if (rl.isKeyPressed(.space)) {
            game_over = false;
        }

        if (game_over) {
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(.black);
            rl.drawText("Press [Enter] to play again", @divExact(rl.getScreenWidth(), 2) - @divExact(rl.measureText("Press [Enter] to play again", 20), 2), @divExact(rl.getScreenHeight(), 2) - 50, 20, .white);
            continue;
        }

        if (rl.isKeyDown(.q) and p1.position.y - p1.speed >= 0) {
            p1.position.y -= p1.speed;
        }
        if (rl.isKeyDown(.w) and p1.position.y + p1.size.y + p1.speed <= screen_height) {
            p1.position.y += p1.speed;
        }

        if (rl.isKeyDown(.up) and p2.position.y - p2.speed >= 0) {
            p2.position.y -= p2.speed;
        }
        if (rl.isKeyDown(.down) and p2.position.y + p2.size.y + p2.speed <= screen_height) {
            p2.position.y += p2.speed;
        }

        if (rl.checkCollisionCircleRec(ball.position, ball.size, rl.Rectangle{ .x = p1.position.x, .y = p1.position.y, .width = p1.size.x, .height = p1.size.y }) or
            rl.checkCollisionCircleRec(ball.position, ball.size, rl.Rectangle{ .x = p2.position.x, .y = p2.position.y, .width = p2.size.x, .height = p2.size.y })) {
            ball.velocity.x = -ball.velocity.x;
        }

        if (rl.checkCollisionCircleLine(ball.position, ball.size, rl.Vector2{ .x = screen_width, .y = 0, }, rl.Vector2{ .x = screen_width, .y = screen_height })) {
            ball.position.x = screen_width / 2;
            ball.position.y = @floatFromInt(rl.getRandomValue(0, screen_height));
            ball.velocity.y = @floatFromInt(rl.getRandomValue(5, 15));
            s1.score += 1;
        }
        if (rl.checkCollisionCircleLine(ball.position, ball.size, rl.Vector2{ .x = 0, .y = 0, }, rl.Vector2{ .x = 0, .y = screen_height })) {
            ball.position.x = screen_width / 2;
            ball.position.y = @floatFromInt(rl.getRandomValue(0, screen_height));
            s2.score += 1;
        }

        if (s1.score >= 10 or s2.score >= 10) {
            game_over = true;
        }

        // ball flip direction randomly when reset
        // ball velocity change based on paddle hit

        if (rl.checkCollisionCircleLine(ball.position, ball.size, rl.Vector2{ .x = 0, .y = 0, }, rl.Vector2{ .x = screen_width, .y = 0 }) or
            rl.checkCollisionCircleLine(ball.position, ball.size, rl.Vector2{ .x = 0, .y = screen_height, }, rl.Vector2{ .x = screen_width, .y = screen_height })) {
            ball.velocity.y = -ball.velocity.y;
        }
                                   
        ball.position.x += ball.velocity.x;
        ball.position.y += ball.velocity.y;

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        p1.draw();
        p2.draw();

        s1.draw();
        s2.draw();

        ball.draw();

        const count = 20;
        for (0..count) |i| {
            const i_i32: i32 = @intCast(i);
            rl.drawRectangle(screen_width / 2 - line_width / 2, 
                (screen_height / count) * i_i32,
                line_width, screen_height / (count * 2), .white);
        }

        rl.drawText(rl.textFormat("[%i, %i]", .{ rl.getMouseX(), rl.getMouseY() }), rl.getMouseX() - 44, rl.getMouseY() - 24, 20, .white);
    }
}

fn initGame() void {
}

fn updateDrawFrame() void {

}

fn unloadGame() void {

}
