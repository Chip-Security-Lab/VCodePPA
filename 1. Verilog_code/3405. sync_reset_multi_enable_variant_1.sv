//SystemVerilog
module watchdog_reset_gen #(
    parameter TIMEOUT = 8
)(
    input wire clk,
    input wire rst_n,
    input wire watchdog_kick,
    input wire enable,
    output reg watchdog_reset,
    output reg valid_out
);
    // 内部信号
    reg [3:0] counter;
    wire timeout_detected;
    
    // 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end
        else if (enable) begin
            if (watchdog_kick)
                counter <= 0;
            else if (counter < TIMEOUT)
                counter <= counter + 1'b1;
        end
    end
    
    // 在组合逻辑阶段提前检测超时
    assign timeout_detected = (counter >= TIMEOUT);
    
    // 流水线寄存器: 传递超时检测信号
    reg timeout_detected_r1;
    reg timeout_detected_r2;
    reg timeout_detected_r3;
    
    // 流水线寄存器: 传递有效信号
    reg valid_r1;
    reg valid_r2;
    reg valid_r3;
    
    // 流水线寄存器阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_detected_r1 <= 0;
            valid_r1 <= 0;
        end
        else if (enable) begin
            timeout_detected_r1 <= timeout_detected;
            valid_r1 <= 1'b1;
        end
    end
    
    // 流水线寄存器阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_detected_r2 <= 0;
            valid_r2 <= 0;
        end
        else if (enable) begin
            timeout_detected_r2 <= timeout_detected_r1;
            valid_r2 <= valid_r1;
        end
    end
    
    // 流水线寄存器阶段3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout_detected_r3 <= 0;
            valid_r3 <= 0;
        end
        else if (enable) begin
            timeout_detected_r3 <= timeout_detected_r2;
            valid_r3 <= valid_r2;
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            watchdog_reset <= 0;
            valid_out <= 0;
        end
        else if (enable) begin
            watchdog_reset <= timeout_detected_r3;
            valid_out <= valid_r3;
        end
    end
endmodule