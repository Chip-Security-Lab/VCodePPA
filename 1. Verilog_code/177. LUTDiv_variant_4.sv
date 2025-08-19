//SystemVerilog
module LUTDiv(input signed [3:0] x, input signed [3:0] y, output reg signed [7:0] q);
    reg signed [7:0] product;
    reg [3:0] multiplier;
    reg [3:0] multiplicand;
    reg [7:0] partial_product;
    reg [3:0] count;
    reg [1:0] state;

    // Booth's multiplication algorithm
    always @(*) begin
        multiplier = y;
        multiplicand = x;
        product = 0;
        partial_product = 0;
        count = 4; // 4 bits for 4-bit inputs
        state = 0;

        while (count > 0) begin
            case (state)
                0: begin
                    if (multiplier[0] == 1) begin
                        partial_product = multiplicand;
                        state = 1;
                    end else if (multiplier[0] == 0 && multiplier[1] == 1) begin
                        partial_product = -multiplicand;
                        state = 1;
                    end else begin
                        partial_product = 0;
                        state = 1;
                    end
                end
                1: begin
                    product = product + partial_product;
                    multiplier = multiplier >> 1;
                    count = count - 1;
                    state = 0;
                end
            endcase
        end
        q = product;
    end
endmodule