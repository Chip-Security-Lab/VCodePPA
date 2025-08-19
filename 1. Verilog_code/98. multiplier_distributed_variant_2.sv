//SystemVerilog
module multiplier_distributed (
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] product
);
    wire [7:0] barrel_shift [3:0];
    reg [7:0] partial_product [3:0];
    
    // Barrel shifter implementation
    assign barrel_shift[0] = b;
    assign barrel_shift[1] = {b[2:0], 1'b0};
    assign barrel_shift[2] = {b[1:0], 2'b0};
    assign barrel_shift[3] = {b[0], 3'b0};
    
    // Partial product generation using if-else
    always @(*) begin
        if(a[0])
            partial_product[0] = barrel_shift[0];
        else
            partial_product[0] = 8'b0;
            
        if(a[1])
            partial_product[1] = barrel_shift[1];
        else
            partial_product[1] = 8'b0;
            
        if(a[2])
            partial_product[2] = barrel_shift[2];
        else
            partial_product[2] = 8'b0;
            
        if(a[3])
            partial_product[3] = barrel_shift[3];
        else
            partial_product[3] = 8'b0;
    end
    
    // Final product calculation
    always @(*) begin
        product = partial_product[0] + partial_product[1] + partial_product[2] + partial_product[3];
    end
endmodule