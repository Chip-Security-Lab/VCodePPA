//SystemVerilog
module UART_PreambleDetect #(
    parameter PREAMBLE = 8'hAA,
    parameter PRE_LEN  = 4
)(
    input wire clk,
    input wire rxd,
    input wire rx_done,
    output reg rx_enable,
    output reg preamble_valid
);

reg [7:0] preamble_shift;
reg [3:0] match_counter;

// Kogge-Stone Adder for 4-bit match_counter increment
function [3:0] kogge_stone_add4;
    input [3:0] a;
    input [3:0] b;
    reg [3:0] p, g;
    reg [3:0] c;
    begin
        // Stage 0: Propagate and Generate
        p = a ^ b;
        g = a & b;
        
        // Stage 1
        c[0] = 0;
        c[1] = g[0];
        c[2] = g[1] | (p[1] & g[0]);
        c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
        
        kogge_stone_add4 = p ^ c;
    end
endfunction

always @(posedge clk) begin
    preamble_shift <= {preamble_shift[6:0], rxd};

    if (preamble_shift == PREAMBLE) begin
        match_counter <= kogge_stone_add4(match_counter, 4'b0001);
    end else begin
        match_counter <= 4'd0;
    end

    preamble_valid <= (match_counter >= PRE_LEN);
end

always @(posedge clk) begin
    if (preamble_valid)
        rx_enable <= 1'b1;
    else if (rx_done)
        rx_enable <= 1'b0;
end

endmodule