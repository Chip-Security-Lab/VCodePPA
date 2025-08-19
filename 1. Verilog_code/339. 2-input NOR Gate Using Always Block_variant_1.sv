//SystemVerilog
module nor2_assign (
    input wire [7:0] A,
    input wire [7:0] B,
    output reg [15:0] Y
);
    reg [7:0] operand_a;
    reg [7:0] operand_b;
    reg [15:0] product;
    integer i;

    always @(*) begin
        // NOR operation on each bit
        operand_a = ~A;
        operand_b = ~B;
        product = 16'b0;
        for (i = 0; i < 8; i = i + 1) begin
            if (operand_b[i])
                product = product + (operand_a << i);
        end
        Y = product;
    end
endmodule