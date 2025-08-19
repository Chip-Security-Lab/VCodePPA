//SystemVerilog
module timeout_ismu(
    input clk, rst_n,
    input [3:0] irq_in,
    input [3:0] irq_mask,
    input [7:0] timeout_val,
    input ready,                 // 接收方准备好接收数据的信号
    output reg valid,            // 数据有效信号
    output reg [3:0] irq_out,
    output reg timeout_flag
);
    reg [7:0] counter [3:0];
    reg [3:0] active_irq;
    reg [3:0] timeout_detect;
    reg data_sent;               // 指示数据是否已发送
    integer i;
    
    // Pre-compute active IRQs to reduce combinational depth
    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            active_irq[i] = irq_in[i] && !irq_mask[i];
            timeout_detect[i] = (counter[i] >= timeout_val) && active_irq[i];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_out <= 4'h0;
            timeout_flag <= 1'b0;
            valid <= 1'b0;
            data_sent <= 1'b0;
            for (i = 0; i < 4; i = i + 1)
                counter[i] <= 8'h0;
        end else begin
            // Default values
            timeout_flag <= |timeout_detect;
            
            // Valid-Ready握手逻辑
            if (valid && ready) begin
                valid <= 1'b0;         // 接收方接收数据后，取消valid信号
                data_sent <= 1'b1;     // 标记数据已发送
            end
            
            for (i = 0; i < 4; i = i + 1) begin
                if (active_irq[i]) begin
                    // Counter hasn't reached timeout value yet
                    if (counter[i] < timeout_val) begin
                        counter[i] <= counter[i] + 8'h1;
                        irq_out[i] <= 1'b0;
                    end 
                    // Counter reached timeout value
                    else begin
                        counter[i] <= counter[i];
                        
                        // 当检测到超时并且数据尚未发送或已完成传输时
                        if (!valid || (valid && ready)) begin
                            irq_out[i] <= 1'b1;
                            valid <= 1'b1;       // 设置valid信号表示数据有效
                            data_sent <= 1'b0;   // 重置数据发送标志
                        end
                    end
                end else begin
                    counter[i] <= 8'h0;
                    irq_out[i] <= 1'b0;
                    if (i == 3 && !active_irq) begin
                        data_sent <= 1'b0;       // 当所有IRQ都不活跃时重置数据发送标志
                    end
                end
            end
        end
    end
endmodule