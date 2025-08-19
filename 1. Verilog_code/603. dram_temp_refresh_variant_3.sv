//SystemVerilog
module dram_temp_refresh #(
    parameter BASE_CYCLES = 7800,
    parameter TEMP_COEFF = 50
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);
    reg [31:0] counter;
    wire [31:0] threshold;
    wire [31:0] next_counter;
    wire counter_overflow;
    
    // Buffer registers for high fanout signals
    reg [7:0] temp_buf;
    reg [31:0] next_counter_buf;
    reg overflow_buf;
    
    // First stage: Buffer temperature input
    always @(posedge clk) begin
        temp_buf <= temperature;
    end
    
    // Optimized threshold calculation using shift and add
    assign threshold = BASE_CYCLES + ({temp_buf, 5'b0} + {temp_buf, 3'b0} + {temp_buf, 1'b0});
    
    // Optimized counter increment and comparison
    assign next_counter = counter + 1'b1;
    
    // Second stage: Buffer next_counter
    always @(posedge clk) begin
        next_counter_buf <= next_counter;
    end
    
    // Third stage: Buffer overflow signal
    always @(posedge clk) begin
        overflow_buf <= (next_counter_buf >= threshold);
    end
    
    // Final stage: Update counter and refresh request
    always @(posedge clk) begin
        counter <= overflow_buf ? 32'd0 : next_counter_buf;
        refresh_req <= overflow_buf;
    end
endmodule