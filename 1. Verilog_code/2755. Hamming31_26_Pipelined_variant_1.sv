//SystemVerilog
module Hamming31_26_Pipelined (
    input clk,
    input [25:0] data_in,
    output reg [30:0] encoded_out,
    input [30:0] received_in,
    output reg [25:0] decoded_out
);
    // 流水线寄存器
    reg [30:0] enc_stage1, enc_stage2;
    reg [30:0] dec_stage1, dec_stage2;
    reg [4:0] syndrome;
    
    // 带状进位加法器信号
    wire [4:0] syndrome_wire;
    wire [30:0] error_position;
    
    // 参数掩码生成函数实现
    function [30:0] parity_mask_31_26;
        input [2:0] pos;
        begin
            case(pos)
                3'd0: parity_mask_31_26 = 31'h55555555; // 奇数位置的位
                3'd1: parity_mask_31_26 = 31'h66666666; // 位2,3,6,7...
                3'd2: parity_mask_31_26 = 31'h78787878; // 位4-7,12-15...
                3'd3: parity_mask_31_26 = 31'h7F807F80; // 位8-15,24-31...
                3'd4: parity_mask_31_26 = 31'h7FFF8000; // 位16-31
                default: parity_mask_31_26 = 31'h0;
            endcase
        end
    endfunction
    
    // 带状进位加法器实现 - 计算校验位综合征
    CLA_Syndrome_Calculator syndrome_calc (
        .received_data(received_in),
        .syndrome(syndrome_wire)
    );
    
    // 使用带状进位加法器实现错误位置计算
    CLA_Error_Position error_pos_calc (
        .syndrome(syndrome_wire),
        .error_position(error_position)
    );
    
    integer i;
    
    // 合并的流水线实现
    always @(posedge clk) begin
        // 编码流水线 - Stage 1: Data expansion
        enc_stage1[30:5] <= data_in[25:0];
        enc_stage1[4:0] <= 5'b0;
        
        // 解码流水线 - Stage 1: 存储接收数据
        dec_stage1 <= received_in;
        syndrome <= syndrome_wire;
        
        // 编码流水线 - Stage 2: Parity calculation
        enc_stage2 <= enc_stage1;
        for(i=0; i<5; i=i+1) begin
            enc_stage2[2**i -1] <= ^(enc_stage1 & parity_mask_31_26(i));
        end
        
        // 解码流水线 - Stage 2: 纠正错误
        dec_stage2 <= dec_stage1;
        if(|syndrome) begin
            dec_stage2 <= dec_stage1 ^ error_position;
        end
        
        // 编码流水线 - Stage 3: Final output
        encoded_out <= enc_stage2;
        
        // 解码流水线 - Stage 3: 提取数据
        decoded_out <= {dec_stage2[30:16], dec_stage2[14:8], dec_stage2[6:5]};
    end
endmodule

// 带状进位加法器实现 - 计算校验位综合征
module CLA_Syndrome_Calculator (
    input [30:0] received_data,
    output [4:0] syndrome
);
    // 生成位 (Generate) 和 传播位 (Propagate)
    wire [4:0][30:0] G, P;
    wire [4:0][4:0] C; // 进位信号
    
    genvar i, j;
    generate
        for (i = 0; i < 5; i = i + 1) begin : gen_GP
            // 计算每个校验位的掩码数据
            wire [30:0] masked_data;
            
            case(i)
                0: assign masked_data = received_data & 31'h55555555;
                1: assign masked_data = received_data & 31'h66666666;
                2: assign masked_data = received_data & 31'h78787878;
                3: assign masked_data = received_data & 31'h7F807F80;
                4: assign masked_data = received_data & 31'h7FFF8000;
            endcase
            
            // 初始生成位和传播位
            assign G[i][0] = masked_data[0];
            assign P[i][0] = 1'b0; // XOR操作不需要传播位
            
            // 带状进位加法用于校验位计算
            for (j = 1; j < 31; j = j + 1) begin : gen_GP_bits
                assign G[i][j] = masked_data[j];
                assign P[i][j] = G[i][j-1] ^ P[i][j-1];
            end
            
            // 计算校验位结果
            assign syndrome[i] = (P[i][30] ^ G[i][30]) ^ received_data[2**i-1];
        end
    endgenerate
endmodule

// 带状进位加法器实现 - 错误位置计算
module CLA_Error_Position (
    input [4:0] syndrome,
    output [30:0] error_position
);
    // 使用带状进位加法器计算错误位置
    wire [4:0] C;  // 内部进位信号
    wire [4:0] G, P;  // 生成位和传播位
    
    // 初始化进位
    assign C[0] = syndrome[0];
    
    // 生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_GP_stages
            assign G[i] = syndrome[i];
            assign P[i] = syndrome[i+1];
            
            // 带状进位计算
            assign C[i+1] = G[i] | (P[i] & C[i]);
        end
    endgenerate
    
    // 错误位置译码
    assign error_position = (|syndrome) ? (1'b1 << {syndrome[4:1], C[4]}) : 31'h0;
endmodule