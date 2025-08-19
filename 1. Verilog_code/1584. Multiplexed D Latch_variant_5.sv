//SystemVerilog
module baugh_wooley_multiplier (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] result
);

    // Partial products for Baugh-Wooley algorithm
    wire [3:0] pp0, pp1, pp2, pp3;
    wire [7:0] sum1, sum2, sum3;
    
    // Generate partial products
    assign pp0 = {4{a[0]}} & b;
    assign pp1 = {4{a[1]}} & b;
    assign pp2 = {4{a[2]}} & b;
    assign pp3 = {4{a[3]}} & b;
    
    // First level of addition
    assign sum1 = {4'b0, pp0} + {3'b0, pp1, 1'b0};
    
    // Second level of addition
    assign sum2 = sum1 + {2'b0, pp2, 2'b0};
    
    // Final addition with sign extension correction
    assign sum3 = sum2 + {1'b0, pp3, 3'b0} + {4'b0, 4'b1};
    
    // Final result
    assign result = sum3;

endmodule

// Top-level module that includes the original mux_d_latch functionality
module mux_d_latch (
    input wire [3:0] d_inputs,
    input wire [1:0] select,
    input wire enable,
    output reg q
);
    wire selected_d;
    
    assign selected_d = d_inputs[select];
    
    always @* begin
        if (enable)
            q = selected_d;
    end
endmodule