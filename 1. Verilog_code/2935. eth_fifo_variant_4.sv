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
    reg [LOG2_DEPTH-1:0] rd_ptr;
    reg [LOG2_DEPTH-1:0] wr_ptr;
    reg [LOG2_DEPTH:0] count;
    
    // Pipeline registers for critical path cutting
    reg [LOG2_DEPTH-1:0] next_rd_ptr;
    reg [LOG2_DEPTH-1:0] next_wr_ptr;
    reg [LOG2_DEPTH:0] next_count;
    reg wr_en_valid, rd_en_valid;
    
    // Status flags with pipelined logic
    assign o_full = (count == DEPTH);
    assign o_empty = (count == 0);
    
    // Calculate next pointers and count (split combinational logic)
    always @(*) begin
        // Default assignments
        next_rd_ptr = rd_ptr;
        next_wr_ptr = wr_ptr;
        next_count = count;
        wr_en_valid = i_wr_en && !o_full;
        rd_en_valid = i_rd_en && !o_empty;
        
        // Write pointer update logic
        if (wr_en_valid) begin
            next_wr_ptr = (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
        end
        
        // Read pointer update logic
        if (rd_en_valid) begin
            next_rd_ptr = (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
        end
        
        // Count update logic
        if (wr_en_valid && !rd_en_valid) begin
            next_count = count + 1;
        end else if (!wr_en_valid && rd_en_valid) begin
            next_count = count - 1;
        end else if (wr_en_valid && rd_en_valid) begin
            next_count = count; // Simultaneous read and write
        end
    end
    
    // Sequential logic with pipelined registers
    always @(posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            rd_ptr <= 0;
            wr_ptr <= 0;
            count <= 0;
        end else begin
            // Update pointers and count based on pipelined logic
            rd_ptr <= next_rd_ptr;
            wr_ptr <= next_wr_ptr;
            count <= next_count;
            
            // Memory write operation
            if (wr_en_valid) begin
                memory[wr_ptr] <= i_data;
            end
            
            // Data output 
            if (rd_en_valid) begin
                o_data <= memory[rd_ptr];
            end
        end
    end
endmodule