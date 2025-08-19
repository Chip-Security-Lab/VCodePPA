//SystemVerilog
module crc_gated_clock (
    input clk,
    input valid,
    output reg ready,
    input [7:0] data,
    output reg [15:0] crc
);

// 第一级流水线 - 初始计算
reg [15:0] crc_stage1;
reg valid_stage1;
reg [7:0] data_stage1;
reg crc_msb_stage1;

// 第二级流水线 - 条件计算准备
reg [15:0] shift_result_stage2;
reg valid_stage2;
reg crc_msb_stage2;
reg [7:0] data_stage2;

// 第三级流水线 - XOR运算
reg [15:0] xor_result_stage3;
reg valid_stage3;

// 第四级流水线 - 最终CRC结果
reg [15:0] crc_stage4;
reg ready_stage4;

// 第一级流水线 - 保存输入和MSB
always @(posedge clk) begin
    valid_stage1 <= valid;
    if (valid) begin
        crc_stage1 <= crc;
        data_stage1 <= data;
        crc_msb_stage1 <= crc[15];
    end
end

// 第二级流水线 - 准备移位结果
always @(posedge clk) begin
    valid_stage2 <= valid_stage1;
    if (valid_stage1) begin
        shift_result_stage2 <= {crc_stage1[14:0], 1'b0};
        crc_msb_stage2 <= crc_msb_stage1;
        data_stage2 <= data_stage1;
    end
end

// 第三级流水线 - 执行XOR运算
always @(posedge clk) begin
    valid_stage3 <= valid_stage2;
    if (valid_stage2) begin
        xor_result_stage3 <= shift_result_stage2 ^ 
                           (crc_msb_stage2 ? 16'h8005 : 16'h0000) ^
                           {8'h00, data_stage2};
    end
end

// 第四级流水线 - 最终结果
always @(posedge clk) begin
    if (valid_stage3) begin
        crc_stage4 <= xor_result_stage3;
        ready_stage4 <= 1'b1;
    end else begin
        ready_stage4 <= 1'b0;
    end
    
    // 输出赋值
    crc <= crc_stage4;
    ready <= ready_stage4;
end

endmodule