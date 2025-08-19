//SystemVerilog
module ChannelEqualizer #(parameter WIDTH=8) (
    input clk,
    input signed [WIDTH-1:0] rx_sample,
    output reg [WIDTH-1:0] eq_output
);
    // Tap register array for shift register
    reg signed [WIDTH-1:0] tap_regs [0:2];
    integer idx;

    // Register for equalizer sum
    reg signed [WIDTH+3:0] eq_sum_reg;

    // Combinational sum calculation
    wire signed [WIDTH+3:0] eq_sum_comb;

    assign eq_sum_comb = (rx_sample * (-1)) + (tap_regs[0] * 3) + (tap_regs[1] * 3) + (tap_regs[2] * (-1));

    // -------------------------------------------------------------------
    // Tap shift register update
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        tap_regs[2] <= tap_regs[1];
        tap_regs[1] <= tap_regs[0];
        tap_regs[0] <= rx_sample;
    end

    // -------------------------------------------------------------------
    // Equalizer sum register update
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        eq_sum_reg <= eq_sum_comb;
    end

    // -------------------------------------------------------------------
    // Output register update
    // -------------------------------------------------------------------
    always @(posedge clk) begin
        eq_output <= eq_sum_reg >>> 2;
    end

endmodule