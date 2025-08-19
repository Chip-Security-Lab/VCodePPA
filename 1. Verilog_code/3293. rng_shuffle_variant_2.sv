//SystemVerilog
// Top-level module for RNG shuffle - Pipelined Version
module rng_shuffle_13(
    input             clk,
    input             rst,
    input             en,
    output [7:0]      rand_o,
    output            valid_o
);

    // Stage 1: RNG State Register
    wire [7:0] state_value_stage1;
    reg        valid_stage1;

    rng_state_reg_pipelined #(
        .INIT_VALUE(8'hC3)
    ) u_state_reg_pipelined (
        .clk        (clk),
        .rst        (rst),
        .en         (en),
        .next_value (shuffle_result_stage3),
        .rand_value (state_value_stage1)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_stage1 <= 1'b0;
        else if (en)
            valid_stage1 <= 1'b1;
        else
            valid_stage1 <= 1'b0;
    end

    // Stage 2: Bit Shuffle
    reg [7:0] shuffled_bits_stage2;
    reg       valid_stage2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shuffled_bits_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            shuffled_bits_stage2 <= {state_value_stage1[3:0], state_value_stage1[7:4]};
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: XOR Mix
    reg [7:0] shuffle_result_stage3;
    reg       valid_stage3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shuffle_result_stage3 <= 8'd0;
            valid_stage3 <= 1'b0;
        end else begin
            shuffle_result_stage3 <= shuffled_bits_stage2 ^ 8'h96;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Output Register (optional for timing balance)
    reg [7:0] rand_o_stage4;
    reg       valid_stage4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rand_o_stage4 <= 8'd0;
            valid_stage4 <= 1'b0;
        end else begin
            rand_o_stage4 <= state_value_stage1;
            valid_stage4 <= valid_stage1;
        end
    end

    assign rand_o = rand_o_stage4;
    assign valid_o = valid_stage4;

endmodule

// -----------------------------------------------------------------------------
// Module: rng_state_reg_pipelined
// Description: 8-bit register with synchronous reset and enable for pipelined design
// Holds the RNG state value
// -----------------------------------------------------------------------------
module rng_state_reg_pipelined #(
    parameter INIT_VALUE = 8'h00
)(
    input             clk,
    input             rst,
    input             en,
    input  [7:0]      next_value,
    output reg [7:0]  rand_value
);
    always @(posedge clk) begin
        if (rst)
            rand_value <= INIT_VALUE;
        else if (en)
            rand_value <= next_value;
    end
endmodule