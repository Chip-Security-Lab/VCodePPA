//SystemVerilog
// 顶层模块
module Timer_SyncLoad #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output timeout
);
    // 内部连线
    wire [WIDTH-1:0] counter_value;
    wire counter_equals_preset;
    
    // 计数器子模块实例化
    Counter_Module #(
        .WIDTH(WIDTH)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .preset(preset),
        .counter_value(counter_value),
        .counter_equals_preset(counter_equals_preset)
    );
    
    // 超时检测子模块实例化
    Timeout_Detector timeout_detector_inst (
        .clk(clk),
        .rst_n(rst_n),
        .counter_equals_preset(counter_equals_preset),
        .timeout(timeout)
    );
    
endmodule

// 计数器子模块
module Counter_Module #(parameter WIDTH=8) (
    input clk, rst_n, enable,
    input [WIDTH-1:0] preset,
    output reg [WIDTH-1:0] counter_value,
    output counter_equals_preset
);
    // 计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            counter_value <= {WIDTH{1'b0}};
        else if (enable)
            counter_value <= (counter_value == preset) ? {WIDTH{1'b0}} : counter_value + 1'b1;
    end
    
    // 比较逻辑
    assign counter_equals_preset = (counter_value == preset);
    
endmodule

// 超时检测子模块
module Timeout_Detector (
    input clk, rst_n,
    input counter_equals_preset,
    output reg timeout
);
    // 超时检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            timeout <= 1'b0;
        else
            timeout <= counter_equals_preset;
    end
    
endmodule