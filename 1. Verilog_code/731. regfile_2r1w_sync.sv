module regfile_2r1w_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 32
)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] rd_addr0,
    input [ADDR_WIDTH-1:0] rd_addr1,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data0,
    output reg [DATA_WIDTH-1:0] rd_data1
);
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
integer i;

always @(posedge clk) begin
    if (!rst_n) begin
        for (i=0; i<DEPTH; i=i+1) mem[i] <= 0;
    end else if (wr_en) begin
        mem[wr_addr] <= wr_data;
    end
end

always @(posedge clk) begin
    rd_data0 <= mem[rd_addr0];
    rd_data1 <= mem[rd_addr1];
end
endmodule