//SystemVerilog
`timescale 1ns/1ps
module SPI_Clock_Recovery #(
    parameter OVERSAMPLE = 8
)(
    input  wire        async_clk,
    input  wire        sdi,
    output reg         recovered_clk,
    output reg  [7:0]  data_out
);

reg  [2:0]   sample_window;
reg  [3:0]   edge_counter;
reg  [7:0]   shift_register;

// Pre-calculate half oversample for path balancing
localparam [3:0] OVERSAMPLE_HALF = OVERSAMPLE >> 1;
localparam [3:0] OVERSAMPLE_MINUS1 = OVERSAMPLE - 1;

// Initialization
initial begin
    sample_window   = 3'b000;
    edge_counter    = 4'h0;
    shift_register  = 8'h00;
    recovered_clk   = 1'b0;
    data_out        = 8'h00;
end

// Balanced sampling window update
always @(posedge async_clk) begin
    sample_window <= {sample_window[1:0], sdi};
end

// Edge detection
wire edge_detected;
assign edge_detected = sample_window[2] ^ sample_window[1];

// Balanced recovered clock and edge counter logic
reg recovered_clk_next;
reg [3:0] edge_counter_next;

always @* begin
    if (edge_detected) begin
        edge_counter_next    = OVERSAMPLE_HALF;
        recovered_clk_next   = 1'b0;
    end else if (edge_counter == OVERSAMPLE_MINUS1) begin
        edge_counter_next    = 4'h0;
        recovered_clk_next   = 1'b1;
    end else begin
        edge_counter_next    = parallel_prefix_adder_4b(edge_counter, 4'b0001, 1'b0);
        recovered_clk_next   = (edge_counter < OVERSAMPLE_HALF);
    end
end

always @(posedge async_clk) begin
    edge_counter   <= edge_counter_next;
    recovered_clk  <= recovered_clk_next;
end

// Path balanced data recovery logic
reg [7:0] shift_register_next;

always @* begin
    if (recovered_clk_next) begin
        shift_register_next = parallel_prefix_adder_8b({shift_register[6:0], sample_window[2]}, 8'b00000000, 1'b0);
    end else begin
        shift_register_next = shift_register;
    end
end

always @(posedge async_clk) begin
    shift_register <= shift_register_next;
end

// Output register
always @(posedge async_clk) begin
    data_out <= shift_register;
end

// 4-bit Parallel Prefix Adder (Kogge-Stone)
function [3:0] parallel_prefix_adder_4b;
    input [3:0] a;
    input [3:0] b;
    input       cin;
    reg   [3:0] g, p;
    reg   [3:0] c;
    begin
        g = a & b;
        p = a ^ b;
        // Stage 1
        c[0] = cin;
        c[1] = g[0] | (p[0] & c[0]);
        c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
        c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
        parallel_prefix_adder_4b = p ^ c;
    end
endfunction

// 8-bit Parallel Prefix Adder (Kogge-Stone)
function [7:0] parallel_prefix_adder_8b;
    input [7:0] a;
    input [7:0] b;
    input       cin;
    reg   [7:0] g, p;
    reg   [7:0] c;
    begin
        g = a & b;
        p = a ^ b;
        c[0] = cin;
        c[1] = g[0] | (p[0] & c[0]);
        c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
        c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
        c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
        c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
        parallel_prefix_adder_8b = p ^ c;
    end
endfunction

endmodule