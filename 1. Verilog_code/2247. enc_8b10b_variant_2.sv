//SystemVerilog
module enc_8b10b #(parameter K=0) (
    input [7:0] din,
    input rd_in,
    output [9:0] dout,
    output rd_out
);
    // 内部信号定义
    wire [9:0] encoded_data;
    wire [5:0] disparity_delta;
    wire       valid_pattern;
    
    // 实例化子模块
    pattern_encoder #(.K(K)) pattern_enc_inst (
        .din(din),
        .k_flag(K),
        .encoded_data(encoded_data),
        .disparity_delta(disparity_delta),
        .valid_pattern(valid_pattern)
    );
    
    disparity_controller disp_ctrl_inst (
        .encoded_data(encoded_data),
        .disparity_delta(disparity_delta),
        .valid_pattern(valid_pattern),
        .k_flag(K),
        .din(din),
        .rd_in(rd_in),
        .dout(dout),
        .rd_out(rd_out)
    );
endmodule

// 模式识别和编码子模块
module pattern_encoder #(parameter K=0) (
    input [7:0] din,
    input k_flag,
    output reg [9:0] encoded_data,
    output reg [5:0] disparity_delta,
    output reg valid_pattern
);
    // 编码逻辑
    always @(*) begin
        valid_pattern = 1'b1;
        
        case({k_flag, din})
            9'b1_00011100: begin  // K28.4特殊字符
                encoded_data = 10'b0011111010;
                disparity_delta = 6'd2;  // 绝对值，符号在disparity_controller处理
            end
            9'b0_10101010: begin  // 交替数据模式
                encoded_data = 10'b1010010111;
                disparity_delta = 6'd2;
            end
            9'b0_00000000: begin  // 全0数据
                encoded_data = 10'b0101010101;
                disparity_delta = 6'd0;
            end
            9'b0_11111111: begin  // 全1数据
                encoded_data = 10'b1010101010;
                disparity_delta = 6'd0;
            end
            default: begin         // 未定义模式
                encoded_data = 10'b0101010101;
                disparity_delta = 6'd0;
                valid_pattern = 1'b0;
            end
        endcase
    end
endmodule

// 视差控制子模块
module disparity_controller (
    input [9:0] encoded_data,
    input [5:0] disparity_delta,
    input valid_pattern,
    input k_flag,
    input [7:0] din,
    input rd_in,
    output reg [9:0] dout,
    output reg rd_out
);
    // 视差计算和输出生成
    always @(*) begin
        // 最终输出编码数据
        dout = encoded_data;
        
        // 视差处理逻辑
        if (!valid_pattern) begin
            // 对于无效模式，保持原有视差
            rd_out = rd_in;
        end else if ({k_flag, din} == 9'b1_00011100) begin
            // K28.4特殊处理
            rd_out = (rd_in <= 0);
        end else begin
            // 常规视差计算
            rd_out = rd_in + ((rd_in <= 0) ? disparity_delta : -disparity_delta);
        end
    end
endmodule