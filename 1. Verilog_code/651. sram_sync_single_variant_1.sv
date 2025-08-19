//SystemVerilog
module sram_sync_single #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input cs,
    input we,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
wire reset = !rst_n;
wire read_en = cs & !we;
wire write_en = cs & we;

always @(posedge clk) begin
    if (reset) begin
        dout <= {DATA_WIDTH{1'b0}};
        for (int i=0; i<DEPTH; i=i+1) 
            mem[i] <= {DATA_WIDTH{1'b0}};
    end else begin
        if (read_en) begin
            dout <= mem[addr];
        end else if (write_en) begin
            dout <= mem[addr];
            mem[addr] <= din;
        end
    end
end
endmodule