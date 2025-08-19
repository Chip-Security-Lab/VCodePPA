//SystemVerilog
module capture_timer (
    input  wire        clk_i,         // 系统时钟
    input  wire        rst_i,         // 异步复位
    input  wire        en_i,          // 计数使能
    input  wire        capture_i,     // 捕获输入信号
    output reg  [31:0] value_o,       // 当前计数值
    output reg  [31:0] capture_o,     // 捕获的计数值
    output reg         capture_valid_o // 捕获有效信号
);

    // 流水线寄存器和信号
    reg capture_stage1, capture_stage2;
    reg en_stage1, en_stage2;
    reg [31:0] value_stage1, value_stage2;
    reg capture_event_stage1, capture_event_stage2;
    reg valid_stage1, valid_stage2;
    
    // 第一级流水线：信号采样和边沿检测
    always @(posedge clk_i) begin
        if (rst_i) begin
            capture_stage1 <= 1'b0;
            capture_stage2 <= 1'b0;
            en_stage1 <= 1'b0;
            value_stage1 <= 32'h0;
            capture_event_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            capture_stage1 <= capture_i;
            capture_stage2 <= capture_stage1;
            en_stage1 <= en_i;
            value_stage1 <= value_o;
            capture_event_stage1 <= capture_i & ~capture_stage1; // 上升沿检测
            valid_stage1 <= 1'b1; // 第一级流水线总是有效
        end
    end
    
    // 第二级流水线：值更新和捕获处理
    always @(posedge clk_i) begin
        if (rst_i) begin
            en_stage2 <= 1'b0;
            value_stage2 <= 32'h0;
            capture_event_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            en_stage2 <= en_stage1;
            value_stage2 <= value_stage1;
            capture_event_stage2 <= capture_event_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 最终输出级：计数器更新和捕获输出
    always @(posedge clk_i) begin
        if (rst_i) begin
            value_o <= 32'h0;
            capture_o <= 32'h0;
            capture_valid_o <= 1'b0;
        end
        else begin
            // 计数器更新，引用第二级流水线的使能信号
            if (en_stage2)
                value_o <= value_o + 32'h1;
                
            // 捕获输出处理
            capture_valid_o <= valid_stage2 & capture_event_stage2;
            
            // 当捕获事件发生时更新捕获值
            if (valid_stage2 & capture_event_stage2)
                capture_o <= value_stage2;
        end
    end

endmodule