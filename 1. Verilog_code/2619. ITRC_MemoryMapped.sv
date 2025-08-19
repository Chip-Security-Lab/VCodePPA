module ITRC_MemoryMapped #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] wr_data,
    input wr_en,
    output reg [DATA_WIDTH-1:0] rd_data,
    input [DATA_WIDTH-1:0] int_status
);
    reg [DATA_WIDTH-1:0] int_reg;
    
    always @(posedge clk) begin
        if (!rst_n) int_reg <= 0;
        else if (wr_en) int_reg <= wr_data;
        else int_reg <= int_status;
    end
    
    always @* begin
        rd_data = int_reg;
    end
endmodule