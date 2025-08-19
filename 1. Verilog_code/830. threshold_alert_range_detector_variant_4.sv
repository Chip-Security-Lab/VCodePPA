//SystemVerilog
module threshold_alert_range_detector(
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output reg [1:0] alert_level // 00:normal, 01:warning, 10:critical
);
    // 注册输入信号，将寄存器前移到组合逻辑之前
    reg [15:0] sensor_data_reg;
    reg [15:0] warning_low_reg, warning_high_reg;
    reg [15:0] critical_low_reg, critical_high_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sensor_data_reg <= 16'b0;
            warning_low_reg <= 16'b0;
            warning_high_reg <= 16'b0;
            critical_low_reg <= 16'b0;
            critical_high_reg <= 16'b0;
        end else begin
            sensor_data_reg <= sensor_data;
            warning_low_reg <= warning_low;
            warning_high_reg <= warning_high;
            critical_low_reg <= critical_low;
            critical_high_reg <= critical_high;
        end
    end
    
    // 使用已注册的信号进行组合逻辑计算
    wire in_normal = (sensor_data_reg >= warning_low_reg) && (sensor_data_reg <= warning_high_reg);
    
    wire in_warning = ((sensor_data_reg >= critical_low_reg) && (sensor_data_reg < warning_low_reg)) || 
                      ((sensor_data_reg > warning_high_reg) && (sensor_data_reg <= critical_high_reg));
    
    wire in_critical = (sensor_data_reg < critical_low_reg) || (sensor_data_reg > critical_high_reg);
    
    always @(posedge clk or posedge rst) begin
        if (rst) alert_level <= 2'b00;
        else alert_level <= {in_critical, in_warning};
    end
endmodule