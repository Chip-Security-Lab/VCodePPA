//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module ring_counter_valid_ready (
    input wire clk,
    input wire rst_n,
    input wire valid,  // Indicates data valid
    input wire ready,  // Indicates downstream ready
    output reg [3:0] ring_pattern
);

    reg valid_reg;
    reg ready_reg;
    wire handshake_complete;
    reg [3:0] next_pattern_reg;
    
    // Register input signals to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            ready_reg <= 1'b0;
        end
        else begin
            valid_reg <= valid;
            ready_reg <= ready;
        end
    end

    // Pre-compute the next pattern
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            next_pattern_reg <= 4'b0010; // Pre-shifted initialization value
        else
            next_pattern_reg <= {ring_pattern[2:0], ring_pattern[3]}; // Shift left
    end
    
    // Detect handshake completion - moved closer to inputs
    assign handshake_complete = valid_reg && ready_reg;

    // Update ring pattern - simplified logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ring_pattern <= 4'b0001; // Initialize to a one-hot pattern
        else if (!valid_reg)
            ring_pattern <= 4'b0000; // When valid is low, output all zeros
        else if (handshake_complete)
            ring_pattern <= next_pattern_reg; // Use pre-computed pattern
        else
            ring_pattern <= ring_pattern; // Hold current value
    end

endmodule