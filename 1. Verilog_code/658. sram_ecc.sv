module sram_dual_clock #(
    parameter DW = 16,
    parameter AW = 6
)(
    input wr_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    
    input rd_clk,
    input rd_en,
    input [AW-1:0] rd_addr,
    output reg [DW-1:0] rd_data
);
reg [DW-1:0] mem [0:(1<<AW)-1];

always @(posedge wr_clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
end

always @(posedge rd_clk) begin
    if (rd_en) rd_data <= mem[rd_addr];
end
endmodule

