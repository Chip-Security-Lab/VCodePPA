//SystemVerilog
module configurable_shifter #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] operand,
    input [$clog2(WIDTH)-1:0] shift_amount,
    input [2:0] mode, // 000:left logical, 001:right logical
                      // 010:left rot, 011:right rot
                      // 100:arithmetic right, others:reserved
    output [WIDTH-1:0] result
);
    // Double operand for rotation operations
    wire [2*WIDTH-1:0] double_operand = {operand, operand};
    
    // Use case statement instead of if-else cascade for better synthesis
    reg [WIDTH-1:0] shifted_result;
    
    always @(*) begin
        case (mode)
            3'b000: shifted_result = operand << shift_amount;                       // Left logical
            3'b001: shifted_result = operand >> shift_amount;                       // Right logical
            3'b010: shifted_result = double_operand[(WIDTH-1)+:WIDTH] >> (WIDTH - shift_amount); // Left rot
            3'b011: shifted_result = double_operand[shift_amount+:WIDTH];           // Right rot
            3'b100: shifted_result = $signed(operand) >>> shift_amount;             // Arith right
            default: shifted_result = operand;                                      // No shift
        endcase
    end
    
    assign result = shifted_result;
endmodule