//SystemVerilog
module threshold_alert_range_detector(
    input wire clk, rst,
    input wire [15:0] sensor_data,
    input wire [15:0] warning_low, warning_high,
    input wire [15:0] critical_low, critical_high,
    output reg [1:0] alert_level, // 00:normal, 01:warning, 10:critical
    output reg valid_out
);
    // Pipeline registers for input data
    reg [15:0] sensor_data_stage1;
    reg [15:0] warning_low_stage1, warning_high_stage1;
    reg [15:0] critical_low_stage1, critical_high_stage1;
    reg valid_stage1;
    
    // Pipeline registers for comparison results
    reg lower_than_critical_low_stage2;
    reg greater_than_critical_high_stage2;
    reg lower_than_warning_low_stage2;
    reg greater_than_warning_high_stage2;
    reg valid_stage2;
    
    // Pipeline registers for final calculation
    reg in_normal_stage3;
    reg in_warning_stage3;
    reg in_critical_stage3;
    reg valid_stage3;
    
    // Stage 1: Register inputs and generate valid signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sensor_data_stage1 <= 16'b0;
            warning_low_stage1 <= 16'b0;
            warning_high_stage1 <= 16'b0;
            critical_low_stage1 <= 16'b0;
            critical_high_stage1 <= 16'b0;
            valid_stage1 <= 1'b0;
        end else begin
            sensor_data_stage1 <= sensor_data;
            warning_low_stage1 <= warning_low;
            warning_high_stage1 <= warning_high;
            critical_low_stage1 <= critical_low;
            critical_high_stage1 <= critical_high;
            valid_stage1 <= 1'b1; // Data is valid every cycle after reset
        end
    end
    
    // Stage 2: Perform basic comparisons
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lower_than_critical_low_stage2 <= 1'b0;
            greater_than_critical_high_stage2 <= 1'b0;
            lower_than_warning_low_stage2 <= 1'b0;
            greater_than_warning_high_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            lower_than_critical_low_stage2 <= (sensor_data_stage1 < critical_low_stage1);
            greater_than_critical_high_stage2 <= (sensor_data_stage1 > critical_high_stage1);
            lower_than_warning_low_stage2 <= (sensor_data_stage1 < warning_low_stage1);
            greater_than_warning_high_stage2 <= (sensor_data_stage1 > warning_high_stage1);
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Calculate final range conditions
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_normal_stage3 <= 1'b0;
            in_warning_stage3 <= 1'b0;
            in_critical_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            in_normal_stage3 <= !lower_than_warning_low_stage2 && !greater_than_warning_high_stage2;
            in_warning_stage3 <= (lower_than_warning_low_stage2 && !lower_than_critical_low_stage2) || 
                                (greater_than_warning_high_stage2 && !greater_than_critical_high_stage2);
            in_critical_stage3 <= lower_than_critical_low_stage2 || greater_than_critical_high_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final stage: Generate output alert level
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alert_level <= 2'b00;
            valid_out <= 1'b0;
        end else begin
            alert_level <= {in_critical_stage3, in_warning_stage3};
            valid_out <= valid_stage3;
        end
    end
endmodule