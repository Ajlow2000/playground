const std = @import("std");

/// Color of a sticker on the cube
pub const Color = enum(u8) {
    White = 0,
    Green = 1,
    Red = 2,
    Blue = 3,
    Orange = 4,
    Yellow = 5,

    /// Convert color to its character representation
    pub fn toChar(self: Color) u8 {
        return switch (self) {
            .White => 'W',
            .Green => 'G',
            .Red => 'R',
            .Blue => 'B',
            .Orange => 'O',
            .Yellow => 'Y',
        };
    }
};

/// Represents a Rubik's cube using matrix transformations
///
/// The cube state consists of:
/// - 8 corner cubies (positions 0-7)
/// - 12 edge cubies (positions 0-11)
/// Each cubie has a position and orientation
pub const CubeState = struct {
    /// Position of each corner cubie (value i at index j means corner cubie i is in position j)
    corner_positions: [8]u8,
    /// Orientation of each corner cubie (0, 1, or 2 representing twist)
    /// 0 = correct orientation, 1 = 120° clockwise, 2 = 120° counter-clockwise
    corner_orientations: [8]u8,

    /// Position of each edge cubie (value i at index j means edge cubie i is in position j)
    edge_positions: [12]u8,
    /// Orientation of each edge cubie (0 or 1 representing flip)
    /// 0 = correct orientation, 1 = flipped
    edge_orientations: [12]u8,

    /// Creates a solved cube state
    pub fn init_solved() CubeState {
        var state = CubeState{
            .corner_positions = undefined,
            .corner_orientations = [_]u8{0} ** 8,
            .edge_positions = undefined,
            .edge_orientations = [_]u8{0} ** 12,
        };

        // Initialize positions to identity (each cubie in its home position)
        for (0..8) |i| {
            state.corner_positions[i] = @intCast(i);
        }
        for (0..12) |i| {
            state.edge_positions[i] = @intCast(i);
        }

        return state;
    }

    /// Checks if the cube is in solved state
    pub fn is_solved(self: *const CubeState) bool {
        // Check corners
        for (0..8) |i| {
            if (self.corner_positions[i] != i or self.corner_orientations[i] != 0) {
                return false;
            }
        }
        // Check edges
        for (0..12) |i| {
            if (self.edge_positions[i] != i or self.edge_orientations[i] != 0) {
                return false;
            }
        }
        return true;
    }

    /// Checks if two cube states are equal
    pub fn equals(self: *const CubeState, other: *const CubeState) bool {
        for (0..8) |i| {
            if (self.corner_positions[i] != other.corner_positions[i] or
                self.corner_orientations[i] != other.corner_orientations[i]) {
                return false;
            }
        }
        for (0..12) |i| {
            if (self.edge_positions[i] != other.edge_positions[i] or
                self.edge_orientations[i] != other.edge_orientations[i]) {
                return false;
            }
        }
        return true;
    }

    /// Print a visual representation of the cube
    pub fn print(self: *const CubeState, writer: anytype) !void {
        // Convert to face representation
        const faces = self.to_faces();

        // Print in unfolded cube format:
        //       UUU
        //       UUU
        //       UUU
        // LLL FFF RRR BBB
        // LLL FFF RRR BBB
        // LLL FFF RRR BBB
        //       DDD
        //       DDD
        //       DDD

        // Top face (U)
        for (0..3) |row| {
            try writer.writeAll("      ");
            for (0..3) |col| {
                try writer.writeByte(faces[0][row * 3 + col].toChar());
            }
            try writer.writeByte('\n');
        }

        // Middle row (L, F, R, B)
        for (0..3) |row| {
            for (0..4) |face_idx| {
                const face = face_idx + 1; // Faces 1-4 (L, F, R, B)
                for (0..3) |col| {
                    try writer.writeByte(faces[face][row * 3 + col].toChar());
                }
                try writer.writeByte(' ');
            }
            try writer.writeByte('\n');
        }

        // Bottom face (D)
        for (0..3) |row| {
            try writer.writeAll("      ");
            for (0..3) |col| {
                try writer.writeByte(faces[5][row * 3 + col].toChar());
            }
            try writer.writeByte('\n');
        }
    }

    /// Convert cubie representation to face representation
    /// Returns 6 faces, each with 9 stickers
    /// Faces: 0=U, 1=L, 2=F, 3=R, 4=B, 5=D
    fn to_faces(self: *const CubeState) [6][9]Color {
        var faces = [_][9]Color{[_]Color{Color.White} ** 9} ** 6;

        // Center stickers (fixed)
        faces[0][4] = Color.White;
        faces[1][4] = Color.Orange;
        faces[2][4] = Color.Green;
        faces[3][4] = Color.Red;
        faces[4][4] = Color.Blue;
        faces[5][4] = Color.Yellow;

        // Map corners to face stickers
        // Corner positions and their 3 stickers (face, position_on_face, color)
        const corner_map = [_][3][3]u8{
            // Corner 0: URF
            .{ .{ 0, 8, @intFromEnum(Color.White) }, .{ 3, 6, @intFromEnum(Color.Red) }, .{ 2, 2, @intFromEnum(Color.Green) } },
            // Corner 1: UFL
            .{ .{ 0, 6, @intFromEnum(Color.White) }, .{ 2, 0, @intFromEnum(Color.Green) }, .{ 1, 8, @intFromEnum(Color.Orange) } },
            // Corner 2: ULB
            .{ .{ 0, 0, @intFromEnum(Color.White) }, .{ 1, 2, @intFromEnum(Color.Orange) }, .{ 4, 2, @intFromEnum(Color.Blue) } },
            // Corner 3: UBR
            .{ .{ 0, 2, @intFromEnum(Color.White) }, .{ 4, 0, @intFromEnum(Color.Blue) }, .{ 3, 8, @intFromEnum(Color.Red) } },
            // Corner 4: DFR
            .{ .{ 5, 2, @intFromEnum(Color.Yellow) }, .{ 2, 8, @intFromEnum(Color.Green) }, .{ 3, 0, @intFromEnum(Color.Red) } },
            // Corner 5: DLF
            .{ .{ 5, 0, @intFromEnum(Color.Yellow) }, .{ 1, 6, @intFromEnum(Color.Orange) }, .{ 2, 6, @intFromEnum(Color.Green) } },
            // Corner 6: DBL
            .{ .{ 5, 6, @intFromEnum(Color.Yellow) }, .{ 4, 8, @intFromEnum(Color.Blue) }, .{ 1, 0, @intFromEnum(Color.Orange) } },
            // Corner 7: DRB
            .{ .{ 5, 8, @intFromEnum(Color.Yellow) }, .{ 3, 2, @intFromEnum(Color.Red) }, .{ 4, 6, @intFromEnum(Color.Blue) } },
        };

        for (0..8) |pos| {
            const cubie = self.corner_positions[pos];
            const orientation = self.corner_orientations[pos];
            for (0..3) |i| {
                const sticker_idx = (i + orientation) % 3;
                const face = corner_map[pos][i][0];
                const face_pos = corner_map[pos][i][1];
                const color_u8 = corner_map[cubie][sticker_idx][2];
                faces[face][face_pos] = @enumFromInt(color_u8);
            }
        }

        // Map edges to face stickers
        const edge_map = [_][2][3]u8{
            // Edge 0: UR
            .{ .{ 0, 5, @intFromEnum(Color.White) }, .{ 3, 7, @intFromEnum(Color.Red) } },
            // Edge 1: UF
            .{ .{ 0, 7, @intFromEnum(Color.White) }, .{ 2, 1, @intFromEnum(Color.Green) } },
            // Edge 2: UL
            .{ .{ 0, 3, @intFromEnum(Color.White) }, .{ 1, 5, @intFromEnum(Color.Orange) } },
            // Edge 3: UB
            .{ .{ 0, 1, @intFromEnum(Color.White) }, .{ 4, 1, @intFromEnum(Color.Blue) } },
            // Edge 4: DR
            .{ .{ 5, 5, @intFromEnum(Color.Yellow) }, .{ 3, 1, @intFromEnum(Color.Red) } },
            // Edge 5: DF
            .{ .{ 5, 1, @intFromEnum(Color.Yellow) }, .{ 2, 7, @intFromEnum(Color.Green) } },
            // Edge 6: DL
            .{ .{ 5, 3, @intFromEnum(Color.Yellow) }, .{ 1, 3, @intFromEnum(Color.Orange) } },
            // Edge 7: DB
            .{ .{ 5, 7, @intFromEnum(Color.Yellow) }, .{ 4, 7, @intFromEnum(Color.Blue) } },
            // Edge 8: FR
            .{ .{ 2, 5, @intFromEnum(Color.Green) }, .{ 3, 3, @intFromEnum(Color.Red) } },
            // Edge 9: FL
            .{ .{ 2, 3, @intFromEnum(Color.Green) }, .{ 1, 7, @intFromEnum(Color.Orange) } },
            // Edge 10: BL
            .{ .{ 4, 5, @intFromEnum(Color.Blue) }, .{ 1, 1, @intFromEnum(Color.Orange) } },
            // Edge 11: BR
            .{ .{ 4, 3, @intFromEnum(Color.Blue) }, .{ 3, 5, @intFromEnum(Color.Red) } },
        };

        for (0..12) |pos| {
            const cubie = self.edge_positions[pos];
            const orientation = self.edge_orientations[pos];
            for (0..2) |i| {
                const sticker_idx = (i + orientation) % 2;
                const face = edge_map[pos][i][0];
                const face_pos = edge_map[pos][i][1];
                const color_u8 = edge_map[cubie][sticker_idx][2];
                faces[face][face_pos] = @enumFromInt(color_u8);
            }
        }

        return faces;
    }
};

/// Represents a move transformation as permutations and orientation changes
/// This is our "matrix" representation - it acts like a transformation matrix
pub const MoveTransform = struct {
    /// Permutation of corner positions (where each corner goes)
    corner_permutation: [8]u8,
    /// How the orientation changes for each corner after the move
    corner_orientation_change: [8]u8,

    /// Permutation of edge positions (where each edge goes)
    edge_permutation: [12]u8,
    /// How the orientation changes for each edge after the move
    edge_orientation_change: [12]u8,

    /// Creates an identity transform (no movement)
    pub fn identity() MoveTransform {
        var transform = MoveTransform{
            .corner_permutation = undefined,
            .corner_orientation_change = [_]u8{0} ** 8,
            .edge_permutation = undefined,
            .edge_orientation_change = [_]u8{0} ** 12,
        };

        for (0..8) |i| {
            transform.corner_permutation[i] = @intCast(i);
        }
        for (0..12) |i| {
            transform.edge_permutation[i] = @intCast(i);
        }

        return transform;
    }

    /// Apply this transformation to a cube state (matrix multiplication analog)
    /// This is equivalent to multiplying the state vector by the transformation matrix
    pub fn apply(self: *const MoveTransform, state: *const CubeState) CubeState {
        var new_state = CubeState{
            .corner_positions = undefined,
            .corner_orientations = undefined,
            .edge_positions = undefined,
            .edge_orientations = undefined,
        };

        // Apply corner permutation and orientation changes
        for (0..8) |i| {
            const new_pos = self.corner_permutation[i];
            new_state.corner_positions[new_pos] = state.corner_positions[i];
            new_state.corner_orientations[new_pos] =
                @intCast((state.corner_orientations[i] + self.corner_orientation_change[i]) % 3);
        }

        // Apply edge permutation and orientation changes
        for (0..12) |i| {
            const new_pos = self.edge_permutation[i];
            new_state.edge_positions[new_pos] = state.edge_positions[i];
            new_state.edge_orientations[new_pos] =
                @intCast((state.edge_orientations[i] + self.edge_orientation_change[i]) % 2);
        }

        return new_state;
    }

    /// Compose two transformations (matrix multiplication)
    /// Returns a new transform equivalent to applying 'first' then 'second'
    pub fn compose(first: *const MoveTransform, second: *const MoveTransform) MoveTransform {
        var result = MoveTransform{
            .corner_permutation = undefined,
            .corner_orientation_change = undefined,
            .edge_permutation = undefined,
            .edge_orientation_change = undefined,
        };

        // Compose corner transformations
        for (0..8) |i| {
            const intermediate_pos = first.corner_permutation[i];
            result.corner_permutation[i] = second.corner_permutation[intermediate_pos];
            result.corner_orientation_change[i] =
                @intCast((first.corner_orientation_change[i] +
                         second.corner_orientation_change[intermediate_pos]) % 3);
        }

        // Compose edge transformations
        for (0..12) |i| {
            const intermediate_pos = first.edge_permutation[i];
            result.edge_permutation[i] = second.edge_permutation[intermediate_pos];
            result.edge_orientation_change[i] =
                @intCast((first.edge_orientation_change[i] +
                         second.edge_orientation_change[intermediate_pos]) % 2);
        }

        return result;
    }

    /// Compute the inverse transformation (matrix inverse)
    pub fn inverse(self: *const MoveTransform) MoveTransform {
        var inv = MoveTransform{
            .corner_permutation = undefined,
            .corner_orientation_change = undefined,
            .edge_permutation = undefined,
            .edge_orientation_change = undefined,
        };

        // Invert corner permutation
        for (0..8) |i| {
            const target_pos = self.corner_permutation[i];
            inv.corner_permutation[target_pos] = @intCast(i);
            // Inverse orientation change: if we added k, inverse adds (3-k) % 3
            inv.corner_orientation_change[target_pos] =
                @intCast((3 - self.corner_orientation_change[i]) % 3);
        }

        // Invert edge permutation
        for (0..12) |i| {
            const target_pos = self.edge_permutation[i];
            inv.edge_permutation[target_pos] = @intCast(i);
            // Inverse orientation change: if we added k, inverse adds (2-k) % 2 = k (since it's mod 2)
            inv.edge_orientation_change[target_pos] = self.edge_orientation_change[i];
        }

        return inv;
    }
};

// ============================================================================
// CUBE GEOMETRY AND MOVE DEFINITIONS
// ============================================================================
//
// Corner numbering (looking at the cube with white on top, green in front):
//   0: URF (Up-Right-Front)
//   1: UFL (Up-Front-Left)
//   2: ULB (Up-Left-Back)
//   3: UBR (Up-Back-Right)
//   4: DFR (Down-Front-Right)
//   5: DLF (Down-Left-Front)
//   6: DBL (Down-Back-Left)
//   7: DRB (Down-Right-Back)
//
// Edge numbering:
//   0: UR (Up-Right)
//   1: UF (Up-Front)
//   2: UL (Up-Left)
//   3: UB (Up-Back)
//   4: DR (Down-Right)
//   5: DF (Down-Front)
//   6: DL (Down-Left)
//   7: DB (Down-Back)
//   8: FR (Front-Right)
//   9: FL (Front-Left)
//  10: BL (Back-Left)
//  11: BR (Back-Right)

/// Right face clockwise 90° turn
pub fn move_R() MoveTransform {
    return MoveTransform{
        // Corner cycle: URF -> UBR -> DRB -> DFR -> URF
        // Positions: 0 -> 3 -> 7 -> 4 -> 0
        .corner_permutation = [8]u8{ 3, 1, 2, 7, 0, 5, 6, 4 },
        // Corners twist when moving between U/D and F/B faces
        .corner_orientation_change = [8]u8{ 2, 0, 0, 1, 1, 0, 0, 2 },

        // Edge cycle: UR -> BR -> DR -> FR -> UR
        // Positions: 0 -> 11 -> 4 -> 8 -> 0
        .edge_permutation = [12]u8{ 11, 1, 2, 3, 8, 5, 6, 7, 0, 9, 10, 4 },
        // Edges don't flip on R moves (they stay in R layer)
        .edge_orientation_change = [12]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };
}

/// Left face clockwise 90° turn
pub fn move_L() MoveTransform {
    return MoveTransform{
        // Corner cycle: UFL -> ULB -> DBL -> DLF -> UFL
        // Positions: 1 -> 2 -> 6 -> 5 -> 1
        .corner_permutation = [8]u8{ 0, 2, 6, 3, 4, 1, 5, 7 },
        .corner_orientation_change = [8]u8{ 0, 1, 2, 0, 0, 2, 1, 0 },

        // Edge cycle: UL -> BL -> DL -> FL -> UL
        // Positions: 2 -> 10 -> 6 -> 9 -> 2
        .edge_permutation = [12]u8{ 0, 1, 10, 3, 4, 5, 9, 7, 8, 2, 6, 11 },
        .edge_orientation_change = [12]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };
}

/// Up face clockwise 90° turn
pub fn move_U() MoveTransform {
    return MoveTransform{
        // Corner cycle: URF -> UFL -> ULB -> UBR -> URF
        // Positions: 0 -> 1 -> 2 -> 3 -> 0
        .corner_permutation = [8]u8{ 1, 2, 3, 0, 4, 5, 6, 7 },
        // No twist on U moves (all corners stay in U layer)
        .corner_orientation_change = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 },

        // Edge cycle: UR -> UF -> UL -> UB -> UR
        // Positions: 0 -> 1 -> 2 -> 3 -> 0
        .edge_permutation = [12]u8{ 1, 2, 3, 0, 4, 5, 6, 7, 8, 9, 10, 11 },
        .edge_orientation_change = [12]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };
}

/// Down face clockwise 90° turn
pub fn move_D() MoveTransform {
    return MoveTransform{
        // Corner cycle: DFR -> DLF -> DBL -> DRB -> DFR
        // Positions: 4 -> 5 -> 6 -> 7 -> 4
        .corner_permutation = [8]u8{ 0, 1, 2, 3, 5, 6, 7, 4 },
        .corner_orientation_change = [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 },

        // Edge cycle: DR -> DF -> DL -> DB -> DR
        // Positions: 4 -> 5 -> 6 -> 7 -> 4
        .edge_permutation = [12]u8{ 0, 1, 2, 3, 5, 6, 7, 4, 8, 9, 10, 11 },
        .edge_orientation_change = [12]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    };
}

/// Front face clockwise 90° turn
pub fn move_F() MoveTransform {
    return MoveTransform{
        // Corner cycle: URF -> DFR -> DLF -> UFL -> URF
        // Positions: 0 -> 4 -> 5 -> 1 -> 0
        .corner_permutation = [8]u8{ 4, 0, 2, 3, 5, 1, 6, 7 },
        .corner_orientation_change = [8]u8{ 1, 2, 0, 0, 2, 1, 0, 0 },

        // Edge cycle: UF -> FR -> DF -> FL -> UF
        // Positions: 1 -> 8 -> 5 -> 9 -> 1
        .edge_permutation = [12]u8{ 0, 8, 2, 3, 4, 9, 6, 7, 5, 1, 10, 11 },
        // F moves flip edges between U/D and F faces
        .edge_orientation_change = [12]u8{ 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0 },
    };
}

/// Back face clockwise 90° turn
pub fn move_B() MoveTransform {
    return MoveTransform{
        // Corner cycle: UBR -> ULB -> DBL -> DRB -> UBR
        // Positions: 3 -> 2 -> 6 -> 7 -> 3
        .corner_permutation = [8]u8{ 0, 1, 6, 2, 4, 5, 7, 3 },
        .corner_orientation_change = [8]u8{ 0, 0, 1, 2, 0, 0, 2, 1 },

        // Edge cycle: UB -> BL -> DB -> BR -> UB
        // Positions: 3 -> 10 -> 7 -> 11 -> 3
        .edge_permutation = [12]u8{ 0, 1, 2, 10, 4, 5, 6, 11, 8, 9, 7, 3 },
        .edge_orientation_change = [12]u8{ 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1 },
    };
}

// Tests
test "solved cube is solved" {
    const cube = CubeState.init_solved();
    try std.testing.expect(cube.is_solved());
}

test "identity transform does nothing" {
    const cube = CubeState.init_solved();
    const identity = MoveTransform.identity();
    const result = identity.apply(&cube);
    try std.testing.expect(result.is_solved());
    try std.testing.expect(result.equals(&cube));
}

test "R move and its inverse" {
    const cube = CubeState.init_solved();
    const R = move_R();
    const R_inv = R.inverse();

    const after_R = R.apply(&cube);
    try std.testing.expect(!after_R.is_solved()); // Should not be solved

    const after_R_inv = R_inv.apply(&after_R);
    try std.testing.expect(after_R_inv.is_solved()); // Should be solved again
}

test "R4 returns to solved" {
    const cube = CubeState.init_solved();
    const R = move_R();

    var current = cube;
    for (0..4) |_| {
        current = R.apply(&current);
    }

    try std.testing.expect(current.is_solved());
}

test "move composition" {
    const cube = CubeState.init_solved();
    const R = move_R();
    const U = move_U();

    // Apply R then U separately
    const after_R = R.apply(&cube);
    const after_RU_separate = U.apply(&after_R);

    // Apply composed transformation
    const RU = MoveTransform.compose(&R, &U);
    const after_RU_composed = RU.apply(&cube);

    try std.testing.expect(after_RU_composed.equals(&after_RU_separate));
}

test "sexy move returns to solved after 6 iterations" {
    // Sexy move: R U R' U'
    const cube = CubeState.init_solved();
    const R = move_R();
    const R_inv = R.inverse();
    const U = move_U();
    const U_inv = U.inverse();

    // Compose the sexy move
    const RU = MoveTransform.compose(&R, &U);
    const RUR_inv = MoveTransform.compose(&RU, &R_inv);
    const sexy = MoveTransform.compose(&RUR_inv, &U_inv);

    var current = cube;
    for (0..6) |_| {
        current = sexy.apply(&current);
    }

    try std.testing.expect(current.is_solved());
}

test "all basic moves have period 4" {
    // Each 90° face turn should return to solved after 4 iterations
    const cube = CubeState.init_solved();
    const moves = [_]MoveTransform{
        move_R(), move_L(), move_U(),
        move_D(), move_F(), move_B(),
    };

    for (moves) |m| {
        var current = cube;
        for (0..4) |_| {
            current = m.apply(&current);
        }
        try std.testing.expect(current.is_solved());
    }
}

test "all moves have valid inverses" {
    const cube = CubeState.init_solved();
    const moves = [_]MoveTransform{
        move_R(), move_L(), move_U(),
        move_D(), move_F(), move_B(),
    };

    for (moves) |m| {
        const m_inv = m.inverse();
        const after_m = m.apply(&cube);
        const after_m_inv = m_inv.apply(&after_m);
        try std.testing.expect(after_m_inv.is_solved());
    }
}

test "double inverse equals identity" {
    const cube = CubeState.init_solved();
    const R = move_R();

    // R followed by R' twice should equal R
    const R_inv = R.inverse();
    const R_inv_inv = R_inv.inverse();

    const result1 = R.apply(&cube);
    const result2 = R_inv_inv.apply(&cube);

    try std.testing.expect(result1.equals(&result2));
}

test "move composition is associative" {
    const cube = CubeState.init_solved();
    const R = move_R();
    const U = move_U();
    const F = move_F();

    // Test (R · U) · F = R · (U · F)
    const RU = MoveTransform.compose(&R, &U);
    const RU_F = MoveTransform.compose(&RU, &F);

    const UF = MoveTransform.compose(&U, &F);
    const R_UF = MoveTransform.compose(&R, &UF);

    const result1 = RU_F.apply(&cube);
    const result2 = R_UF.apply(&cube);

    try std.testing.expect(result1.equals(&result2));
}

test "superflip sequence" {
    // The superflip is a famous position where all edges are flipped
    // but in their correct positions. It requires a long sequence.
    // Let's test a simpler commutator: [R, U] = R U R' U'
    const cube = CubeState.init_solved();
    const R = move_R();
    const U = move_U();

    // Apply commutator [R, U]
    var state = cube;
    state = R.apply(&state);
    state = U.apply(&state);
    state = R.inverse().apply(&state);
    state = U.inverse().apply(&state);

    // Commutator should not be identity (corners should be permuted)
    try std.testing.expect(!state.is_solved());

    // But it should have specific properties (3-cycle of corners)
    // Let's verify by applying it multiple times
    var test_state = cube;
    for (0..3) |_| {
        test_state = R.apply(&test_state);
        test_state = U.apply(&test_state);
        test_state = R.inverse().apply(&test_state);
        test_state = U.inverse().apply(&test_state);
    }
    // Should not be solved yet
    try std.testing.expect(!test_state.is_solved());
}

test "R U sequence has finite order" {
    // R U R U R U ... should eventually return to solved
    const cube = CubeState.init_solved();
    const R = move_R();
    const U = move_U();
    const RU = MoveTransform.compose(&R, &U);

    var current = cube;
    var found_cycle = false;

    // Test up to 105 iterations (known period of RU)
    for (0..105) |i| {
        current = RU.apply(&current);
        if (current.is_solved() and i > 0) {
            found_cycle = true;
            break;
        }
    }

    try std.testing.expect(found_cycle);
}

test "T-perm (corner swap)" {
    // T-perm: R U R' U' R' F R2 U' R' U' R U R' F'
    const cube = CubeState.init_solved();
    const R = move_R();
    const U = move_U();
    const F = move_F();

    var state = cube;
    state = R.apply(&state);
    state = U.apply(&state);
    state = R.inverse().apply(&state);
    state = U.inverse().apply(&state);
    state = R.inverse().apply(&state);
    state = F.apply(&state);
    state = R.apply(&state);
    state = R.apply(&state);
    state = U.inverse().apply(&state);
    state = R.inverse().apply(&state);
    state = U.inverse().apply(&state);
    state = R.apply(&state);
    state = U.apply(&state);
    state = R.inverse().apply(&state);
    state = F.inverse().apply(&state);

    // T-perm is not identity
    try std.testing.expect(!state.is_solved());

    // But applying it twice should return to solved
    var state2 = state;
    state2 = R.apply(&state2);
    state2 = U.apply(&state2);
    state2 = R.inverse().apply(&state2);
    state2 = U.inverse().apply(&state2);
    state2 = R.inverse().apply(&state2);
    state2 = F.apply(&state2);
    state2 = R.apply(&state2);
    state2 = R.apply(&state2);
    state2 = U.inverse().apply(&state2);
    state2 = R.inverse().apply(&state2);
    state2 = U.inverse().apply(&state2);
    state2 = R.apply(&state2);
    state2 = U.apply(&state2);
    state2 = R.inverse().apply(&state2);
    state2 = F.inverse().apply(&state2);

    try std.testing.expect(state2.is_solved());
}
