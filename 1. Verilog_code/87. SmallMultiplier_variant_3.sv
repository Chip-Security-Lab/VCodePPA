//SystemVerilog
module SmallMultiplier(
    input [1:0] a, b,
    output reg [3:0] prod
);

    wire [3:0] final_prod;
    
    // Optimized multiplication using direct bit manipulation
    assign final_prod = (a[1] ? {b, 2'b00} : 4'b0000) + 
                       (a[0] ? {2'b00, b} : 4'b0000);

    // Register output
    always @(*) begin
        prod = final_prod;
    end

endmodule