//SystemVerilog
// SystemVerilog
module threshold_alert_range_detector(
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output reg [1:0] alert_level // 00:normal, 01:warning, 10:critical
);
    // 使用寄存器存储比较结果以减少组合逻辑深度
    reg less_than_crit_low, more_than_crit_high;
    reg less_than_warn_low, more_than_warn_high;
    reg in_critical, in_warning;
    
    // 使用显式多路复用器来确定下一个警报级别
    reg [1:0] next_alert;
    wire [1:0] critical_value = 2'b10;
    wire [1:0] warning_value = 2'b01;
    wire [1:0] normal_value = 2'b00;
    wire critical_select = in_critical;
    wire warning_select = in_warning & ~in_critical;
    wire normal_select = ~in_warning & ~in_critical;
    
    // 比较逻辑
    always @(*) begin
        less_than_crit_low = (sensor_data < critical_low);
        more_than_crit_high = (sensor_data > critical_high);
        less_than_warn_low = (sensor_data < warning_low);
        more_than_warn_high = (sensor_data > warning_high);
        
        // 确定警报条件
        in_critical = less_than_crit_low | more_than_crit_high;
        in_warning = (less_than_warn_low & ~less_than_crit_low) | 
                    (more_than_warn_high & ~more_than_crit_high);
                    
        // 显式多路复用器实现alert级别选择
        next_alert = ({2{critical_select}} & critical_value) |
                     ({2{warning_select}} & warning_value) |
                     ({2{normal_select}} & normal_value);
    end
    
    // 时序逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) 
            alert_level <= 2'b00;
        else 
            alert_level <= next_alert;
    end
endmodule