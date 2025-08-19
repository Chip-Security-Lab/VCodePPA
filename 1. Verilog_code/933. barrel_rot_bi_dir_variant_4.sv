//SystemVerilog
module barrel_rot_bi_dir (
    input [31:0] data_in,
    input [4:0] shift_val,
    input direction,  // 0-left, 1-right
    output [31:0] data_out
);
    // 使用二进制补码减法算法计算32-shift_val
    wire [5:0] shift_val_extended = {1'b0, shift_val};
    wire [5:0] complemented_value;
    wire [5:0] neg_shift_val;
    
    // 二进制补码运算：取反加一
    assign complemented_value = ~shift_val_extended;
    assign neg_shift_val = complemented_value + 6'b1;
    
    // 32-shift_val的计算结果（使用补码算法）
    wire [5:0] subtraction_result = 6'd32 + neg_shift_val;
    wire [4:0] shift_complement = subtraction_result[4:0];
    
    // 分解为级联的移位操作以提高性能
    reg [31:0] left_shift, right_shift;
    
    // 左移实现
    always @(*) begin
        case(shift_val)
            5'd0:  left_shift = data_in;
            5'd1:  left_shift = {data_in[30:0], data_in[31]};
            5'd2:  left_shift = {data_in[29:0], data_in[31:30]};
            5'd3:  left_shift = {data_in[28:0], data_in[31:29]};
            5'd4:  left_shift = {data_in[27:0], data_in[31:28]};
            5'd5:  left_shift = {data_in[26:0], data_in[31:27]};
            5'd6:  left_shift = {data_in[25:0], data_in[31:26]};
            5'd7:  left_shift = {data_in[24:0], data_in[31:25]};
            5'd8:  left_shift = {data_in[23:0], data_in[31:24]};
            5'd9:  left_shift = {data_in[22:0], data_in[31:23]};
            5'd10: left_shift = {data_in[21:0], data_in[31:22]};
            5'd11: left_shift = {data_in[20:0], data_in[31:21]};
            5'd12: left_shift = {data_in[19:0], data_in[31:20]};
            5'd13: left_shift = {data_in[18:0], data_in[31:19]};
            5'd14: left_shift = {data_in[17:0], data_in[31:18]};
            5'd15: left_shift = {data_in[16:0], data_in[31:17]};
            5'd16: left_shift = {data_in[15:0], data_in[31:16]};
            5'd17: left_shift = {data_in[14:0], data_in[31:15]};
            5'd18: left_shift = {data_in[13:0], data_in[31:14]};
            5'd19: left_shift = {data_in[12:0], data_in[31:13]};
            5'd20: left_shift = {data_in[11:0], data_in[31:12]};
            5'd21: left_shift = {data_in[10:0], data_in[31:11]};
            5'd22: left_shift = {data_in[9:0], data_in[31:10]};
            5'd23: left_shift = {data_in[8:0], data_in[31:9]};
            5'd24: left_shift = {data_in[7:0], data_in[31:8]};
            5'd25: left_shift = {data_in[6:0], data_in[31:7]};
            5'd26: left_shift = {data_in[5:0], data_in[31:6]};
            5'd27: left_shift = {data_in[4:0], data_in[31:5]};
            5'd28: left_shift = {data_in[3:0], data_in[31:4]};
            5'd29: left_shift = {data_in[2:0], data_in[31:3]};
            5'd30: left_shift = {data_in[1:0], data_in[31:2]};
            5'd31: left_shift = {data_in[0], data_in[31:1]};
            default: left_shift = data_in;
        endcase
    end
    
    // 右移实现
    always @(*) begin
        case(shift_val)
            5'd0:  right_shift = data_in;
            5'd1:  right_shift = {data_in[0], data_in[31:1]};
            5'd2:  right_shift = {data_in[1:0], data_in[31:2]};
            5'd3:  right_shift = {data_in[2:0], data_in[31:3]};
            5'd4:  right_shift = {data_in[3:0], data_in[31:4]};
            5'd5:  right_shift = {data_in[4:0], data_in[31:5]};
            5'd6:  right_shift = {data_in[5:0], data_in[31:6]};
            5'd7:  right_shift = {data_in[6:0], data_in[31:7]};
            5'd8:  right_shift = {data_in[7:0], data_in[31:8]};
            5'd9:  right_shift = {data_in[8:0], data_in[31:9]};
            5'd10: right_shift = {data_in[9:0], data_in[31:10]};
            5'd11: right_shift = {data_in[10:0], data_in[31:11]};
            5'd12: right_shift = {data_in[11:0], data_in[31:12]};
            5'd13: right_shift = {data_in[12:0], data_in[31:13]};
            5'd14: right_shift = {data_in[13:0], data_in[31:14]};
            5'd15: right_shift = {data_in[14:0], data_in[31:15]};
            5'd16: right_shift = {data_in[15:0], data_in[31:16]};
            5'd17: right_shift = {data_in[16:0], data_in[31:17]};
            5'd18: right_shift = {data_in[17:0], data_in[31:18]};
            5'd19: right_shift = {data_in[18:0], data_in[31:19]};
            5'd20: right_shift = {data_in[19:0], data_in[31:20]};
            5'd21: right_shift = {data_in[20:0], data_in[31:21]};
            5'd22: right_shift = {data_in[21:0], data_in[31:22]};
            5'd23: right_shift = {data_in[22:0], data_in[31:23]};
            5'd24: right_shift = {data_in[23:0], data_in[31:24]};
            5'd25: right_shift = {data_in[24:0], data_in[31:25]};
            5'd26: right_shift = {data_in[25:0], data_in[31:26]};
            5'd27: right_shift = {data_in[26:0], data_in[31:27]};
            5'd28: right_shift = {data_in[27:0], data_in[31:28]};
            5'd29: right_shift = {data_in[28:0], data_in[31:29]};
            5'd30: right_shift = {data_in[29:0], data_in[31:30]};
            5'd31: right_shift = {data_in[30:0], data_in[31]};
            default: right_shift = data_in;
        endcase
    end

    // 最终输出
    assign data_out = direction ? right_shift : left_shift;
    
endmodule