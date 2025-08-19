//SystemVerilog
module asym_bidir_shifter (
    input [15:0] data,
    input [3:0] l_shift, // 左移量
    input [2:0] r_shift, // 右移量
    output reg [15:0] result
);

    // 声明用于存储左移和右移结果的中间变量
    reg [31:0] left_shifted;
    reg [15:0] right_shifted;
    
    always @(*) begin
        // 扩展左移结果至32位，避免移位越界
        left_shifted = {16'b0, data} << l_shift;
        
        // 优化右移，只对有效位移位
        case(r_shift)
            3'd0: right_shifted = data;
            3'd1: right_shifted = {1'b0, data[15:1]};
            3'd2: right_shifted = {2'b0, data[15:2]};
            3'd3: right_shifted = {3'b0, data[15:3]};
            3'd4: right_shifted = {4'b0, data[15:4]};
            3'd5: right_shifted = {5'b0, data[15:5]};
            3'd6: right_shifted = {6'b0, data[15:6]};
            3'd7: right_shifted = {7'b0, data[15:7]};
        endcase
        
        // 合并结果
        result = left_shifted[15:0] | right_shifted;
    end
endmodule