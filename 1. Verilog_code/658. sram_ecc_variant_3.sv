//SystemVerilog
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

// Memory array declaration
reg [DW-1:0] memory_array [0:(1<<AW)-1];

// Write pipeline stage
reg [AW-1:0] wr_addr_reg;
reg [DW-1:0] wr_data_reg;
reg wr_en_reg;

always @(posedge wr_clk) begin
    wr_addr_reg <= wr_addr;
    wr_data_reg <= wr_data;
    wr_en_reg <= wr_en;
end

// Write operation
always @(posedge wr_clk) begin
    if (wr_en_reg) begin
        memory_array[wr_addr_reg] <= wr_data_reg;
    end
end

// Read pipeline stage
reg [AW-1:0] rd_addr_reg;
reg rd_en_reg;

always @(posedge rd_clk) begin
    rd_addr_reg <= rd_addr;
    rd_en_reg <= rd_en;
end

// Read operation
always @(posedge rd_clk) begin
    if (rd_en_reg) begin
        rd_data <= memory_array[rd_addr_reg];
    end
end

endmodule