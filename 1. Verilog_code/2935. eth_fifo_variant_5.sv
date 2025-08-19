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
    output wire [WIDTH-1:0] o_data,
    output wire o_full,
    output wire o_empty
);
    // Memory array
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // Pointers and counter
    reg [LOG2_DEPTH-1:0] rd_ptr, rd_ptr_next;
    reg [LOG2_DEPTH-1:0] wr_ptr, wr_ptr_next;
    reg [LOG2_DEPTH:0] count, count_next;
    
    // Output registers
    reg [WIDTH-1:0] o_data_reg;
    
    // Optimized full/empty flags using direct comparisons
    assign o_full = (count == DEPTH);
    assign o_empty = (count == 0);
    assign o_data = o_data_reg;
    
    // Optimized read and write conditions
    wire can_write = i_wr_en && (count < DEPTH);
    wire can_read = i_rd_en && (count > 0);
    
    // Next pointer calculations with optimized comparisons
    wire [LOG2_DEPTH-1:0] rd_ptr_plus1 = (rd_ptr == DEPTH-1) ? {LOG2_DEPTH{1'b0}} : rd_ptr + 1'b1;
    wire [LOG2_DEPTH-1:0] wr_ptr_plus1 = (wr_ptr == DEPTH-1) ? {LOG2_DEPTH{1'b0}} : wr_ptr + 1'b1;
    
    // Combinational logic block with optimized comparisons
    always @(*) begin
        // Default assignments
        rd_ptr_next = rd_ptr;
        wr_ptr_next = wr_ptr;
        count_next = count;
        
        // Optimized state updates using pre-calculated conditions
        case ({can_write, can_read})
            2'b10: begin  // Write only
                wr_ptr_next = wr_ptr_plus1;
                count_next = count + 1'b1;
            end
            2'b01: begin  // Read only
                rd_ptr_next = rd_ptr_plus1;
                count_next = count - 1'b1;
            end
            2'b11: begin  // Both read and write
                rd_ptr_next = rd_ptr_plus1;
                wr_ptr_next = wr_ptr_plus1;
                // Count remains unchanged
            end
            default: begin // No operation
                // Keep existing values
            end
        endcase
    end
    
    // Optimized read data logic
    always @(posedge i_clk) begin
        if (can_read) begin
            o_data_reg <= memory[rd_ptr];
        end
    end
    
    // Sequential logic block for state updates
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            // Reset all registers
            rd_ptr <= {LOG2_DEPTH{1'b0}};
            wr_ptr <= {LOG2_DEPTH{1'b0}};
            count <= {(LOG2_DEPTH+1){1'b0}};
            o_data_reg <= {WIDTH{1'b0}};
        end
        else begin
            // Update registers with next state values
            rd_ptr <= rd_ptr_next;
            wr_ptr <= wr_ptr_next;
            count <= count_next;
        end
    end
    
    // Memory write operation with gated clock enable
    always @(posedge i_clk) begin
        if (can_write) begin
            memory[wr_ptr] <= i_data;
        end
    end
    
endmodule