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
    // Memory declaration
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Stage registers - restructured for better timing
    reg [LOG2_DEPTH-1:0] rd_ptr, wr_ptr;
    reg [LOG2_DEPTH:0] count;
    reg wr_en_qualified, rd_en_qualified;
    reg [WIDTH-1:0] wr_data;
    
    // Pre-calculation registers - moved from later stages
    reg [LOG2_DEPTH-1:0] next_rd_ptr, next_wr_ptr;
    reg [WIDTH-1:0] read_data;
    
    // Status signals - directly derived from count
    wire full, empty;
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    
    // Output assignments
    assign o_full = full;
    assign o_empty = empty;
    
    // Next pointer calculation - moved earlier in pipeline
    always @(*) begin
        next_rd_ptr = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
        next_wr_ptr = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
    end
    
    // Qualified control signals - moved earlier
    always @(*) begin
        wr_en_qualified = i_wr_en && !full;
        rd_en_qualified = i_rd_en && !empty;
    end
    
    // Pointer and count management
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            count <= 0;
            wr_data <= 0;
        end else begin
            // Register the input data
            wr_data <= i_data;
            
            // Update write pointer
            if (wr_en_qualified) begin
                wr_ptr <= next_wr_ptr;
            end
            
            // Update read pointer
            if (rd_en_qualified) begin
                rd_ptr <= next_rd_ptr;
            end
            
            // Update count based on read/write operations
            if (wr_en_qualified && !rd_en_qualified) begin
                count <= count + 1;
            end else if (!wr_en_qualified && rd_en_qualified) begin
                count <= count - 1;
            end
            // Count remains unchanged when both operations occur or neither occurs
        end
    end
    
    // Memory access and output stage
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            read_data <= 0;
            o_data <= 0;
        end else begin
            // Write operation
            if (wr_en_qualified) begin
                memory[wr_ptr] <= wr_data;
            end
            
            // Two-stage read operation - first read from memory
            if (rd_en_qualified) begin
                read_data <= memory[rd_ptr];
            end
            
            // Second stage - output register
            o_data <= read_data;
        end
    end
endmodule