//SystemVerilog
module hamming_decoder_16bit(
    input clk, rst,
    input [21:0] encoded,
    output reg [15:0] decoded,
    output reg [4:0] error_pos,
    // 流水线控制信号
    input valid_in,
    output reg valid_out,
    input ready_in,
    output reg ready_out
);
    // 第一级流水线寄存器
    reg [21:0] encoded_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [21:0] encoded_stage2;
    reg [4:0] syndrome_stage2;
    reg valid_stage2;
    
    // 第三级流水线寄存器（输出级）
    reg [21:0] encoded_stage3;
    reg [4:0] syndrome_stage3;
    
    // 流水线控制逻辑
    always @(*) begin
        ready_out = (valid_stage1 == 1'b0) || (ready_in == 1'b1 && valid_stage2 == 1'b0);
    end
    
    // 第一级流水线：数据输入和部分校验位计算
    always @(posedge clk) begin
        if (rst) begin
            encoded_stage1 <= 22'b0;
            valid_stage1 <= 1'b0;
        end else if (ready_out && valid_in) begin
            encoded_stage1 <= encoded;
            valid_stage1 <= 1'b1;
        end else if (valid_stage1 && (!valid_stage2 || (valid_stage2 && ready_in))) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线：完成校验位计算并生成syndrome
    always @(posedge clk) begin
        if (rst) begin
            encoded_stage2 <= 22'b0;
            syndrome_stage2 <= 5'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1 && (!valid_stage2 || (valid_stage2 && ready_in))) begin
            encoded_stage2 <= encoded_stage1;
            
            // 计算syndrome - 分阶段计算以减少每级负载
            syndrome_stage2[0] <= ^(encoded_stage1 & 22'b0101_0101_0101_0101_0101_0);
            syndrome_stage2[1] <= ^(encoded_stage1 & 22'b0110_0110_0110_0110_0110_0);
            syndrome_stage2[2] <= ^(encoded_stage1 & 22'b0111_1000_0111_1000_0111_1);
            syndrome_stage2[3] <= ^(encoded_stage1 & 22'b0111_1111_1000_0000_0000_0);
            syndrome_stage2[4] <= ^encoded_stage1;
            
            valid_stage2 <= 1'b1;
        end else if (valid_stage2 && ready_in) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线：完成数据解码和错误位置确定
    always @(posedge clk) begin
        if (rst) begin
            encoded_stage3 <= 22'b0;
            syndrome_stage3 <= 5'b0;
            decoded <= 16'b0;
            error_pos <= 5'b0;
            valid_out <= 1'b0;
        end else if (valid_stage2 && ready_in) begin
            encoded_stage3 <= encoded_stage2;
            syndrome_stage3 <= syndrome_stage2;
            
            // 错误位置传递
            error_pos <= syndrome_stage2;
            
            // 解码逻辑
            decoded <= {encoded_stage2[21:17], encoded_stage2[15:9], encoded_stage2[7:4], encoded_stage2[2]};
            
            valid_out <= 1'b1;
        end else if (valid_out && ready_in) begin
            valid_out <= 1'b0;
        end
    end
endmodule