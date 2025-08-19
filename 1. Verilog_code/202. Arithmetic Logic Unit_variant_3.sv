//SystemVerilog
module arithmetic_logic_unit (
    input [7:0] a,
    input [7:0] b,
    input [1:0] op_select,  // 00: add, 01: subtract, 10: and, 11: or
    output reg [7:0] result
);

    wire [7:0] sum;
    wire [7:0] carry;
    wire [7:0] p, g; // generate and propagate signals
    wire [7:0] c;    // carry signals

    // Generate and propagate signals
    assign p = a ^ b; // propagate
    assign g = a & b; // generate

    // Carry calculation using the carry lookahead method
    assign c[0] = 1'b0; // Initial carry-in is 0
    genvar i;
    generate
        for (i = 0; i < 7; i = i + 1) begin: carry_calc
            assign c[i + 1] = g[i] | (p[i] & c[i]);
        end
    endgenerate

    // Sum calculation
    assign sum = p ^ c;

    always @(*) begin
        case (op_select)
            2'b00: result = sum;           // 加法
            2'b01: result = a - b;         // 减法
            2'b10: result = a & b;         // 与操作
            2'b11: result = a | b;         // 或操作
            default: result = 8'b0;
        endcase
    end
endmodule