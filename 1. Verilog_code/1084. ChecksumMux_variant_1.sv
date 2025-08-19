//SystemVerilog
module ChecksumMux #(parameter DW=8) (
    input clk,
    input rst_n,
    input [3:0][DW-1:0] din,
    input [1:0] sel,
    input in_valid,
    output reg [DW+3:0] out,
    output reg out_valid
);

// Stage 1: Input latch and selection
reg [DW-1:0] data_latched;
reg [1:0] sel_latched;
reg valid_latched;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_latched <= {DW{1'b0}};
        sel_latched <= 2'b00;
        valid_latched <= 1'b0;
    end else begin
        data_latched <= din[sel];
        sel_latched <= sel;
        valid_latched <= in_valid;
    end
end

// Stage 2: Checksum computation using LUT-based 4-bit subtractor
reg [DW-1:0] data_stage2;
reg [1:0] sel_stage2;
reg checksum_stage2;
reg valid_stage2;

// 4-bit subtractor LUT: 16x16 entries for all a-b
reg [3:0] lut_subtractor [0:15][0:15];

// LUT initialization
integer i, j;
initial begin
    for (i = 0; i < 16; i = i + 1) begin
        for (j = 0; j < 16; j = j + 1) begin
            lut_subtractor[i][j] = i - j;
        end
    end
end

// Helper: 4-bit LUT subtraction for checksum
function [3:0] lut_sub;
    input [3:0] a;
    input [3:0] b;
    begin
        lut_sub = lut_subtractor[a][b];
    end
endfunction

// LUT-based checksum (xor, but using LUT-based subtraction as example)
reg [3:0] checksum_in;
reg [3:0] checksum_out;
always @(*) begin
    checksum_in = data_latched[3:0];
    checksum_out = lut_sub(checksum_in, 4'b0000); // checksum as a-b with b=0 (a-0=a)
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_stage2 <= {DW{1'b0}};
        sel_stage2 <= 2'b00;
        checksum_stage2 <= 1'b0;
        valid_stage2 <= 1'b0;
    end else begin
        data_stage2 <= data_latched;
        sel_stage2 <= sel_latched;
        checksum_stage2 <= ^checksum_out;  // Use LUT-based subtraction result for checksum
        valid_stage2 <= valid_latched;
    end
end

// Stage 3: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out <= {(DW+4){1'b0}};
        out_valid <= 1'b0;
    end else begin
        out <= {checksum_stage2, data_stage2, sel_stage2};
        out_valid <= valid_stage2;
    end
end

endmodule