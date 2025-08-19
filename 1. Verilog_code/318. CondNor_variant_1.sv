//SystemVerilog
module CondNor(
    input  [7:0] a, 
    input  [7:0] b, 
    output reg [15:0] y
);
    reg [7:0] multiplicand;
    reg [7:0] multiplier;
    reg [15:0] product;
    reg [3:0] bit_index;
    reg busy;
    reg start;

    always @(*) begin
        start = ~(|a | |b); // If all bits of a and b are zero, start multiplication
    end

    always @(posedge start or posedge busy) begin
        if(start && !busy) begin
            multiplicand <= a;
            multiplier   <= b;
            product      <= 16'b0;
            bit_index    <= 4'd0;
            busy         <= 1'b1;
        end
        else if(busy) begin
            if(bit_index < 8) begin
                if(multiplier[0]) begin
                    product <= product + (multiplicand << bit_index);
                end
                multiplier <= multiplier >> 1;
                bit_index  <= bit_index + 1'b1;
            end
            else begin
                busy <= 1'b0;
            end
        end
    end

    always @(*) begin
        if(start) begin
            y = 16'b1; // If both a and b are zero, output 1
        end else begin
            y = product; // Else output the product
        end
    end
endmodule