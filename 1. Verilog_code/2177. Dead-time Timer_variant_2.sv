//SystemVerilog
module deadtime_timer (
    input wire clk, rst_n,
    
    // AXI-Stream 输入接口
    input wire [15:0] s_axis_tdata,  // 输入数据（period/duty/deadtime）
    input wire [1:0] s_axis_tuser,   // 用户信号，指示数据类型：00=period, 01=duty, 10=deadtime
    input wire s_axis_tvalid,        // 输入数据有效
    output wire s_axis_tready,       // 模块准备接收数据
    
    // AXI-Stream 输出接口
    output wire [1:0] m_axis_tdata,  // 输出数据 [pwm_high, pwm_low]
    output wire m_axis_tvalid,       // 输出数据有效
    input wire m_axis_tready         // 下游模块准备接收数据
);
    reg [15:0] period_reg, duty_reg;
    reg [7:0] deadtime_reg;
    reg [15:0] counter;
    wire compare_match;
    wire deadtime_expired;
    wire low_active_region;
    reg pwm_high, pwm_low;
    
    // 接收数据状态控制
    assign s_axis_tready = 1'b1;  // 始终准备好接收新配置
    
    // 根据s_axis_tuser类型更新相应的寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_reg <= 16'd0;
            duty_reg <= 16'd0;
            deadtime_reg <= 8'd0;
        end
        else if (s_axis_tvalid && s_axis_tready) begin
            case (s_axis_tuser)
                2'b00: period_reg <= s_axis_tdata;
                2'b01: duty_reg <= s_axis_tdata;
                2'b10: deadtime_reg <= s_axis_tdata[7:0];
                default: ; // 保持不变
            endcase
        end
    end
    
    // 优化计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 16'd0;
        else if (counter == period_reg - 16'd1)  // 直接比较等于而不是大于等于
            counter <= 16'd0;
        else
            counter <= counter + 16'd1;
    end
    
    // 优化比较链
    assign compare_match = (counter < duty_reg);
    assign deadtime_expired = (counter >= {8'd0, deadtime_reg});
    // 使用范围检查代替复杂的条件
    assign low_active_region = (counter < (period_reg - duty_reg)) || 
                              (counter >= (period_reg - {8'd0, deadtime_reg}));
    
    // 生成PWM输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            pwm_high <= 1'b0; 
            pwm_low <= 1'b0; 
        end
        else begin
            // 使用优化后的比较信号生成PWM输出
            pwm_high <= compare_match & deadtime_expired;
            pwm_low <= ~compare_match & low_active_region;
        end
    end
    
    // AXI-Stream 输出控制
    assign m_axis_tdata = {pwm_high, pwm_low};
    assign m_axis_tvalid = 1'b1;  // PWM输出始终有效
    
endmodule