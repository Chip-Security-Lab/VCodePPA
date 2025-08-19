//SystemVerilog
module AsyncReset_AND(
    input rst_n,
    input [3:0] src1, src2,
    output reg [3:0] q
);
    wire [7:0] mult_result;
    
    BoothMultiplier booth_mult (
        .multiplicand(src1),
        .multiplier(src2),
        .product(mult_result)
    );
    
    always @(*) begin
        q = rst_n ? mult_result[3:0] : 4'b0000;
    end
endmodule

module BoothMultiplier(
    input [3:0] multiplicand,
    input [3:0] multiplier,
    output [7:0] product
);
    reg [7:0] booth_product;
    reg [4:0] booth_partial_product;
    reg [4:0] neg_multiplicand;
    integer i;
    
    always @(*) begin
        booth_product = 8'b0;
        neg_multiplicand = {1'b1, ~multiplicand} + 1;
        
        booth_partial_product = {1'b0, multiplicand};
        
        for (i = 0; i < 4; i = i + 1) begin
            case ({multiplier[i], (i == 0) ? 1'b0 : multiplier[i-1]})
                2'b01: booth_product = booth_product + (booth_partial_product << i);
                2'b10: booth_product = booth_product + (neg_multiplicand << i);
                default: booth_product = booth_product;
            endcase
        end
    end
    
    assign product = booth_product;
endmodule