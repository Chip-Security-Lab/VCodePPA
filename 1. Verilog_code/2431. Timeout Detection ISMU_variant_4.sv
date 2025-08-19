//SystemVerilog
module timeout_ismu(
    input wire clk, rst_n,
    // Valid-Ready接口
    input wire valid_in,
    output reg ready_out,
    input wire [3:0] irq_in,
    input wire [3:0] irq_mask,
    input wire [7:0] timeout_val,
    output reg valid_out,
    input wire ready_in,
    output reg [3:0] irq_out,
    output reg timeout_flag
);
    reg [7:0] counter [3:0];
    integer i;
    
    // 内部状态寄存器
    reg processing;
    reg [3:0] irq_in_reg;
    reg [3:0] irq_mask_reg;
    reg [7:0] timeout_val_reg;
    
    // 中间变量，用于简化条件判断
    reg input_handshake;
    reg output_handshake;
    reg [3:0] active_irq;
    reg [3:0] timeout_reached;
    reg all_irq_inactive;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_out <= 4'h0;
            timeout_flag <= 1'b0;
            for (i = 0; i < 4; i = i + 1)
                counter[i] <= 8'h0;
            processing <= 1'b0;
            ready_out <= 1'b1;
            valid_out <= 1'b0;
            irq_in_reg <= 4'h0;
            irq_mask_reg <= 4'h0;
            timeout_val_reg <= 8'h0;
        end else begin
            // 默认值
            timeout_flag <= 1'b0;
            
            // 计算中间条件变量
            input_handshake = valid_in && ready_out;
            output_handshake = valid_out && ready_in;
            
            // 计算每个中断通道的激活状态
            for (i = 0; i < 4; i = i + 1) begin
                active_irq[i] = irq_in_reg[i] && !irq_mask_reg[i];
                timeout_reached[i] = counter[i] >= timeout_val_reg;
            end
            
            // 检查是否所有中断都处于非活动状态
            all_irq_inactive = &(~irq_in_reg | irq_mask_reg);
            
            // 输入握手逻辑
            if (input_handshake) begin
                // 接收新数据
                irq_in_reg <= irq_in;
                irq_mask_reg <= irq_mask;
                timeout_val_reg <= timeout_val;
                ready_out <= 1'b0;  // 停止接收数据直到处理完成
                processing <= 1'b1;
            end
            
            // 处理逻辑
            if (processing) begin
                for (i = 0; i < 4; i = i + 1) begin
                    if (active_irq[i]) begin
                        // 中断激活且未被屏蔽
                        if (!timeout_reached[i]) begin
                            // 计数器未达到超时值
                            counter[i] <= counter[i] + 8'h1;
                        end else begin
                            // 计数器达到超时值
                            timeout_flag <= 1'b1;
                            irq_out[i] <= 1'b1;
                            valid_out <= 1'b1;  // 输出结果有效
                            processing <= 1'b0; // 处理完成
                        end
                    end else begin
                        // 中断未激活或被屏蔽
                        counter[i] <= 8'h0;
                        irq_out[i] <= 1'b0;
                    end
                end
                
                // 处理完成条件
                if (all_irq_inactive && !valid_out) begin
                    processing <= 1'b0;
                    ready_out <= 1'b1;  // 准备接收新数据
                end
            end
            
            // 输出握手逻辑
            if (output_handshake) begin
                valid_out <= 1'b0;      // 清除valid信号
                ready_out <= 1'b1;      // 准备接收新数据
            end
        end
    end
endmodule