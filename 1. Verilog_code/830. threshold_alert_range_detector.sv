module threshold_alert_range_detector(
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output reg [1:0] alert_level // 00:normal, 01:warning, 10:critical
);
    // Normal range: value is between warning thresholds
    wire in_normal = (sensor_data >= warning_low) && (sensor_data <= warning_high);
    
    // Warning range: value is outside normal range but within critical thresholds
    wire in_warning = ((sensor_data >= critical_low) && (sensor_data < warning_low)) || 
                      ((sensor_data > warning_high) && (sensor_data <= critical_high));
    
    // Critical range: value is outside both normal and warning ranges
    wire in_critical = (sensor_data < critical_low) || (sensor_data > critical_high);
    
    always @(posedge clk or posedge rst) begin
        if (rst) alert_level <= 2'b00;
        else alert_level <= {in_critical, in_warning};
    end
endmodule