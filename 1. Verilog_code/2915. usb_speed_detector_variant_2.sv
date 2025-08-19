//SystemVerilog
// SystemVerilog
module usb_speed_detector(
    input wire clk,
    input wire rst_n,
    input wire dp,
    input wire dm,
    input wire detect_en,
    output reg low_speed,
    output reg full_speed,
    output reg no_device,
    output reg chirp_detected,
    output reg [1:0] detection_state
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam WAIT_STABLE = 2'b01;
    localparam DETECT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    reg [9:0] stability_counter;
    reg prev_dp, prev_dm;
    
    // 状态转换逻辑 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detection_state <= IDLE;
        end else if (detection_state == IDLE && detect_en) begin
            detection_state <= WAIT_STABLE;
        end else if (detection_state == WAIT_STABLE && dp == prev_dp && dm == prev_dm && stability_counter >= 10'd500) begin
            detection_state <= DETECT;
        end else if (detection_state == DETECT) begin
            detection_state <= COMPLETE;
        end else if (detection_state == COMPLETE && !detect_en) begin
            detection_state <= IDLE;
        end
    end
    
    // 稳定性计数器逻辑 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stability_counter <= 10'd0;
        end else if (detection_state == IDLE && detect_en) begin
            stability_counter <= 10'd0;
        end else if (detection_state == WAIT_STABLE && dp == prev_dp && dm == prev_dm && stability_counter < 10'd500) begin
            stability_counter <= stability_counter + 10'd1;
        end else if (detection_state == WAIT_STABLE && (dp != prev_dp || dm != prev_dm)) begin
            stability_counter <= 10'd0;
        end
    end
    
    // 信号边缘检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_dp <= 1'b0;
            prev_dm <= 1'b0;
        end else begin
            prev_dp <= dp;
            prev_dm <= dm;
        end
    end
    
    // 设备类型检测逻辑 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_speed <= 1'b0;
            full_speed <= 1'b0;
            no_device <= 1'b1;
            chirp_detected <= 1'b0;
        end else if (detection_state == DETECT && !(dp || dm)) begin
            no_device <= 1'b1;
            full_speed <= 1'b0;
            low_speed <= 1'b0;
            chirp_detected <= 1'b0;
        end else if (detection_state == DETECT && dp && !dm) begin
            no_device <= 1'b0;
            full_speed <= 1'b1;
            low_speed <= 1'b0;
            chirp_detected <= 1'b0;
        end else if (detection_state == DETECT && !dp && dm) begin
            no_device <= 1'b0;
            full_speed <= 1'b0;
            low_speed <= 1'b1;
            chirp_detected <= 1'b0;
        end else if (detection_state == DETECT && dp && dm) begin
            no_device <= 1'b0;
            full_speed <= 1'b0;
            low_speed <= 1'b0;
            chirp_detected <= 1'b1;
        end
    end
    
endmodule