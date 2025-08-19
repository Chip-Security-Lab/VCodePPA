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

// Memory array declaration
reg [DW-1:0] mem [0:BANKS-1][0:(1<<AW)-1];
reg [DW-1:0] out_data;

// Write operation - handles memory updates
always @(posedge clk) begin
    for (int b = 0; b < BANKS; b++) begin
        if (bank_sel[b] & we) begin
            mem[b][addr] <= din;
        end
    end
end

// Read operation - handles data output
always @(*) begin
    out_data = {DW{1'b0}};
    for (int k = 0; k < BANKS; k++) begin
        out_data = bank_sel[k] ? mem[k][addr] : out_data;
    end
end

// Output assignment
assign dout = out_data;

endmodule