//SystemVerilog
module ring_divider (
    input  wire       clk_in,  // System input clock
    input  wire       rst_n,   // Active low reset signal
    output wire       clk_out  // Output divided clock
);
    // Main ring counter for clock division
    reg [4:0] ring_counter;
    
    // Buffered copies of ring counter to reduce fanout
    reg [4:0] ring_counter_buf1;
    reg [4:0] ring_counter_buf2;
    
    // Pipeline registers to improve timing
    reg       clk_out_reg;
    
    // Ring counter shift operation with reset control
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize with a single '1' bit to start the ring oscillation
            ring_counter <= 5'b00001;
        end else begin
            // Rotate the counter bits - shifting right with wrap-around
            ring_counter <= {ring_counter[0], ring_counter[4:1]};
        end
    end
    
    // First level buffering of ring counter to reduce fanout load
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            ring_counter_buf1 <= 5'b00001;
        end else begin
            ring_counter_buf1 <= ring_counter;
        end
    end
    
    // Second level buffering for balanced load distribution
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            ring_counter_buf2 <= 5'b00001;
        end else begin
            ring_counter_buf2 <= ring_counter;
        end
    end
    
    // Output clock generation stage with registered output
    // Using the buffered copy of ring counter to reduce fanout
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out_reg <= 1'b0;
        end else begin
            clk_out_reg <= ring_counter_buf1[0];
        end
    end
    
    // Final output assignment
    assign clk_out = clk_out_reg;
    
endmodule