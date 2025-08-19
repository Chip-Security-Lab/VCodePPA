module dual_clock_regfile #(
    parameter DW = 48,
    parameter AW = 5
)(
    input wr_clk,
    input rd_clk,
    input wr_en,
    input [AW-1:0] wr_addr,
    input [DW-1:0] wr_data,
    input [AW-1:0] rd_addr,
    output [DW-1:0] rd_data
);
reg [DW-1:0] mem [0:(1<<AW)-1];
reg [DW-1:0] sync_reg;

always @(posedge wr_clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
end

always @(posedge rd_clk) begin
    sync_reg <= mem[rd_addr];
end

assign rd_data = sync_reg;
endmodule