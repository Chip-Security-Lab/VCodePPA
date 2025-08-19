//SystemVerilog
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
reg [AW-1:0] rd_addr_reg;
reg rd_en_reg;
reg [DW-1:0] rd_data_reg;

// Write logic
always @(posedge wr_clk) begin
    if (wr_en) storage[wr_addr] <= wr_data;
end

// Read address and enable register
always @(posedge wr_clk) begin
    rd_addr_reg <= rd_addr;
    rd_en_reg <= rd_en;
end

// Read data register
always @(posedge wr_clk) begin
    rd_data_reg <= rd_en_reg ? storage[rd_addr_reg] : {DW{1'bz}};
end

// Output assignment
assign rd_data = rd_data_reg;

endmodule