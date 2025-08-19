//SystemVerilog
module generic_mult #(parameter WIDTH=8) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);

    reg [2*WIDTH-1:0] product_reg;
    reg [WIDTH-1:0] multiplicand;
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] partial_sum;
    reg [2*WIDTH-1:0] shifted_multiplicand [WIDTH-1:0];
    integer i;

    always @(*) begin
        multiplicand = operand1;
        multiplier = operand2;
        product_reg = 0;
        partial_sum = 0;
        
        // Pre-compute all possible shifts using barrel shifter structure
        for (i = 0; i < WIDTH; i = i + 1) begin
            shifted_multiplicand[i] = multiplicand << i;
        end
        
        // Use barrel shifter outputs based on multiplier bits
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (multiplier[i]) begin
                partial_sum = partial_sum + shifted_multiplicand[i];
            end
        end
        
        product_reg = partial_sum;
    end

    assign product = product_reg;

endmodule