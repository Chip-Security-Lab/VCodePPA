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
    wire [$clog2(WIDTH)-1:0] left_rot_amount;
    
    // Double operand for rotation operations
    assign double_operand = {operand, operand};
    
    // 使用3位借位减法器算法计算左旋转量
    // WIDTH - shift_amount 实现
    wire [2:0] minuend;          // 被减数
    wire [2:0] subtrahend;       // 减数
    wire [2:0] difference;       // 差
    wire [3:0] borrow;           // 借位信号，多一位用于初始借位
    
    // 截取有效位宽，确保3位减法器能够处理
    assign minuend = WIDTH[2:0];
    assign subtrahend = shift_amount[2:0];
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;  // 初始无借位
    
    // 逐位生成借位和差
    assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow[0];
    assign borrow[1] = (~minuend[0] & subtrahend[0]) | 
                      (borrow[0] & ~(minuend[0] ^ subtrahend[0]));
                      
    assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[1];
    assign borrow[2] = (~minuend[1] & subtrahend[1]) | 
                      (borrow[1] & ~(minuend[1] ^ subtrahend[1]));
                      
    assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[2];
    assign borrow[3] = (~minuend[2] & subtrahend[2]) | 
                      (borrow[2] & ~(minuend[2] ^ subtrahend[2]));
    
    // 扩展至所需位宽
    assign left_rot_amount = {difference, {($clog2(WIDTH)-3){1'b0}}};
    
    // Configurable shift implementation
    always @(*) begin
        case(mode)
            3'b000: shifted_result = operand << shift_amount; // Left logical
            3'b001: shifted_result = operand >> shift_amount; // Right logical
            3'b010: shifted_result = double_operand >> left_rot_amount; // Left rot using borrowing subtractor
            3'b011: shifted_result = double_operand >> shift_amount; // Right rot
            3'b100: shifted_result = $signed(operand) >>> shift_amount; // Arith right
            default: shifted_result = operand; // No shift
        endcase
    end
    
    assign result = shifted_result;
endmodule