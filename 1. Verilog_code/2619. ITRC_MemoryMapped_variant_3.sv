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
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [DATA_WIDTH-1:0] wr_data_stage2;
    reg wr_en_stage2;
    reg [DATA_WIDTH-1:0] int_status_stage2;
    
    // Pipeline stage 3 registers
    reg [DATA_WIDTH-1:0] int_reg_stage3;
    reg [DATA_WIDTH-1:0] rd_data_stage3;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Stage 1: Input sampling
    always @(posedge clk) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            wr_data_stage1 <= 0;
            wr_en_stage1 <= 0;
            int_status_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            addr_stage1 <= addr;
            wr_data_stage1 <= wr_data;
            wr_en_stage1 <= wr_en;
            int_status_stage1 <= int_status;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Data preparation
    always @(posedge clk) begin
        if (!rst_n) begin
            addr_stage2 <= 0;
            wr_data_stage2 <= 0;
            wr_en_stage2 <= 0;
            int_status_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            addr_stage2 <= addr_stage1;
            wr_data_stage2 <= wr_data_stage1;
            wr_en_stage2 <= wr_en_stage1;
            int_status_stage2 <= int_status_stage1;
            valid_stage2 <= 1;
        end
    end
    
    // Stage 3: Register update and read
    always @(posedge clk) begin
        if (!rst_n) begin
            int_reg_stage3 <= 0;
            rd_data_stage3 <= 0;
            valid_stage3 <= 0;
        end else if (valid_stage2) begin
            if (wr_en_stage2) 
                int_reg_stage3 <= wr_data_stage2;
            else 
                int_reg_stage3 <= int_status_stage2;
                
            rd_data_stage3 <= int_reg_stage3;
            valid_stage3 <= 1;
        end
    end
    
    // Output assignment
    always @* begin
        rd_data = valid_stage3 ? rd_data_stage3 : 0;
    end
    
endmodule