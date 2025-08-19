//SystemVerilog
module uniform_rng_valid_ready (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        valid_i,
    output wire        ready_o,
    output reg  [15:0] random_o,
    output reg         valid_o,
    input  wire        ready_i
);

// Internal state registers for XORshift
reg [31:0] x_reg, y_reg, z_reg, w_reg;
// Next-state wires
reg [31:0] x_next_int, y_next_int, z_next_int, w_next_int;

// High fanout signal buffers (stage 1)
reg [31:0] x_reg_buf1, y_reg_buf1, x_next_buf1, y_next_buf1, z_next_buf1;

// High fanout signal buffers (stage 2 for x/y)
reg [31:0] x_reg_buf2, y_reg_buf2, x_next_buf2, y_next_buf2, z_next_buf2;

// Internal handshake signal
wire handshake_en;
assign handshake_en = valid_i & ready_o;

// Ready logic (always ready to accept new request if not currently asserting output valid or output valid is being accepted)
assign ready_o = (~valid_o) | (valid_o & ready_i);

//-----------------------------------------------------
// State Initialization Block
// Handles synchronous reset for all state registers
//-----------------------------------------------------
always @(posedge clk_i) begin
    if (rst_i) begin
        x_reg      <= 32'h12345678;
        y_reg      <= 32'h9ABCDEF0;
        z_reg      <= 32'h13579BDF;
        w_reg      <= 32'h2468ACE0;

        x_reg_buf1 <= 32'h12345678;
        y_reg_buf1 <= 32'h9ABCDEF0;
        x_reg_buf2 <= 32'h12345678;
        y_reg_buf2 <= 32'h9ABCDEF0;

        x_next_buf1 <= 32'h12345678;
        y_next_buf1 <= 32'h9ABCDEF0;
        z_next_buf1 <= 32'h13579BDF;
        x_next_buf2 <= 32'h12345678;
        y_next_buf2 <= 32'h9ABCDEF0;
        z_next_buf2 <= 32'h13579BDF;

        random_o   <= 16'h0000;
        valid_o    <= 1'b0;
    end else begin
        if (handshake_en) begin
            x_reg      <= x_next_int;
            y_reg      <= y_next_int;
            z_reg      <= z_next_int;
            w_reg      <= w_next_int;

            x_reg_buf1 <= x_next_int;
            y_reg_buf1 <= y_next_int;
            x_reg_buf2 <= x_reg_buf1;
            y_reg_buf2 <= y_reg_buf1;

            x_next_buf1 <= x_next_int;
            y_next_buf1 <= y_next_int;
            z_next_buf1 <= z_next_int;
            x_next_buf2 <= x_next_buf1;
            y_next_buf2 <= y_next_buf1;
            z_next_buf2 <= z_next_buf1;
        end else begin
            x_reg_buf1 <= x_reg_buf1;
            y_reg_buf1 <= y_reg_buf1;
            x_reg_buf2 <= x_reg_buf2;
            y_reg_buf2 <= y_reg_buf2;

            x_next_buf1 <= x_next_buf1;
            y_next_buf1 <= y_next_buf1;
            z_next_buf1 <= z_next_buf1;
            x_next_buf2 <= x_next_buf2;
            y_next_buf2 <= y_next_buf2;
            z_next_buf2 <= z_next_buf2;
        end

        // Output valid/data logic
        if (handshake_en) begin
            random_o <= w_next_int[15:0];
            valid_o  <= 1'b1;
        end else if (valid_o && ready_i) begin
            valid_o  <= 1'b0;
        end
    end
end

//-----------------------------------------------------
// XORshift Algorithm Block
// Computes next-state values for the PRNG registers
// Now uses buffered versions to reduce fanout
//-----------------------------------------------------
always @(*) begin
    reg [31:0] x_temp;
    if (handshake_en) begin
        // XORshift sequence for x, with buffering
        x_temp = x_reg_buf2 ^ (x_reg_buf2 << 11);
        x_temp = x_temp ^ (x_temp >> 8);
        x_temp = x_temp ^ (y_reg_buf2 ^ (y_reg_buf2 >> 19));
        x_next_int = x_temp;

        // Rotate the state, using buffered signals
        y_next_int = z_reg;
        z_next_int = w_reg;
        w_next_int = x_temp;
    end else begin
        x_next_int = x_reg;
        y_next_int = y_reg;
        z_next_int = z_reg;
        w_next_int = w_reg;
    end
end

endmodule