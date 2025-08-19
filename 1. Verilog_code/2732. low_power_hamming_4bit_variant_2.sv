//SystemVerilog
module low_power_hamming_4bit(
    input clk,
    input sleep_mode,
    input [3:0] data,
    input valid_in,
    output reg valid_out,
    output reg [6:0] encoded
);
    // 时钟门控
    wire power_save_clk;
    assign power_save_clk = clk & ~sleep_mode;
    
    // 流水线阶段1寄存器
    reg [3:0] data_stage1;
    reg valid_stage1;
    
    // 流水线阶段2寄存器
    reg [3:0] data_stage2;
    reg valid_stage2;
    
    // 流水线阶段1 - 数据捕获
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data;
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线阶段2 - 奇偶校验计算
    reg parity_bit0_stage2, parity_bit1_stage2, parity_bit3_stage2;
    
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            parity_bit0_stage2 <= 1'b0;
            parity_bit1_stage2 <= 1'b0;
            parity_bit3_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
            parity_bit0_stage2 <= data_stage1[0] ^ data_stage1[1] ^ data_stage1[3];
            parity_bit1_stage2 <= data_stage1[0] ^ data_stage1[2] ^ data_stage1[3];
            parity_bit3_stage2 <= data_stage1[1] ^ data_stage1[2] ^ data_stage1[3];
        end
    end
    
    // 流水线阶段3 - 最终输出
    always @(posedge power_save_clk) begin
        if (sleep_mode) begin
            encoded <= 7'b0;
            valid_out <= 1'b0;
        end
        else begin
            valid_out <= valid_stage2;
            encoded[0] <= parity_bit0_stage2;
            encoded[1] <= parity_bit1_stage2;
            encoded[2] <= data_stage2[0];
            encoded[3] <= parity_bit3_stage2;
            encoded[4] <= data_stage2[1];
            encoded[5] <= data_stage2[2];
            encoded[6] <= data_stage2[3];
        end
    end
endmodule