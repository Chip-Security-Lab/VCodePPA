//SystemVerilog
module param_hamming_encoder #(
    parameter DATA_WIDTH = 4
)(
    input clk, enable,
    input [DATA_WIDTH-1:0] data,
    output reg [(DATA_WIDTH+4):0] encoded, // 简化的位宽计算，增加额外的位
    output reg valid_out
);
    // 流水线阶段1：寄存数据和计算校验位
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [3:0] parity_bits_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：产生最终的编码输出
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [3:0] parity_bits_stage2;
    reg valid_stage2;
    
    integer i, j, k;
    
    // 流水线第一阶段：数据寄存和校验位计算
    always @(posedge clk) begin
        if (enable) begin
            // 寄存输入数据
            data_stage1 <= data;
            
            // 计算校验位
            parity_bits_stage1[0] <= ^(data & 4'b0101);
            parity_bits_stage1[1] <= ^(data & 4'b0110);
            parity_bits_stage1[2] <= ^(data & 4'b1100);
            parity_bits_stage1[3] <= ^data;
            
            // 设置有效信号
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // 流水线第二阶段：传递计算结果到第二级
    always @(posedge clk) begin
        data_stage2 <= data_stage1;
        parity_bits_stage2 <= parity_bits_stage1;
        valid_stage2 <= valid_stage1;
    end
    
    // 流水线第三阶段：组装最终编码输出
    always @(posedge clk) begin
        if (valid_stage2) begin
            // 填充数据位和校验位
            j = 0;
            for (i = 0; i < DATA_WIDTH+4; i = i + 1) begin
                // 位置是2的幂则为校验位
                k = i + 1;
                if (k == 1 || k == 2 || k == 4 || k == 8)
                    encoded[i] <= parity_bits_stage2[k>>1];
                else if (j < DATA_WIDTH) begin
                    encoded[i] <= data_stage2[j];
                    j = j + 1;
                end
            end
        end
        // 传递有效信号到输出
        valid_out <= valid_stage2;
    end
endmodule