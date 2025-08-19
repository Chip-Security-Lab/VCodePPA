//SystemVerilog
module debounced_reset #(
    parameter DEBOUNCE_COUNT = 3
)(
    input wire clk,
    input wire noisy_reset,
    output reg clean_reset
);
    // 流水线寄存器和控制信号
    reg [2:0] noisy_reset_pipe;    // 信号采样流水线
    reg [2:0] valid_pipe;          // 有效信号流水线
    reg [1:0] counter [2:0];       // 每级流水线的计数器
    reg [2:0] stable_pipe;         // 稳定性标志流水线
    
    // 流水线启动控制
    reg pipeline_ready;
    
    // 第一级流水线 - 信号采样和边缘检测
    always @(posedge clk) begin
        // 采样输入信号
        noisy_reset_pipe[0] <= noisy_reset;
        valid_pipe[0] <= 1'b1;  // 第一级始终有效
        
        // 边缘检测和计数
        if (noisy_reset_pipe[0] != noisy_reset) begin
            counter[0] <= 0;
            stable_pipe[0] <= 1'b0;
        end
        else begin
            counter[0] <= (counter[0] < DEBOUNCE_COUNT) ? counter[0] + 1'b1 : counter[0];
            stable_pipe[0] <= (counter[0] >= (DEBOUNCE_COUNT-2));
        end
    end
    
    // 第二级流水线 - 计数继续和稳定性分析
    always @(posedge clk) begin
        // 级间数据传递
        noisy_reset_pipe[1] <= noisy_reset_pipe[0];
        valid_pipe[1] <= valid_pipe[0];
        
        // 稳定性分析继续
        if (valid_pipe[0]) begin
            if (noisy_reset_pipe[1] != noisy_reset_pipe[0]) begin
                counter[1] <= 0;
                stable_pipe[1] <= 1'b0;
            end
            else begin
                counter[1] <= (counter[0] > counter[1]) ? counter[0] : 
                             ((counter[1] < DEBOUNCE_COUNT) ? counter[1] + 1'b1 : counter[1]);
                stable_pipe[1] <= stable_pipe[0] || (counter[1] >= (DEBOUNCE_COUNT-1));
            end
        end
    end
    
    // 第三级流水线 - 最终确认和输出生成
    always @(posedge clk) begin
        // 级间数据传递
        noisy_reset_pipe[2] <= noisy_reset_pipe[1];
        valid_pipe[2] <= valid_pipe[1];
        
        // 稳定性最终确认
        if (valid_pipe[1]) begin
            if (noisy_reset_pipe[2] != noisy_reset_pipe[1]) begin
                counter[2] <= 0;
                stable_pipe[2] <= 1'b0;
            end
            else begin
                counter[2] <= (counter[1] > counter[2]) ? counter[1] : 
                             ((counter[2] < DEBOUNCE_COUNT) ? counter[2] + 1'b1 : counter[2]);
                stable_pipe[2] <= stable_pipe[1] || (counter[2] >= DEBOUNCE_COUNT);
            end
        end
        
        // 输出控制 - 带前递(forwarding)机制
        if (valid_pipe[2] && stable_pipe[2]) begin
            clean_reset <= noisy_reset_pipe[2];
            pipeline_ready <= 1'b1;
        end
    end
    
    // 增加流水线状态监控和启动逻辑
    initial begin
        pipeline_ready = 1'b0;
        valid_pipe = 3'b0;
        stable_pipe = 3'b0;
        counter[0] = 0;
        counter[1] = 0;
        counter[2] = 0;
    end
endmodule