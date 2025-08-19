//SystemVerilog
// 顶层模块
module int_ctrl_timeout #(
    parameter TIMEOUT = 8'hFF
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] req_in,
    output wire [2:0] curr_grant,
    output wire       timeout
);
    // 内部信号
    wire        timer_reset;
    wire [7:0]  timer_value;
    wire        timeout_detected;
    wire [2:0]  priority_index;
    
    // 实例化优先级编码器子模块
    priority_encoder priority_encoder_inst (
        .req_in        (req_in),
        .priority_index (priority_index)
    );
    
    // 实例化计时器子模块
    timer_controller #(
        .TIMEOUT       (TIMEOUT)
    ) timer_controller_inst (
        .clk           (clk),
        .rst           (rst),
        .timer_reset   (timer_reset),
        .timer_value   (timer_value),
        .timeout_detected (timeout_detected)
    );
    
    // 实例化授权控制器子模块
    grant_controller grant_controller_inst (
        .clk           (clk),
        .rst           (rst),
        .req_in        (req_in),
        .priority_index (priority_index),
        .timer_value   (timer_value),
        .timeout_detected (timeout_detected),
        .curr_grant    (curr_grant),
        .timeout       (timeout),
        .timer_reset   (timer_reset)
    );
    
endmodule

// 优先级编码器子模块
module priority_encoder (
    input  wire [7:0] req_in,
    output wire [2:0] priority_index
);
    // 确定请求中的优先级
    function [2:0] find_first_set;
        input [7:0] req;
        reg [2:0] index;
        begin
            index = 3'b0;
            if      (req[0]) index = 3'd0;
            else if (req[1]) index = 3'd1;
            else if (req[2]) index = 3'd2;
            else if (req[3]) index = 3'd3;
            else if (req[4]) index = 3'd4;
            else if (req[5]) index = 3'd5;
            else if (req[6]) index = 3'd6;
            else if (req[7]) index = 3'd7;
            find_first_set = index;
        end
    endfunction
    
    // 组合逻辑计算优先级索引
    assign priority_index = find_first_set(req_in);
    
endmodule

// 计时器控制器子模块
module timer_controller #(
    parameter TIMEOUT = 8'hFF
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       timer_reset,
    output reg  [7:0] timer_value,
    output wire       timeout_detected
);
    // 计时器逻辑
    always @(posedge clk) begin
        if (rst || timer_reset) begin
            timer_value <= 8'h0;
        end else begin
            timer_value <= (timer_value == TIMEOUT) ? 8'h0 : timer_value + 8'h1;
        end
    end
    
    // 超时检测
    assign timeout_detected = (timer_value == TIMEOUT);
    
endmodule

// 授权控制器子模块
module grant_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] req_in,
    input  wire [2:0] priority_index,
    input  wire [7:0] timer_value,
    input  wire       timeout_detected,
    output reg  [2:0] curr_grant,
    output reg        timeout,
    output wire       timer_reset
);
    // 授权和超时控制
    always @(posedge clk) begin
        if (rst || !req_in[curr_grant]) begin
            if (req_in != 0) begin
                curr_grant <= priority_index;
            end else begin
                curr_grant <= 3'b0;
            end
            timeout <= 1'b0;
        end else begin
            if (timeout_detected) begin
                timeout <= 1'b1;
            end else begin
                timeout <= 1'b0;
            end
        end
    end
    
    // 计时器重置信号
    assign timer_reset = rst || !req_in[curr_grant];
    
endmodule