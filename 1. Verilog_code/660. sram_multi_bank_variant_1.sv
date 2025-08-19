//SystemVerilog
module sram_multi_bank #(
    parameter BANKS = 4,
    parameter AW = 4,
    parameter DW = 16
)(
    input clk,
    input [BANKS-1:0] bank_sel,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

reg [DW-1:0] mem [0:BANKS-1][0:(1<<AW)-1];
reg [DW-1:0] out_data;

// Write logic optimized
always @(posedge clk) begin
    for (int b = 0; b < BANKS; b = b + 1) begin
        if (bank_sel[b] & we) begin
            mem[b][addr] <= din;
        end
    end
end

// Read logic optimized
always @(*) begin
    out_data = {DW{1'b0}};
    for (int k = 0; k < BANKS; k = k + 1) begin
        out_data = bank_sel[k] ? (out_data | mem[k][addr]) : out_data;
    end
end

assign dout = |bank_sel ? out_data : {DW{1'b0}};

endmodule