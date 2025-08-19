//SystemVerilog
module dual_port_async_rst #(parameter ADDR_WIDTH=4, DATA_WIDTH=8)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] addr_wr, addr_rd,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout
);
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0];

    always @(posedge clk or posedge rst) begin
        dout <= rst ? {DATA_WIDTH{1'b0}} : mem[addr_rd];
        mem[addr_wr] <= (wr_en & ~rst) ? din : mem[addr_wr];
    end
endmodule