//SystemVerilog
// Top level module for ring counter with buffered output
module basic_ring_counter #(parameter WIDTH = 4)(
    input wire clk,
    output wire [WIDTH-1:0] count
);
    // Internal signals for connecting submodules
    wire [WIDTH-1:0] counter_out;
    wire [WIDTH-1:0] buffer1_out;
    
    // Instantiate the core ring counter
    ring_counter_core #(
        .WIDTH(WIDTH)
    ) core_counter (
        .clk(clk),
        .count_out(counter_out)
    );
    
    // Instantiate the first buffer stage
    output_buffer #(
        .WIDTH(WIDTH)
    ) buffer_stage1 (
        .clk(clk),
        .data_in(counter_out),
        .data_out(buffer1_out)
    );
    
    // Instantiate the second buffer stage
    output_buffer #(
        .WIDTH(WIDTH)
    ) buffer_stage2 (
        .clk(clk),
        .data_in(buffer1_out),
        .data_out(count)
    );
endmodule

// Core ring counter logic module
module ring_counter_core #(parameter WIDTH = 4)(
    input wire clk,
    output reg [WIDTH-1:0] count_out
);
    // Initialize with one-hot encoding
    initial begin
        count_out = {{(WIDTH-1){1'b0}}, 1'b1};
    end
    
    always @(posedge clk) begin
        // Rotate the bits
        count_out <= {count_out[WIDTH-2:0], count_out[WIDTH-1]};
    end
endmodule

// Generic output buffer module for load distribution
module output_buffer #(parameter WIDTH = 4)(
    input wire clk,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    // Initialize buffer
    initial begin
        data_out = {{(WIDTH-1){1'b0}}, 1'b1};
    end
    
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule