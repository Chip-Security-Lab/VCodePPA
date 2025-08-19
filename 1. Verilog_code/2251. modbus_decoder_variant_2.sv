//SystemVerilog
module modbus_decoder #(parameter TIMEOUT=1000000) (
    input wire clk,
    input wire rx,
    output reg [7:0] data,
    output reg valid,
    output reg crc_err
);
    // 计时器和状态控制
    reg [31:0] timer;
    reg [15:0] crc_stage1, crc_stage2, crc_stage3, crc_stage4;
    reg [3:0] bitcnt;
    
    // 流水线寄存器
    reg rx_stage1, rx_stage2, rx_stage3;
    reg [7:0] data_stage1, data_stage2, data_stage3;
    reg [3:0] bitcnt_stage1, bitcnt_stage2, bitcnt_stage3;
    reg [15:0] crc_temp1, crc_temp2, crc_temp3, crc_temp4;
    
    // CRC计算中间结果寄存器
    reg [15:0] crc_step1, crc_step2, crc_step3, crc_step4;
    reg [15:0] crc_step5, crc_step6, crc_step7, crc_step8;
    reg data_bit_stage1, data_bit_stage2, data_bit_stage3, data_bit_stage4;
    reg data_bit_stage5, data_bit_stage6, data_bit_stage7, data_bit_stage8;
    
    // 合并所有流水线阶段到单一always块
    always @(posedge clk) begin
        // 第一级流水线阶段：输入捕获和计时器管理
        rx_stage1 <= rx;
        
        if(rx) 
            timer <= 32'h0;
        else if(timer < TIMEOUT) 
            timer <= timer + 32'h1;
            
        bitcnt_stage1 <= bitcnt;
        data_stage1 <= data;
        crc_stage1 <= crc_stage4;
        
        // 第二级流水线阶段：数据移位和CRC计算准备
        rx_stage2 <= rx_stage1;
        bitcnt_stage2 <= bitcnt_stage1;
        
        if(bitcnt_stage1 < 8) begin
            data_stage2 <= {data_stage1[6:0], rx_stage1};
        end else begin
            data_stage2 <= data_stage1;
        end
        
        // CRC计算第一步 - 准备
        crc_temp1 <= crc_stage1 ^ {8'h00, data_stage1};
        data_bit_stage1 <= crc_temp1[0];
        
        // 第三级流水线阶段：CRC计算前半部分
        rx_stage3 <= rx_stage2;
        data_stage3 <= data_stage2;
        bitcnt_stage3 <= bitcnt_stage2;
        
        // CRC计算 - 前4步
        crc_step1 <= (crc_temp1 >> 1) ^ (data_bit_stage1 ? 16'hA001 : 16'h0000);
        data_bit_stage2 <= crc_step1[0];
        
        crc_step2 <= (crc_step1 >> 1) ^ (data_bit_stage2 ? 16'hA001 : 16'h0000);
        data_bit_stage3 <= crc_step2[0];
        
        crc_step3 <= (crc_step2 >> 1) ^ (data_bit_stage3 ? 16'hA001 : 16'h0000);
        data_bit_stage4 <= crc_step3[0];
        
        crc_step4 <= (crc_step3 >> 1) ^ (data_bit_stage4 ? 16'hA001 : 16'h0000);
        data_bit_stage5 <= crc_step4[0];
        
        // 第四级流水线阶段：CRC计算后半部分
        crc_step5 <= (crc_step4 >> 1) ^ (data_bit_stage5 ? 16'hA001 : 16'h0000);
        data_bit_stage6 <= crc_step5[0];
        
        crc_step6 <= (crc_step5 >> 1) ^ (data_bit_stage6 ? 16'hA001 : 16'h0000);
        data_bit_stage7 <= crc_step6[0];
        
        crc_step7 <= (crc_step6 >> 1) ^ (data_bit_stage7 ? 16'hA001 : 16'h0000);
        data_bit_stage8 <= crc_step7[0];
        
        crc_step8 <= (crc_step7 >> 1) ^ (data_bit_stage8 ? 16'hA001 : 16'h0000);
        
        // 保存CRC结果
        crc_stage2 <= crc_step8;
        
        // 第五级流水线阶段：状态更新和输出准备
        crc_stage3 <= crc_stage2;
        
        if(bitcnt < 8) begin
            if(bitcnt_stage3 < 8) begin
                data <= data_stage3;
                bitcnt <= bitcnt_stage3 + 4'h1;
                crc_stage4 <= crc_stage2;
            end
        end
        else if(bitcnt == 8) begin
            crc_err <= (crc_stage3 != 16'h0000);
            valid <= (crc_stage3 == 16'h0000);
            bitcnt <= 4'h0;
        end
    end
endmodule