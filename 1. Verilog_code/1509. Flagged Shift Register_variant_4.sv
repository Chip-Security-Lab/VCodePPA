//SystemVerilog
// IEEE 1364-2005
module flagged_shift_reg #(parameter DEPTH = 8) (
    input wire clk, rst, push, pop,
    input wire data_in,
    output wire data_out,
    output wire empty, full
);
    // Main data storage
    reg [DEPTH-1:0] fifo;
    
    // Count tracking register
    reg [$clog2(DEPTH):0] count;
    
    // Pre-registered input signals
    reg push_reg, pop_reg, data_in_reg;
    
    // Pre-compute control conditions
    wire push_allowed, pop_allowed;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk) begin
        if (rst) begin
            push_reg <= 0;
            pop_reg <= 0;
            data_in_reg <= 0;
        end else begin
            push_reg <= push;
            pop_reg <= pop;
            data_in_reg <= data_in;
        end
    end
    
    // Pre-compute control conditions after input registration
    assign push_allowed = push_reg && !(count == DEPTH);
    assign pop_allowed = pop_reg && !(count == 0);
    
    // Main FIFO logic with simplified single-stage pipeline
    always @(posedge clk) begin
        if (rst) begin
            fifo <= 0;
            count <= 0;
        end else begin
            if (push_allowed && !pop_allowed) begin
                fifo <= {fifo[DEPTH-2:0], data_in_reg};
                count <= count + 1;
            end else if (!push_allowed && pop_allowed) begin
                fifo <= {1'b0, fifo[DEPTH-1:1]};
                count <= count - 1;
            end else if (push_allowed && pop_allowed) begin
                // Both push and pop - shift in new data while shifting out
                fifo <= {fifo[DEPTH-2:0], data_in_reg};
                // Count stays the same
            end
            // If neither push nor pop, keep state unchanged
        end
    end
    
    // Output assignments directly from the FIFO register
    assign data_out = fifo[DEPTH-1];
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
endmodule