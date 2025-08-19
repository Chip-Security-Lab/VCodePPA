//SystemVerilog
module shift_xor_operator (
    input [7:0] a,
    input [2:0] shift_amount,
    output reg [7:0] shifted_result,
    output reg [7:0] xor_result
);
    // 使用组合逻辑块替代连续赋值，提高时序控制
    always @(*) begin
        // 采用case语句实现移位操作，减少级联逻辑
        case(shift_amount)
            3'b000: shifted_result = a;
            3'b001: shifted_result = {1'b0, a[7:1]};
            3'b010: shifted_result = {2'b00, a[7:2]};
            3'b011: shifted_result = {3'b000, a[7:3]};
            3'b100: shifted_result = {4'b0000, a[7:4]};
            3'b101: shifted_result = {5'b00000, a[7:5]};
            3'b110: shifted_result = {6'b000000, a[7:6]};
            3'b111: shifted_result = {7'b0000000, a[7]};
            default: shifted_result = a;
        endcase
        
        // 直接在同一个逻辑块中计算异或结果，减少门延迟
        xor_result = a ^ shifted_result;
    end
endmodule