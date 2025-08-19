//SystemVerilog
module Hybrid_XNOR(
    input [1:0] ctrl,
    input [7:0] base,
    output [7:0] res
);
    wire [7:0] shifted_val;
    wire [7:0] multiplicand;
    wire [3:0] multiplier;
    
    // Determine multiplier and multiplicand based on ctrl
    assign multiplier = (ctrl == 2'b00) ? 4'b1111 :
                       (ctrl == 2'b01) ? 4'b1111 :
                       (ctrl == 2'b10) ? 4'b1111 :
                       4'b1111;
                       
    assign multiplicand = 8'b1;
    
    // Booth multiplier implementation
    wire [7:0] booth_product;
    Booth_Multiplier booth_mult(
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(booth_product)
    );
    
    // Position the result based on ctrl
    assign shifted_val = (ctrl == 2'b00) ? {4'b0000, booth_product[3:0]} :
                        (ctrl == 2'b01) ? {2'b00, booth_product[3:0], 2'b00} :
                        (ctrl == 2'b10) ? {booth_product[3:0], 4'b0000} :
                        {booth_product[1:0], 6'b000000} | {4'b0000, booth_product[3:2], 2'b00};
    
    // Final result calculation
    assign res = ~(base ^ shifted_val);
endmodule

module Booth_Multiplier(
    input [7:0] multiplicand,
    input [3:0] multiplier,
    output [7:0] product
);
    reg [7:0] prod;
    reg [8:0] pp; // Partial product
    reg [3:0] booth_encoding;
    integer i;
    
    always @(*) begin
        // Initialize partial product
        pp = 9'b0;
        
        // Booth algorithm implementation
        for (i = 0; i < 2; i = i + 1) begin
            // Booth encoding
            case (multiplier[i*2 +: 2])
                2'b00, 2'b11: booth_encoding = 0; // 0, -0
                2'b01: booth_encoding = 1;        // 1
                2'b10: booth_encoding = -1;       // -1
                default: booth_encoding = 0;
            endcase
            
            // Add/subtract based on encoding
            if (booth_encoding == 1)
                pp = pp + (multiplicand << (i*2));
            else if (booth_encoding == -1)
                pp = pp - (multiplicand << (i*2));
        end
        
        // Final product
        prod = pp[7:0];
    end
    
    assign product = prod;
endmodule