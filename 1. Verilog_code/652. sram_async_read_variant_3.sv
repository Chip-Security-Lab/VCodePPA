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

// Memory array
reg [DW-1:0] memory_array [0:(1<<AW)-1];

// Write pipeline
always @(posedge wr_clk) begin
    if (wr_en) begin
        memory_array[wr_addr] <= wr_data;
    end
end

// Read pipeline
reg [DW-1:0] read_data_reg;
reg read_valid_reg;

always @(*) begin
    if (rd_en) begin
        read_data_reg = memory_array[rd_addr];
        read_valid_reg = 1'b1;
    end else begin
        read_data_reg = {DW{1'bz}};
        read_valid_reg = 1'b0;
    end
end

// Output stage
assign rd_data = read_valid_reg ? read_data_reg : {DW{1'bz}};

endmodule