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
reg [DW-1:0] rd_data_reg;

// Write operation
always @(posedge wr_clk) begin
    if (wr_en) begin
        storage[wr_addr] <= wr_data;
    end
end

// Read operation with conditional sum
always @(*) begin
    if (rd_en) begin
        rd_data_reg = storage[rd_addr];
    end else begin
        rd_data_reg = {DW{1'bz}};
    end
end

assign rd_data = rd_data_reg;

endmodule