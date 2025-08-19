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
    reg [DATA_WIDTH-1:0] rd_data_stage2;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Input sampling
    always @(posedge clk) begin
        if (!rst_n) begin
            addr_stage1 <= {ADDR_WIDTH{1'b0}};
            wr_data_stage1 <= {DATA_WIDTH{1'b0}};
            wr_en_stage1 <= 1'b0;
            int_status_stage1 <= {DATA_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            wr_data_stage1 <= wr_data;
            wr_en_stage1 <= wr_en;
            int_status_stage1 <= int_status;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Register update and read
    always @(posedge clk) begin
        if (!rst_n) begin
            int_reg_stage2 <= {DATA_WIDTH{1'b0}};
            rd_data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                int_reg_stage2 <= wr_en_stage1 ? wr_data_stage1 : int_status_stage1;
                rd_data_stage2 <= int_reg_stage2;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_data <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage2) begin
                rd_data <= rd_data_stage2;
            end
        end
    end

endmodule