//SystemVerilog
module clock_divider #(parameter DIVIDE_BY = 2) (
    input wire clk_in, reset,
    output reg clk_out
);
    // Pipeline registers for better timing
    reg [$clog2(DIVIDE_BY)-1:0] count;
    reg [$clog2(DIVIDE_BY)-1:0] half_divide_minus_one_reg;
    reg comparison_result; // Register to break the comparison path
    
    // Pre-compute the constant value for half_divide_minus_one at initialization
    wire [$clog2(DIVIDE_BY)-1:0] half_divide_minus_one = (DIVIDE_BY/2) + {$clog2(DIVIDE_BY){1'b1}};
    
    // First pipeline stage: store constant and perform comparison
    always @(posedge clk_in) begin
        if (reset) begin
            half_divide_minus_one_reg <= (DIVIDE_BY/2) + {$clog2(DIVIDE_BY){1'b1}};
            comparison_result <= 1'b0;
        end else begin
            half_divide_minus_one_reg <= half_divide_minus_one;
            comparison_result <= (count == half_divide_minus_one_reg);
        end
    end
    
    // Second pipeline stage: handle counter and clock output
    always @(posedge clk_in) begin
        if (reset) begin
            count <= 0;
            clk_out <= 0;
        end else begin
            if (comparison_result) begin
                clk_out <= ~clk_out;
                count <= 0;
            end else
                count <= count + 1'b1;
        end
    end
endmodule