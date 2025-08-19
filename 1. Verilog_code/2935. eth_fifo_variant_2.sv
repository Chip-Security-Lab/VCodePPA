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
    // Memory and pointers
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    reg [LOG2_DEPTH-1:0] rd_ptr_stage1, rd_ptr_stage2;
    reg [LOG2_DEPTH-1:0] wr_ptr_stage1, wr_ptr_stage2;
    reg [LOG2_DEPTH:0] count_stage1, count_stage2;
    
    // Pipeline control signals
    reg wr_operation_stage1, wr_operation_stage2;
    reg rd_operation_stage1, rd_operation_stage2;
    reg [WIDTH-1:0] wr_data_stage1, wr_data_stage2;
    reg [LOG2_DEPTH-1:0] rd_addr_stage1, rd_addr_stage2;
    reg [LOG2_DEPTH-1:0] wr_addr_stage1, wr_addr_stage2;
    
    // Status signals
    wire full_stage1, empty_stage1;
    reg full_stage2, empty_stage2;
    
    // Stage 1: Calculate status and next pointers
    assign full_stage1 = (count_stage1 == DEPTH);
    assign empty_stage1 = (count_stage1 == 0);
    
    wire wr_wrap_around_stage1, rd_wrap_around_stage1;
    wire [LOG2_DEPTH-1:0] next_wr_ptr_stage1, next_rd_ptr_stage1;
    wire [LOG2_DEPTH:0] next_count_stage1;
    
    // Check for wrap-around conditions
    assign wr_wrap_around_stage1 = (wr_ptr_stage1 == DEPTH-1);
    assign rd_wrap_around_stage1 = (rd_ptr_stage1 == DEPTH-1);
    
    // Determine valid operations for stage 1
    wire wr_valid_stage1 = i_wr_en && !full_stage1;
    wire rd_valid_stage1 = i_rd_en && !empty_stage1;
    
    // Calculate next pointers
    assign next_wr_ptr_stage1 = wr_wrap_around_stage1 ? {LOG2_DEPTH{1'b0}} : (wr_ptr_stage1 + 1'b1);
    assign next_rd_ptr_stage1 = rd_wrap_around_stage1 ? {LOG2_DEPTH{1'b0}} : (rd_ptr_stage1 + 1'b1);
    
    // Calculate next count based on operations
    wire [1:0] count_select_stage1 = {wr_valid_stage1, rd_valid_stage1};
    wire [LOG2_DEPTH:0] count_inc_stage1 = count_stage1 + 1'b1;
    wire [LOG2_DEPTH:0] count_dec_stage1 = count_stage1 - 1'b1;
    
    assign next_count_stage1 = (count_select_stage1 == 2'b10) ? count_inc_stage1 :
                               (count_select_stage1 == 2'b01) ? count_dec_stage1 :
                               (count_select_stage1 == 2'b11) ? count_stage1 : 
                               count_stage1;
    
    // Pipeline stage registers
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            // Reset stage 1 registers
            rd_ptr_stage1 <= {LOG2_DEPTH{1'b0}};
            wr_ptr_stage1 <= {LOG2_DEPTH{1'b0}};
            count_stage1 <= {(LOG2_DEPTH+1){1'b0}};
            wr_operation_stage1 <= 1'b0;
            rd_operation_stage1 <= 1'b0;
            wr_data_stage1 <= {WIDTH{1'b0}};
            rd_addr_stage1 <= {LOG2_DEPTH{1'b0}};
            wr_addr_stage1 <= {LOG2_DEPTH{1'b0}};
            
            // Reset stage 2 registers
            rd_ptr_stage2 <= {LOG2_DEPTH{1'b0}};
            wr_ptr_stage2 <= {LOG2_DEPTH{1'b0}};
            count_stage2 <= {(LOG2_DEPTH+1){1'b0}};
            wr_operation_stage2 <= 1'b0;
            rd_operation_stage2 <= 1'b0;
            wr_data_stage2 <= {WIDTH{1'b0}};
            rd_addr_stage2 <= {LOG2_DEPTH{1'b0}};
            wr_addr_stage2 <= {LOG2_DEPTH{1'b0}};
            full_stage2 <= 1'b0;
            empty_stage2 <= 1'b1;
        end else begin
            // Stage 1 to Stage 2 pipeline registers
            rd_ptr_stage2 <= rd_valid_stage1 ? next_rd_ptr_stage1 : rd_ptr_stage1;
            wr_ptr_stage2 <= wr_valid_stage1 ? next_wr_ptr_stage1 : wr_ptr_stage1;
            count_stage2 <= next_count_stage1;
            wr_operation_stage2 <= wr_valid_stage1;
            rd_operation_stage2 <= rd_valid_stage1;
            wr_data_stage2 <= i_data;
            rd_addr_stage2 <= rd_ptr_stage1;
            wr_addr_stage2 <= wr_ptr_stage1;
            full_stage2 <= full_stage1;
            empty_stage2 <= empty_stage1;
            
            // Update stage 1 registers for next cycle
            rd_ptr_stage1 <= rd_ptr_stage2;
            wr_ptr_stage1 <= wr_ptr_stage2;
            count_stage1 <= count_stage2;
        end
    end
    
    // Stage 2: Perform memory operations
    always @(posedge i_clk) begin
        if (wr_operation_stage2) begin
            memory[wr_addr_stage2] <= wr_data_stage2;
        end
        
        if (rd_operation_stage2) begin
            o_data <= memory[rd_addr_stage2];
        end
    end
    
    // Output status signals
    assign o_full = full_stage2;
    assign o_empty = empty_stage2;
    
endmodule