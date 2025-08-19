//SystemVerilog
module pipelined_decoder(
    input wire clk,
    input wire rst_n,
    input wire [3:0] addr_in,
    output wire [15:0] decode_out
);
    // 第一级流水线 - 地址预处理
    reg [3:0] addr_stage1;
    
    // 第二级流水线 - 低位解码 (解码出低8位)
    reg [7:0] decode_low_stage2;
    
    // 第三级流水线 - 高位解码 (解码出高8位)
    reg [7:0] decode_high_stage2;
    
    // 第四级流水线 - 合并结果
    reg [15:0] decode_stage3;
    
    // 第五级流水线 - 输出级
    reg [15:0] decode_stage4;
    
    // 第一级流水线 - 存储输入地址
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr_stage1 <= 4'b0;
        else
            addr_stage1 <= addr_in;
    end
    
    // 第二级流水线 - 分别解码低位和高位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_low_stage2 <= 8'b0;
            decode_high_stage2 <= 8'b0;
        end
        else begin
            // 解码逻辑拆分为两部分，降低每级组合逻辑复杂度
            if (addr_stage1[3] == 1'b0) begin
                // 处理低8位输出 (当addr_stage1[3]=0时)
                decode_low_stage2 <= (8'b1 << addr_stage1[2:0]);
                decode_high_stage2 <= 8'b0;
            end
            else begin
                // 处理高8位输出 (当addr_stage1[3]=1时)
                decode_low_stage2 <= 8'b0;
                decode_high_stage2 <= (8'b1 << addr_stage1[2:0]);
            end
        end
    end
    
    // 第三级流水线 - 合并低位和高位结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_stage3 <= 16'b0;
        else
            decode_stage3 <= {decode_high_stage2, decode_low_stage2};
    end
    
    // 第四级流水线 - 输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_stage4 <= 16'b0;
        else
            decode_stage4 <= decode_stage3;
    end
    
    // 输出连接
    assign decode_out = decode_stage4;
    
endmodule