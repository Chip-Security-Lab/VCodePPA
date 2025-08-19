//SystemVerilog
module basic_ring_counter #(parameter WIDTH = 4)(
    input wire clk,
    output wire [WIDTH-1:0] count
);
    // Internal registers
    reg [WIDTH-1:0] count_internal;
    reg [WIDTH-1:0] count_buffer1;
    reg [WIDTH-1:0] count_buffer2;
    
    // Initialize with one-hot encoding
    initial count_internal = {{(WIDTH-1){1'b0}}, 1'b1};
    
    // Main counter logic using two's complement addition instead of direct rotation
    // For ring counter, we can use addition with proper masking to implement rotation
    always @(posedge clk) begin
        // Implementation of rotation using two's complement addition
        // This achieves the same functionality as {count_internal[WIDTH-2:0], count_internal[WIDTH-1]}
        count_internal <= (count_internal + count_internal) | (count_internal >> (WIDTH-1)); 
    end
    
    // Buffer registers to reduce fanout
    always @(posedge clk) begin
        count_buffer1 <= count_internal;
        count_buffer2 <= count_internal;
    end
    
    // Balanced output distribution using buffers
    assign count[WIDTH-1:WIDTH/2] = count_buffer1[WIDTH-1:WIDTH/2];
    assign count[WIDTH/2-1:0] = count_buffer2[WIDTH/2-1:0];
    
endmodule