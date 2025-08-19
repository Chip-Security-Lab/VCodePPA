//SystemVerilog
// Pipelined Top-level module: Hierarchical 8-bit Xorshift Random Number Generator
module rng_xorshift_18(
    input             clk,
    input             rst,
    input             en,
    output [7:0]      data_o,
    output            data_valid
);
    // Pipeline control signals
    wire valid_stage1, valid_stage2, valid_stage3;
    wire flush;
    wire en_stage1, en_stage2, en_stage3;

    // Pipeline data signals
    wire [7:0] state_stage1, state_stage2, state_stage3;
    wire [7:0] state_next_stage3;
    wire [7:0] state_current;

    // Flush logic (active high on reset)
    assign flush = rst;

    // Valid signal pipeline
    reg valid_reg_stage1, valid_reg_stage2, valid_reg_stage3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_reg_stage1 <= 1'b0;
            valid_reg_stage2 <= 1'b0;
            valid_reg_stage3 <= 1'b0;
        end else if (en) begin
            valid_reg_stage1 <= 1'b1;
            valid_reg_stage2 <= valid_reg_stage1;
            valid_reg_stage3 <= valid_reg_stage2;
        end else begin
            valid_reg_stage1 <= 1'b0;
            valid_reg_stage2 <= 1'b0;
            valid_reg_stage3 <= 1'b0;
        end
    end
    assign valid_stage1 = valid_reg_stage1;
    assign valid_stage2 = valid_reg_stage2;
    assign valid_stage3 = valid_reg_stage3;
    assign data_valid   = valid_stage3;

    // Enable pipeline (can be extended for ready/valid handshake)
    assign en_stage1 = en;
    assign en_stage2 = valid_stage1;
    assign en_stage3 = valid_stage2;

    // State Register (holds the latest output state)
    rng_xorshift_reg #(
        .INIT_VAL(8'hAA)
    ) u_state_reg (
        .clk    (clk),
        .rst    (rst),
        .en     (en_stage3),
        .x_next (state_next_stage3),
        .x_q    (state_current)
    );

    // Pipeline registers for xorshift stages
    // Stage 1: x_in -> x_shift_left3, temp1
    reg [7:0] x_in_stage1;
    reg [7:0] x_shift_left3_stage1;
    reg [7:0] temp1_stage1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_in_stage1         <= 8'b0;
            x_shift_left3_stage1 <= 8'b0;
            temp1_stage1        <= 8'b0;
        end else if (en_stage1) begin
            x_in_stage1         <= state_current;
            x_shift_left3_stage1 <= {state_current[4:0], 3'b000};
            temp1_stage1        <= state_current ^ {state_current[4:0], 3'b000};
        end
    end

    // Stage 2: temp1 -> x_shift_right2, temp2
    reg [7:0] temp1_stage2;
    reg [7:0] x_shift_right2_stage2;
    reg [7:0] temp2_stage2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temp1_stage2        <= 8'b0;
            x_shift_right2_stage2 <= 8'b0;
            temp2_stage2        <= 8'b0;
        end else if (en_stage2) begin
            temp1_stage2        <= temp1_stage1;
            x_shift_right2_stage2 <= {2'b00, temp1_stage1[7:2]};
            temp2_stage2        <= temp1_stage1 ^ {2'b00, temp1_stage1[7:2]};
        end
    end

    // Stage 3: temp2 -> x_shift_left1, x_out
    reg [7:0] temp2_stage3;
    reg [7:0] x_shift_left1_stage3;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            temp2_stage3        <= 8'b0;
            x_shift_left1_stage3 <= 8'b0;
        end else if (en_stage3) begin
            temp2_stage3        <= temp2_stage2;
            x_shift_left1_stage3 <= {temp2_stage2[6:0], 1'b0};
        end
    end

    assign state_next_stage3 = temp2_stage3 ^ x_shift_left1_stage3;

    assign data_o = state_current;

endmodule

// State Register Module (No change needed)
module rng_xorshift_reg #(
    parameter INIT_VAL = 8'hAA
)(
    input         clk,
    input         rst,
    input         en,
    input  [7:0]  x_next,
    output [7:0]  x_q
);
    reg [7:0] state_reg;
    always @(posedge clk) begin
        if (rst)
            state_reg <= INIT_VAL;
        else if (en)
            state_reg <= x_next;
    end
    assign x_q = state_reg;
endmodule