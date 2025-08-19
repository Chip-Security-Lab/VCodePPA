//SystemVerilog
module sync_majority_filter #(
    parameter WINDOW = 5,
    parameter W = WINDOW / 2 + 1  // Majority threshold
)(
    input clk, rst_n,
    input data_in,
    output reg data_out
);
    // Clock distribution network with buffered clocks
    wire clk_shift_reg;
    wire clk_counter;
    wire clk_output;
    
    // Clock buffer instantiation for load balancing
    clk_buffer shift_reg_buf (.clk_in(clk), .clk_out(clk_shift_reg));
    clk_buffer counter_buf (.clk_in(clk), .clk_out(clk_counter));
    clk_buffer output_buf (.clk_in(clk), .clk_out(clk_output));
    
    reg [WINDOW-1:0] shift_reg;
    reg [2:0] one_count;  // Count of '1's (assumes WINDOW ≤ 7)
    wire bit_leaving;
    
    // Extract the bit that's about to leave the window
    assign bit_leaving = shift_reg[WINDOW-1];
    
    // Always block for shift register management (using buffered clock)
    always @(posedge clk_shift_reg or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
        end else begin
            // Shift in new data
            shift_reg <= {shift_reg[WINDOW-2:0], data_in};
        end
    end
    
    // Always block for ones counter management (using buffered clock)
    always @(posedge clk_counter or negedge rst_n) begin
        if (!rst_n) begin
            one_count <= 0;
        end else begin
            // Update one count based on bits entering/leaving window
            one_count <= one_count + data_in - bit_leaving;
        end
    end
    
    // Always block for output decision logic (using buffered clock)
    always @(posedge clk_output or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else begin
            // Majority decision
            data_out <= (one_count >= W-1) ? 1'b1 : 1'b0;
        end
    end
endmodule

// Clock buffer module to distribute clock loads
module clk_buffer (
    input clk_in,
    output clk_out
);
    // Simple non-inverting buffer
    assign clk_out = clk_in;
    
    // Synthesis attributes to prevent optimization
    /* synthesis preserve */
    /* synthesis noprune */
endmodule