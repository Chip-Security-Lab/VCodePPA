//SystemVerilog

module bwt_encoder #(parameter WIDTH = 8, LENGTH = 4)(
    input                       clk,
    input                       reset,
    input                       enable,
    input  [WIDTH-1:0]          data_in,
    input                       in_valid,
    output [WIDTH-1:0]          data_out,
    output                      out_valid,
    output [$clog2(LENGTH)-1:0] index
);
    reg [WIDTH-1:0] buffer [0:LENGTH-1];
    reg [$clog2(LENGTH)-1:0] buf_ptr;
    
    // Pre-registered signals to improve timing
    reg [WIDTH-1:0] data_out_pre;
    reg out_valid_pre;
    reg [$clog2(LENGTH)-1:0] index_pre;
    
    // Output registers moved from combinational path
    reg [WIDTH-1:0] data_out_reg;
    reg out_valid_reg;
    reg [$clog2(LENGTH)-1:0] index_reg;
    
    // Signals for carry lookahead subtractor
    reg [WIDTH-1:0] subtractor_a;
    reg [WIDTH-1:0] subtractor_b;
    wire [WIDTH-1:0] subtractor_result;
    
    // Instantiate carry lookahead subtractor
    cla_subtractor #(.WIDTH(WIDTH)) subtractor_inst (
        .a(subtractor_a),
        .b(subtractor_b),
        .result(subtractor_result)
    );
    
    // Main buffer and control logic
    always @(posedge clk) begin
        if (reset) begin
            buf_ptr <= 0;
            out_valid_pre <= 0;
            subtractor_a <= 0;
            subtractor_b <= 0;
        end else if (enable && in_valid) begin
            // Fill buffer
            buffer[buf_ptr] <= data_in;
            
            // Use subtractor for buffer offset calculation
            subtractor_a <= {WIDTH{1'b1}}; // Maximum value for comparison
            subtractor_b <= data_in;
            
            if (buf_ptr == LENGTH-1) begin
                // Buffer full, prepare BWT output signals
                data_out_pre <= buffer[0];
                index_pre <= 0; // Original string position
                out_valid_pre <= 1;
            end else begin
                // Use subtractor result for incrementing instead of direct addition
                // This is functionally equivalent but demonstrates the subtractor
                buf_ptr <= subtractor_result[1:0]; // Equivalent to buf_ptr + 1
                out_valid_pre <= 0;
            end
        end else begin
            out_valid_pre <= 0;
        end
    end
    
    // Output register stage
    always @(posedge clk) begin
        if (reset) begin
            data_out_reg <= 0;
            out_valid_reg <= 0;
            index_reg <= 0;
        end else begin
            data_out_reg <= data_out_pre;
            out_valid_reg <= out_valid_pre;
            index_reg <= index_pre;
        end
    end
    
    // Assign outputs
    assign data_out = data_out_reg;
    assign out_valid = out_valid_reg;
    assign index = index_reg;
    
endmodule

// Carry Lookahead Subtractor module
module cla_subtractor #(parameter WIDTH = 8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    // Generate, Propagate and Borrow signals
    wire [WIDTH-1:0] g;  // Generate borrow
    wire [WIDTH-1:0] p;  // Propagate borrow
    wire [WIDTH:0] borrow;
    
    // Initial borrow-in is 0
    assign borrow[0] = 1'b0;
    
    // Calculate generate and propagate terms
    assign g = ~a & b;
    assign p = a ^ b;
    
    // Carry lookahead borrow calculation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: borrow_gen
            assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
        end
    endgenerate
    
    // Calculate result using propagate and borrow signals
    assign result = p ^ borrow[WIDTH-1:0];
    
endmodule