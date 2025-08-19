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
    reg [WIDTH-1:0] shifted_result;
    wire [2*WIDTH-1:0] double_operand;
    
    // Double operand for rotation operations
    assign double_operand = {operand, operand};
    
    // Efficient look-ahead implementation for left rotation
    wire [WIDTH-1:0] left_rot_result;
    wire [WIDTH-1:0] right_rot_result;
    
    // Calculate rotations using look-ahead technique
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: rotation_gen
            // Left rotation with look-ahead borrowing
            assign left_rot_result[i] = (shift_amount == 0) ? operand[i] :
                                      double_operand[i + WIDTH - shift_amount];
            
            // Right rotation with look-ahead borrowing
            assign right_rot_result[i] = double_operand[i + shift_amount];
        end
    endgenerate
    
    // Configurable shift implementation
    always @(*) begin
        case(mode)
            3'b000: shifted_result = operand << shift_amount; // Left logical
            3'b001: shifted_result = operand >> shift_amount; // Right logical
            3'b010: shifted_result = left_rot_result; // Left rot with look-ahead
            3'b011: shifted_result = right_rot_result; // Right rot with look-ahead
            3'b100: shifted_result = $signed(operand) >>> shift_amount; // Arith right
            default: shifted_result = operand; // No shift
        endcase
    end
    
    assign result = shifted_result;
endmodule