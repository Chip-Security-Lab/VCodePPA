//SystemVerilog
module mul_add (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [3:0] num1,
    input [3:0] num2,
    output valid_out,
    input ready_in,
    output [7:0] product,
    output [4:0] sum
);
    wire mult_valid, mult_ready;
    wire add_valid, add_ready;
    wire [7:0] mult_result;
    wire [4:0] add_result;
    
    // Control signals
    reg valid_reg;
    reg [7:0] product_reg;
    reg [4:0] sum_reg;
    
    // Multiplier instance
    multiplier mult_unit (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(mult_ready),
        .a(num1),
        .b(num2),
        .valid_out(mult_valid),
        .ready_in(ready_in),
        .result(mult_result)
    );
    
    // Adder instance
    adder add_unit (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ready_out(add_ready),
        .a(num1),
        .b(num2),
        .valid_out(add_valid),
        .ready_in(ready_in),
        .result(add_result)
    );
    
    // Output control
    assign ready_out = mult_ready & add_ready;
    assign valid_out = valid_reg;
    assign product = product_reg;
    assign sum = sum_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            product_reg <= 8'b0;
            sum_reg <= 5'b0;
        end else if (valid_in && ready_out) begin
            valid_reg <= 1'b1;
            product_reg <= mult_result;
            sum_reg <= add_result;
        end else if (valid_out && ready_in) begin
            valid_reg <= 1'b0;
        end
    end
endmodule

module multiplier #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 8
) (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [WIDTH_IN-1:0] a,
    input [WIDTH_IN-1:0] b,
    output valid_out,
    input ready_in,
    output [WIDTH_OUT-1:0] result
);
    reg valid_reg;
    reg [WIDTH_OUT-1:0] result_reg;
    
    assign ready_out = !valid_reg || (valid_reg && ready_in);
    assign valid_out = valid_reg;
    assign result = result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            result_reg <= {WIDTH_OUT{1'b0}};
        end else if (valid_in && ready_out) begin
            valid_reg <= 1'b1;
            result_reg <= a * b;
        end else if (valid_reg && ready_in) begin
            valid_reg <= 1'b0;
        end
    end
endmodule

module adder #(
    parameter WIDTH_IN = 4,
    parameter WIDTH_OUT = 5
) (
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [WIDTH_IN-1:0] a,
    input [WIDTH_IN-1:0] b,
    output valid_out,
    input ready_in,
    output [WIDTH_OUT-1:0] result
);
    reg valid_reg;
    reg [WIDTH_OUT-1:0] result_reg;
    
    assign ready_out = !valid_reg || (valid_reg && ready_in);
    assign valid_out = valid_reg;
    assign result = result_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg <= 1'b0;
            result_reg <= {WIDTH_OUT{1'b0}};
        end else if (valid_in && ready_out) begin
            valid_reg <= 1'b1;
            result_reg <= a + b;
        end else if (valid_reg && ready_in) begin
            valid_reg <= 1'b0;
        end
    end
endmodule