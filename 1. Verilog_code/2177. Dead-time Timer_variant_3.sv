//SystemVerilog
//IEEE 1364-2005 Verilog standard
module deadtime_timer (
    // Clock and reset
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI-Stream input interface
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    
    // AXI-Stream output interface
    output wire [1:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);
    // 从AXI-Stream数据中提取配置
    wire [15:0] period   = s_axis_tdata[15:0];
    wire [15:0] duty     = s_axis_tdata[31:16];
    wire [7:0]  deadtime = s_axis_tdata[23:16]; // 复用部分位域
    
    // 配置接收状态
    reg config_received;
    
    // AXI-Stream输入握手逻辑
    assign s_axis_tready = !config_received || m_axis_tready;
    
    // 内部寄存器信号
    reg [15:0] counter;
    
    // 组合逻辑信号
    wire compare_match;
    wire high_enable;
    wire low_enable;
    
    // PWM输出信号
    reg pwm_high, pwm_low;
    
    // 将输出信号映射到AXI-Stream
    assign m_axis_tdata = {pwm_low, pwm_high};
    assign m_axis_tlast = (counter == period - 1); // 每个周期结束时发送TLAST
    
    // 配置寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            config_received <= 1'b0;
        else if (s_axis_tvalid && s_axis_tready)
            config_received <= 1'b1;
    end
    
    // 计数器时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            counter <= 16'd0;
        else if (config_received)
            counter <= (counter >= period - 1) ? 16'd0 : counter + 16'd1;
    end
    
    // 组合逻辑 - PWM比较和使能信号生成
    assign compare_match = (counter < duty);
    assign high_enable = compare_match & (counter >= deadtime);
    assign low_enable = ~compare_match & (counter >= (period - deadtime) || counter < (period - duty));
    
    // 输出寄存器时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            pwm_high <= 1'b0; 
            pwm_low <= 1'b0; 
        end
        else if (config_received) begin
            pwm_high <= high_enable;
            pwm_low <= low_enable;
        end
    end
    
    // AXI-Stream输出有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            m_axis_tvalid <= 1'b0;
        else if (config_received)
            m_axis_tvalid <= 1'b1;
        else if (m_axis_tready)
            m_axis_tvalid <= 1'b0;
    end
    
endmodule