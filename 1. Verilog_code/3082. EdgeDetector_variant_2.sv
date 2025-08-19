//SystemVerilog
module EdgeDetector #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input signal_in,
    output rising_edge,
    output falling_edge
);
    reg [1:0] sync_reg;
    wire rise_detect, fall_detect;
    
    // 时序逻辑 - 信号同步和寄存器更新
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], signal_in};
        end
    end
    
    // 组合逻辑 - 边沿检测
    EdgeDetectionLogic edge_logic_inst (
        .sync_signal(sync_reg),
        .rise_detect(rise_detect),
        .fall_detect(fall_detect)
    );
    
    // 边沿脉冲生成模块
    PulseGenerator #(
        .PULSE_WIDTH(PULSE_WIDTH)
    ) pulse_gen_inst (
        .clk(clk),
        .rst_async(rst_async),
        .rise_detect(rise_detect),
        .fall_detect(fall_detect),
        .rising_edge(rising_edge),
        .falling_edge(falling_edge)
    );
endmodule

// 纯组合逻辑模块 - 边沿检测
module EdgeDetectionLogic (
    input [1:0] sync_signal,
    output rise_detect,
    output fall_detect
);
    // 使用assign语句替代always块，提高性能
    assign rise_detect = (sync_signal == 2'b01);
    assign fall_detect = (sync_signal == 2'b10);
endmodule

// 脉冲生成模块 - 可配置脉冲宽度
module PulseGenerator #(
    parameter PULSE_WIDTH = 2
)(
    input clk, rst_async,
    input rise_detect, fall_detect,
    output reg rising_edge,
    output reg falling_edge
);
    reg [$clog2(PULSE_WIDTH):0] rise_counter;
    reg [$clog2(PULSE_WIDTH):0] fall_counter;
    
    // 时序逻辑 - 脉冲计数器和输出控制
    always @(posedge clk or posedge rst_async) begin
        if (rst_async) begin
            rise_counter <= 0;
            fall_counter <= 0;
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
        end else begin
            // 上升沿脉冲控制
            if (rise_detect) begin
                rise_counter <= PULSE_WIDTH;
                rising_edge <= 1'b1;
            end else if (rise_counter > 0) begin
                rise_counter <= rise_counter - 1;
                if (rise_counter == 1)
                    rising_edge <= 1'b0;
            end
            
            // 下降沿脉冲控制
            if (fall_detect) begin
                fall_counter <= PULSE_WIDTH;
                falling_edge <= 1'b1;
            end else if (fall_counter > 0) begin
                fall_counter <= fall_counter - 1;
                if (fall_counter == 1)
                    falling_edge <= 1'b0;
            end
        end
    end
endmodule