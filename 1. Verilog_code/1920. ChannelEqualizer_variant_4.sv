//SystemVerilog
module ChannelEqualizer #(parameter WIDTH=8) (
    input clk,
    input signed [WIDTH-1:0] rx_sample,
    output reg [WIDTH-1:0] eq_output
);
    // Tap registers
    reg signed [WIDTH-1:0] tap_reg_0, tap_reg_1, tap_reg_2, tap_reg_3, tap_reg_4;
    // First tap buffer
    reg signed [WIDTH-1:0] tap_buf1_0, tap_buf1_1, tap_buf1_2, tap_buf1_3, tap_buf1_4;
    // Second tap buffer
    reg signed [WIDTH-1:0] tap_buf2_0, tap_buf2_1, tap_buf2_2, tap_buf2_3, tap_buf2_4;

    // Equalizer sum pipeline registers
    reg signed [WIDTH+3:0] eq_sum_buf1;
    reg signed [WIDTH+3:0] eq_sum_buf2;

    // Tap shift register chain
    always @(posedge clk) begin
        tap_reg_4 <= tap_reg_3;
        tap_reg_3 <= tap_reg_2;
        tap_reg_2 <= tap_reg_1;
        tap_reg_1 <= tap_reg_0;
        tap_reg_0 <= rx_sample;
    end

    // First tap buffer update
    always @(posedge clk) begin
        tap_buf1_0 <= tap_reg_0;
        tap_buf1_1 <= tap_reg_1;
        tap_buf1_2 <= tap_reg_2;
        tap_buf1_3 <= tap_reg_3;
        tap_buf1_4 <= tap_reg_4;
    end

    // Second tap buffer update
    always @(posedge clk) begin
        tap_buf2_0 <= tap_buf1_0;
        tap_buf2_1 <= tap_buf1_1;
        tap_buf2_2 <= tap_buf1_2;
        tap_buf2_3 <= tap_buf1_3;
        tap_buf2_4 <= tap_buf1_4;
    end

    // Compute equalizer sum
    wire signed [WIDTH+3:0] eq_sum_wire;
    assign eq_sum_wire = (tap_buf2_0 * (-1)) + (tap_buf2_1 * 3) + (tap_buf2_2 * 3) + (tap_buf2_3 * (-1));

    // Equalizer sum pipeline stage 1
    always @(posedge clk) begin
        eq_sum_buf1 <= eq_sum_wire;
    end

    // Equalizer sum pipeline stage 2
    always @(posedge clk) begin
        eq_sum_buf2 <= eq_sum_buf1;
    end

    // Output assignment
    always @(posedge clk) begin
        eq_output <= eq_sum_buf2 >>> 2;
    end

endmodule