//SystemVerilog
module booth_encoder #(parameter WIDTH = 4) (
    input wire [WIDTH:0] multiplier_bits,  // 3 adjacent bits
    output reg [1:0] booth_op,             // Operation: 00=0, 01=+A, 10=-A, 11=+2A
    output reg neg                         // Negate result
);

    // Internal signals for decision tree
    wire is_all_zero;
    wire is_all_one;
    wire is_one;
    wire is_two;
    wire is_five;
    wire is_six;
    wire is_three;
    wire is_four;

    assign is_all_zero = (multiplier_bits[2:0] == 3'b000);
    assign is_all_one  = (multiplier_bits[2:0] == 3'b111);
    assign is_one      = (multiplier_bits[2:0] == 3'b001);
    assign is_two      = (multiplier_bits[2:0] == 3'b010);
    assign is_five     = (multiplier_bits[2:0] == 3'b101);
    assign is_six      = (multiplier_bits[2:0] == 3'b110);
    assign is_three    = (multiplier_bits[2:0] == 3'b011);
    assign is_four     = (multiplier_bits[2:0] == 3'b100);

    always @(*) begin
        // Decision tree structure
        if (is_all_zero || is_all_one) begin
            booth_op = 2'b00;
            neg = 1'b0;
        end else if (is_one || is_two) begin
            booth_op = 2'b01;
            neg = 1'b0;
        end else if (is_five || is_six) begin
            booth_op = 2'b01;
            neg = 1'b1;
        end else if (is_three) begin
            booth_op = 2'b11;
            neg = 1'b0;
        end else if (is_four) begin
            booth_op = 2'b11;
            neg = 1'b1;
        end else begin
            booth_op = 2'b00;
            neg = 1'b0;
        end
    end

endmodule