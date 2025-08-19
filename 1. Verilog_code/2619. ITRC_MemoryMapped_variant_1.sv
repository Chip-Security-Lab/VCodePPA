//SystemVerilog
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

    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [DATA_WIDTH-1:0] wr_data_stage1;
    reg wr_en_stage1;
    reg [DATA_WIDTH-1:0] int_status_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_WIDTH-1:0] int_reg_stage2;
    
    // Pipeline stage 1 - optimized with parallel assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {addr_stage1, wr_data_stage1, wr_en_stage1, int_status_stage1} <= 0;
        end else begin
            {addr_stage1, wr_data_stage1, wr_en_stage1, int_status_stage1} <= {addr, wr_data, wr_en, int_status};
        end
    end
    
    // Pipeline stage 2 - optimized with ternary operator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_reg_stage2 <= 0;
        end else begin
            int_reg_stage2 <= wr_en_stage1 ? wr_data_stage1 : int_status_stage1;
        end
    end
    
    // Output stage - direct assignment
    assign rd_data = int_reg_stage2;

endmodule