//SystemVerilog
module eth_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16,
    parameter LOG2_DEPTH = 4
) (
    input wire i_clk,
    input wire i_rst,
    input wire i_wr_en,
    input wire i_rd_en,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data,
    output wire o_full,
    output wire o_empty
);
    // Memory and pointer declarations
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    reg [LOG2_DEPTH-1:0] rd_ptr_stage1, rd_ptr_stage2;
    reg [LOG2_DEPTH-1:0] wr_ptr_stage1, wr_ptr_stage2;
    reg [LOG2_DEPTH:0] count_stage1, count_stage2;
    
    // Pipeline stage registers
    reg wr_valid_stage1, wr_valid_stage2;
    reg rd_valid_stage1, rd_valid_stage2;
    reg [WIDTH-1:0] wr_data_stage1, wr_data_stage2;
    reg [WIDTH-1:0] rd_data_stage1, rd_data_stage2;
    
    // Status signals
    wire full_stage1, empty_stage1;
    reg full_stage2, empty_stage2;
    
    // First stage status calculation
    assign full_stage1 = (count_stage1 == DEPTH);
    assign empty_stage1 = (count_stage1 == 0);
    
    // Output assignments
    assign o_full = full_stage2;
    assign o_empty = empty_stage2;
    
    // Pipeline Stage 1: Request processing and pointer calculation
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rd_ptr_stage1 <= 0;
            wr_ptr_stage1 <= 0;
            count_stage1 <= 0;
            wr_valid_stage1 <= 0;
            rd_valid_stage1 <= 0;
            wr_data_stage1 <= 0;
        end else begin
            // Write request processing
            wr_valid_stage1 <= i_wr_en && !full_stage1;
            if (i_wr_en && !full_stage1) begin
                wr_data_stage1 <= i_data;
                wr_ptr_stage1 <= (wr_ptr_stage1 == DEPTH-1) ? 0 : wr_ptr_stage1 + 1;
            end
            
            // Read request processing
            rd_valid_stage1 <= i_rd_en && !empty_stage1;
            if (i_rd_en && !empty_stage1) begin
                rd_ptr_stage1 <= (rd_ptr_stage1 == DEPTH-1) ? 0 : rd_ptr_stage1 + 1;
            end
            
            // Count calculation (with priority to write if both happen)
            if (i_wr_en && !full_stage1 && i_rd_en && !empty_stage1)
                count_stage1 <= count_stage1;
            else if (i_wr_en && !full_stage1)
                count_stage1 <= count_stage1 + 1;
            else if (i_rd_en && !empty_stage1)
                count_stage1 <= count_stage1 - 1;
        end
    end
    
    // Pipeline Stage 2: Memory access and output generation
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rd_ptr_stage2 <= 0;
            wr_ptr_stage2 <= 0;
            count_stage2 <= 0;
            wr_valid_stage2 <= 0;
            rd_valid_stage2 <= 0;
            wr_data_stage2 <= 0;
            rd_data_stage2 <= 0;
            full_stage2 <= 0;
            empty_stage2 <= 1;
            o_data <= 0;
        end else begin
            // Move control signals to stage 2
            rd_ptr_stage2 <= rd_ptr_stage1;
            wr_ptr_stage2 <= wr_ptr_stage1;
            count_stage2 <= count_stage1;
            wr_valid_stage2 <= wr_valid_stage1;
            rd_valid_stage2 <= rd_valid_stage1;
            wr_data_stage2 <= wr_data_stage1;
            full_stage2 <= full_stage1;
            empty_stage2 <= empty_stage1;
            
            // Perform memory operations
            if (wr_valid_stage2)
                memory[wr_ptr_stage2] <= wr_data_stage2;
                
            if (rd_valid_stage2)
                o_data <= memory[rd_ptr_stage2];
        end
    end
endmodule