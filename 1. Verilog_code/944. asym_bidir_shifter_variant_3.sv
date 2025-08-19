//SystemVerilog
module asym_bidir_shifter (
    input [15:0] data,
    input [3:0] l_shift, // 左移量
    input [2:0] r_shift, // 右移量
    output reg [15:0] result
);

    // 使用参数化设计提高可配置性
    parameter DATA_WIDTH = 16;
    
    // 左移和右移的中间结果
    reg [DATA_WIDTH-1:0] left_shifted;
    reg [DATA_WIDTH-1:0] right_shifted;
    
    // 使用always块代替assign语句，允许更复杂的逻辑
    always @(*) begin
        // 分解移位操作为多个步骤以减少关键路径
        // 左移操作优化
        case(l_shift)
            4'd0: left_shifted = data;
            4'd1: left_shifted = {data[14:0], 1'b0};
            4'd2: left_shifted = {data[13:0], 2'b0};
            4'd3: left_shifted = {data[12:0], 3'b0};
            4'd4: left_shifted = {data[11:0], 4'b0};
            4'd5: left_shifted = {data[10:0], 5'b0};
            4'd6: left_shifted = {data[9:0], 6'b0};
            4'd7: left_shifted = {data[8:0], 7'b0};
            4'd8: left_shifted = {data[7:0], 8'b0};
            4'd9: left_shifted = {data[6:0], 9'b0};
            4'd10: left_shifted = {data[5:0], 10'b0};
            4'd11: left_shifted = {data[4:0], 11'b0};
            4'd12: left_shifted = {data[3:0], 12'b0};
            4'd13: left_shifted = {data[2:0], 13'b0};
            4'd14: left_shifted = {data[1:0], 14'b0};
            4'd15: left_shifted = {data[0], 15'b0};
        endcase
        
        // 右移操作优化
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
        
        // 最终的按位或操作
        result = left_shifted | right_shifted;
    end
endmodule