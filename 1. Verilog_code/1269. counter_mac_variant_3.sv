//SystemVerilog
// Top-level module (IEEE 1364-2005)
module counter_mac #(parameter WIDTH=8) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output [2*WIDTH-1:0] sum
);
    // Internal signals
    wire [WIDTH-1:0] a_reg, b_reg;
    wire [2*WIDTH-1:0] mult_result;
    
    // Register inputs to improve timing
    reg [WIDTH-1:0] a_input, b_input;
    
    always @(posedge clk) begin
        if (rst) begin
            a_input <= {WIDTH{1'b0}};
            b_input <= {WIDTH{1'b0}};
        end
        else begin
            a_input <= a;
            b_input <= b;
        end
    end
    
    // Multiplication sub-module with registered inputs
    multiplier #(
        .WIDTH(WIDTH)
    ) mult_inst (
        .a(a_input),
        .b(b_input),
        .product(mult_result)
    );
    
    // Accumulator sub-module
    accumulator #(
        .WIDTH(2*WIDTH)
    ) acc_inst (
        .clk(clk),
        .rst(rst),
        .data_in(mult_result),
        .sum_out(sum)
    );
    
endmodule

// Sub-module for multiplication
module multiplier #(parameter WIDTH=8) (
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] product
);
    // Registered multiplication output
    always @(*) begin
        product = a * b;
    end
endmodule

// Sub-module for accumulation
module accumulator #(parameter WIDTH=16) (
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] sum_out
);
    // Sequential accumulation logic
    always @(posedge clk) begin
        if (rst) 
            sum_out <= {WIDTH{1'b0}};
        else 
            sum_out <= sum_out + data_in;
    end
endmodule