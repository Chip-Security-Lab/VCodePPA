//SystemVerilog
module LUTDiv(input [3:0] x, y, output reg [7:0] q);
    reg [7:0] product;
    reg [3:0] counter;
    reg [7:0] multiplicand;
    reg [7:0] multiplier;

    // Bucket Shift Register for multiplication
    wire [7:0] mux_out [0:3]; // MUX outputs for bucket shifting

    // MUX for shifting multiplicand
    assign mux_out[0] = multiplicand; // No shift
    assign mux_out[1] = multiplicand << 1; // Shift left by 1
    assign mux_out[2] = multiplicand << 2; // Shift left by 2
    assign mux_out[3] = multiplicand << 3; // Shift left by 3

    always @(*) begin
        // Initialize product to 0
        product = 8'h00;
        multiplicand = {4'b0000, x}; // Extend x to 8 bits
        multiplier = {4'b0000, y};    // Extend y to 8 bits
        counter = 4'b0000;

        // Shift and Add Multiplication Algorithm
        while (counter < 8) begin
            if (multiplier[0]) begin
                product = product + mux_out[counter[1:0]]; // Use MUX output based on counter
            end
            multiplier = multiplier >> 1; // Shift multiplier right
            counter = counter + 1;
        end
        
        // Output the product
        q = product;
    end
endmodule