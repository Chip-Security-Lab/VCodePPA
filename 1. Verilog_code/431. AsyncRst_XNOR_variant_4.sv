//SystemVerilog
// Top level module - AsyncRst_BoothMultiplier
module AsyncRst_XNOR (
    input        rst_n,
    input  [3:0] src_a, src_b,
    output [3:0] q
);
    // Internal connection signals
    wire [3:0] mult_result;
    
    // Instantiate Booth multiplier submodule
    Booth_Multiplier u_booth_multiplier (
        .multiplicand (src_a),
        .multiplier   (src_b),
        .product      (mult_result)
    );
    
    // Instantiate reset control submodule
    Reset_Control u_reset_control (
        .rst_n      (rst_n),
        .data_in    (mult_result),
        .data_out   (q)
    );
    
endmodule

// Submodule for 4-bit Booth Multiplier
module Booth_Multiplier (
    input  [3:0] multiplicand,
    input  [3:0] multiplier,
    output [3:0] product
);
    reg [8:0] booth_product;
    reg [4:0] booth_multiplier;
    reg [4:0] neg_multiplicand;
    reg [4:0] pos_multiplicand;
    
    always @(*) begin
        // Initialize values
        booth_multiplier = {multiplier, 1'b0};
        pos_multiplicand = {1'b0, multiplicand};
        neg_multiplicand = ~{1'b0, multiplicand} + 1'b1;
        booth_product = 9'b0;
        
        // Booth algorithm implementation
        for (integer i = 0; i < 4; i = i + 1) begin
            case (booth_multiplier[1:0])
                2'b01: booth_product[8:4] = booth_product[8:4] + pos_multiplicand;
                2'b10: booth_product[8:4] = booth_product[8:4] + neg_multiplicand;
                default: ; // Do nothing for 00 or 11
            endcase
            
            // Arithmetic right shift
            booth_product = {booth_product[8], booth_product[8:1]};
            booth_multiplier = {1'b0, booth_multiplier[4:1]};
        end
    end
    
    // Extract the final product (truncated to 4 bits)
    assign product = booth_product[3:0];
    
endmodule

// Submodule for reset control
module Reset_Control (
    input        rst_n,
    input  [3:0] data_in,
    output reg [3:0] data_out
);
    // Reset control logic using if-else instead of conditional operator
    always @(*) begin
        if (rst_n) begin
            data_out = data_in;
        end else begin
            data_out = 4'b0000;
        end
    end
    
endmodule