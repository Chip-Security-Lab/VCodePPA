//SystemVerilog IEEE 1364-2005
module Demux_Timeout #(parameter DW=8, TIMEOUT=100) (
    input clk, rst,
    input valid,
    input [DW-1:0] data_in,
    input [3:0] addr,
    output reg [15:0][DW-1:0] data_out,
    output reg timeout
);
    // 流水线阶段1寄存器
    reg valid_stage1;
    reg [DW-1:0] data_in_stage1;
    reg [3:0] addr_stage1;
    
    // 流水线阶段2寄存器
    reg valid_stage2;
    reg [DW-1:0] data_in_stage2;
    reg [3:0] addr_stage2;
    
    // 流水线阶段3寄存器
    reg valid_stage3;
    reg [DW-1:0] data_in_stage3;
    reg [3:0] addr_stage3;
    
    // 流水线阶段4寄存器
    reg valid_stage4;
    reg [DW-1:0] data_in_stage4;
    reg [3:0] addr_stage4;
    
    // 计数器和超时检测逻辑分段
    reg [7:0] counter_stage1;
    reg [7:0] counter_stage2;
    reg timeout_detected_stage2;
    reg timeout_detected_stage3;
    reg timeout_detected_stage4;
    
    // 流水线阶段1：输入捕获和计数器初始处理
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 0;
            data_in_stage1 <= 0;
            addr_stage1 <= 0;
            counter_stage1 <= 0;
        end else begin
            valid_stage1 <= valid;
            data_in_stage1 <= data_in;
            addr_stage1 <= addr;
            
            if (valid) begin
                counter_stage1 <= 0;
            end else begin
                counter_stage1 <= (counter_stage1 < TIMEOUT/2) ? counter_stage1 + 1 : counter_stage1;
            end
        end
    end
    
    // 流水线阶段2：计数器进一步处理和超时检测第一部分
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 0;
            data_in_stage2 <= 0;
            addr_stage2 <= 0;
            counter_stage2 <= 0;
            timeout_detected_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            data_in_stage2 <= data_in_stage1;
            addr_stage2 <= addr_stage1;
            
            if (valid_stage1) begin
                counter_stage2 <= 0;
                timeout_detected_stage2 <= 0;
            end else begin
                counter_stage2 <= (counter_stage1 >= TIMEOUT/2) ? 
                                 ((counter_stage2 < TIMEOUT) ? counter_stage2 + 1 : TIMEOUT) : 
                                 counter_stage1 + 1;
                timeout_detected_stage2 <= (counter_stage2 == TIMEOUT-2);
            end
        end
    end
    
    // 流水线阶段3：超时检测第二部分和地址解码准备
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 0;
            data_in_stage3 <= 0;
            addr_stage3 <= 0;
            timeout_detected_stage3 <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            data_in_stage3 <= data_in_stage2;
            addr_stage3 <= addr_stage2;
            timeout_detected_stage3 <= timeout_detected_stage2 || (counter_stage2 == TIMEOUT-1);
        end
    end
    
    // 流水线阶段4：输出准备和最终超时判断
    always @(posedge clk) begin
        if (rst) begin
            valid_stage4 <= 0;
            data_in_stage4 <= 0;
            addr_stage4 <= 0;
            timeout_detected_stage4 <= 0;
        end else begin
            valid_stage4 <= valid_stage3;
            data_in_stage4 <= data_in_stage3;
            addr_stage4 <= addr_stage3;
            timeout_detected_stage4 <= timeout_detected_stage3;
        end
    end
    
    // 流水线阶段5：输出寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 0;
            timeout <= 0;
        end else begin
            timeout <= timeout_detected_stage4;
            
            if (valid_stage4) begin
                data_out[addr_stage4] <= data_in_stage4;
            end else if (timeout_detected_stage4) begin
                data_out <= 0;
            end
        end
    end
    
endmodule