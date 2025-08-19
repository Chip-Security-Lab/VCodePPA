// Lower 4-bit adder module with retimed registers
module lower_adder(
    input clk,
    input [3:0] a_low,
    input [3:0] b_low,
    output [3:0] sum_low,
    output carry
);
    reg [3:0] a_low_reg, b_low_reg;
    wire [4:0] sum_temp;
    
    always @(posedge clk) begin
        a_low_reg <= a_low;
        b_low_reg <= b_low;
    end
    
    assign sum_temp = a_low_reg + b_low_reg;
    assign {carry, sum_low} = sum_temp;
endmodule

// Upper 4-bit adder module with retimed registers
module upper_adder(
    input clk,
    input [3:0] a_high,
    input [3:0] b_high,
    input carry_in,
    output [3:0] sum_high
);
    reg [3:0] a_high_reg, b_high_reg;
    reg carry_in_reg;
    wire [4:0] sum_temp;
    
    always @(posedge clk) begin
        a_high_reg <= a_high;
        b_high_reg <= b_high;
        carry_in_reg <= carry_in;
    end
    
    assign sum_temp = a_high_reg + b_high_reg + carry_in_reg;
    assign sum_high = sum_temp[3:0];
endmodule

// Top-level pipelined adder module
module pipelined_adder(
    input clk,
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    wire [3:0] sum_low;
    wire carry;
    wire [3:0] sum_high;

    lower_adder lower_inst(
        .clk(clk),
        .a_low(a[3:0]),
        .b_low(b[3:0]),
        .sum_low(sum_low),
        .carry(carry)
    );

    upper_adder upper_inst(
        .clk(clk),
        .a_high(a[7:4]),
        .b_high(b[7:4]),
        .carry_in(carry),
        .sum_high(sum_high)
    );

    assign sum = {sum_high, sum_low};
endmodule