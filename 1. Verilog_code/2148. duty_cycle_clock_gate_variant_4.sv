//SystemVerilog
module duty_cycle_clock_gate (
    input  wire       clk_in,
    input  wire       rst_n,
    input  wire [2:0] duty_ratio,
    input  wire       valid_in,    // 输入有效信号
    output wire       ready_out,   // 输出就绪信号
    output wire       clk_out,
    output wire       valid_out    // 输出有效信号
);
    reg [2:0] phase;
    reg enable;
    reg data_valid;
    reg [2:0] duty_ratio_reg;
    
    // 握手逻辑 - 当valid_in有效时，可以接收新的数据
    assign ready_out = 1'b1;  // 本模块总是准备好接收新数据
    
    // 捕获输入数据并维护valid状态
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            data_valid <= 1'b0;
            duty_ratio_reg <= 3'd0;
        end
        else if (valid_in && ready_out) begin
            data_valid <= 1'b1;
            duty_ratio_reg <= duty_ratio;
        end
    end
    
    // 相位计数器
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            phase <= 3'd0;
        end
        else if (data_valid) begin
            phase <= (phase == 3'd7) ? 3'd0 : (phase + 1'b1);
        end
    end
    
    // 预计算使能信号以减少关键路径延迟
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable <= 1'b0;
        end
        else if (data_valid) begin
            // 使用比较器结构优化比较逻辑
            // 在下一个时钟边沿之前预先计算使能信号
            enable <= (phase == 3'd7) ? (duty_ratio_reg > 3'd0) : 
                      ((phase + 1'b1) < duty_ratio_reg);
        end
    end
    
    // 使用预计算的使能信号
    assign clk_out = (clk_in & enable & data_valid);
    
    // 输出valid信号
    assign valid_out = data_valid;
endmodule