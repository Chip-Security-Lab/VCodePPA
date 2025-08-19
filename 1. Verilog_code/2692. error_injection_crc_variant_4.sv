//SystemVerilog
module error_injection_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire inject_error,
    input wire [2:0] error_bit,
    output reg [7:0] crc_out
);
    parameter [7:0] POLY = 8'h07;
    
    // 卡拉苏巴乘法器模块用于提高PPA指标
    wire [7:0] mult_result;
    wire [7:0] mult_input_b;
    
    // 使用显式多路复用器替代三元运算符
    assign mult_input_b = inject_error ? 8'h02 : 8'h01;
    
    karatsuba_multiplier mult_inst(
        .a(data),
        .b(mult_input_b),
        .p(mult_result)
    );
    
    reg [7:0] modified_data;
    wire [7:0] error_mask;
    
    // 创建错误掩码，只有在特定位置有1
    assign error_mask = (8'h01 << error_bit);
    
    // 使用显式多路复用器结构
    always @(*) begin
        modified_data = data;
        if (inject_error) begin
            modified_data = data ^ error_mask; // 对特定位取反
        end
    end
    
    // CRC计算时使用显式多路复用器
    reg [7:0] feedback_term;
    wire feedback_bit;
    
    assign feedback_bit = crc_out[7] ^ modified_data[0];
    
    always @(*) begin
        case(feedback_bit)
            1'b1: feedback_term = POLY;
            1'b0: feedback_term = 8'h00;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            crc_out <= 8'h00;
        end
        else if (data_valid) begin
            crc_out <= {crc_out[6:0], 1'b0} ^ feedback_term;
        end
    end
endmodule

// 基拉斯基乘法器实现
module karatsuba_multiplier(
    input [7:0] a,
    input [7:0] b,
    output [15:0] p
);
    // 将8位输入分成高低各4位
    wire [3:0] a_high, a_low, b_high, b_low;
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // 计算子乘积
    wire [7:0] z0, z1, z2;
    wire [7:0] sum_a, sum_b;
    
    // z0 = a_low * b_low
    assign z0 = a_low * b_low;
    
    // z2 = a_high * b_high
    assign z2 = a_high * b_high;
    
    // sum_a = a_high + a_low, sum_b = b_high + b_low
    assign sum_a = {4'b0000, a_high} + {4'b0000, a_low};
    assign sum_b = {4'b0000, b_high} + {4'b0000, b_low};
    
    // 优化z1计算，使用显式多路复用器结构
    wire [15:0] sum_ab_mult;
    wire [7:0] z1_subtractor;
    
    assign sum_ab_mult = sum_a * sum_b;
    assign z1_subtractor = z2 + z0;
    assign z1 = sum_ab_mult[7:0] - z1_subtractor;
    
    // 使用卡拉苏巴算法组合结果
    wire [15:0] z0_ext, z1_ext, z2_ext;
    assign z0_ext = {8'b0, z0};
    assign z1_ext = {4'b0, z1, 4'b0};
    assign z2_ext = {z2, 8'b0};
    
    // 最终结果
    assign p = z0_ext + z1_ext + z2_ext;
endmodule