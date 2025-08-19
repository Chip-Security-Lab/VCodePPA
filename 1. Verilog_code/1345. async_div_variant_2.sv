//SystemVerilog
//IEEE 1364-2005
// Top-level module
module async_div #(parameter DIV=4) (
    input clk_in,
    output wire clk_out
);
    wire [3:0] counter_value;
    
    // Counter submodule instance
    counter_module counter_inst (
        .clk(clk_in),
        .count(counter_value)
    );
    
    // Clock output generator submodule instance using binary long division
    binary_long_division_clock_gen #(
        .DIV(DIV)
    ) output_gen_inst (
        .count_value(counter_value),
        .clk_out(clk_out)
    );
endmodule

// Counter submodule
module counter_module (
    input clk,
    output reg [3:0] count
);
    // Counter implementation
    always @(posedge clk) begin
        count <= count + 1;
    end
endmodule

// Clock output generator using binary long division algorithm
module binary_long_division_clock_gen #(
    parameter DIV=4
) (
    input [3:0] count_value,
    output reg clk_out
);
    reg [3:0] dividend;
    reg [3:0] divisor;
    reg [3:0] quotient;
    reg [3:0] remainder;
    reg [3:0] temp_dividend;
    integer i;
    
    always @(*) begin
        // Initialize values
        dividend = count_value;
        divisor = DIV;
        quotient = 4'b0000;
        remainder = 4'b0000;
        temp_dividend = 4'b0000;
        
        // Binary long division algorithm implementation
        for (i = 3; i >= 0; i = i - 1) begin
            // Shift remainder left and bring down next bit from dividend
            temp_dividend = {remainder[2:0], dividend[i]};
            
            // Compare with divisor
            if (temp_dividend >= divisor) begin
                quotient[i] = 1'b1;
                remainder = temp_dividend - divisor;
            end else begin
                quotient[i] = 1'b0;
                remainder = temp_dividend;
            end
        end
        
        // Generate clock output based on division result
        // Maintain same behavior as original implementation
        if (DIV <= 4)
            clk_out = |quotient[1:0];
        else
            clk_out = |quotient[3:1];
    end
endmodule