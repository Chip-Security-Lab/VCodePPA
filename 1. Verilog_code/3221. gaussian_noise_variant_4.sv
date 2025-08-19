//SystemVerilog
module gaussian_noise(
    input clk,
    input rst,
    output reg [7:0] noise_out
);
    reg [15:0] lfsr1, lfsr2;
    reg [7:0] noise_lut [0:3]; // 查找表，用于预计算可能的噪声输出
    reg [1:0] lut_index;       // 查找表索引
    
    // 使用XOR进行反馈计算
    wire fb1, fb2;
    assign fb1 = lfsr1[15] ^ lfsr1[14] ^ lfsr1[12] ^ lfsr1[3];
    assign fb2 = lfsr2[15] ^ lfsr2[13] ^ lfsr2[11] ^ lfsr2[7];
    
    // 使用查找表进行噪声值选择
    always @(posedge clk) begin
        if (rst) begin
            lfsr1 <= 16'hACE1;
            lfsr2 <= 16'h1234;
            noise_out <= 8'h80;
            
            // 初始化查找表
            noise_lut[0] <= 8'h80;
            noise_lut[1] <= 8'h40;
            noise_lut[2] <= 8'hC0;
            noise_lut[3] <= 8'h20;
            lut_index <= 2'b00;
        end else begin
            // 更新LFSR
            lfsr1 <= {lfsr1[14:0], fb1};
            lfsr2 <= {lfsr2[14:0], fb2};
            
            // 生成查找表索引
            lut_index <= {lfsr1[0], lfsr2[0]};
            
            // 使用预先计算的噪声值，然后基于LFSR添加随机性
            noise_out <= noise_lut[lut_index] + {1'b0, lfsr1[7:1]} + {1'b0, lfsr2[7:1]};
        end
    end
endmodule