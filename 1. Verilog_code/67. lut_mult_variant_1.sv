//SystemVerilog
module lut_mult (
    input [3:0] a, b,
    output reg [7:0] product
);

    reg [7:0] partial_product [0:15][0:15];
    
    // Initialize LUT
    always @(*) begin
        for (int i = 0; i < 16; i = i + 1) begin
            for (int j = 0; j < 16; j = j + 1) begin
                partial_product[i][j] = i * j;
            end
        end
    end
    
    // Lookup result
    always @(*) begin
        product = partial_product[a][b];
    end

endmodule