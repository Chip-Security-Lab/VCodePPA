module sram_async_read #(
    parameter DW = 16,
    parameter AW = 5
)(
    input wr_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input rd_en,
    input [AW-1:0] rd_addr,
    output [DW-1:0] rd_data
);
reg [DW-1:0] storage [0:(1<<AW)-1];
always @(posedge wr_clk) begin
    if (wr_en) storage[wr_addr] <= wr_data;
end
assign rd_data = rd_en ? storage[rd_addr] : {DW{1'bz}};
endmodule
