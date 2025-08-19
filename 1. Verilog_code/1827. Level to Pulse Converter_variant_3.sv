//SystemVerilog
// 顶层模块
module level2pulse_converter (
    input  wire clk_i,
    input  wire rst_i,  // Active high reset
    input  wire level_i,
    output wire pulse_o
);
    // 内部信号
    wire level_delayed;
    
    // 延迟模块实例化
    edge_detector_delay delay_unit (
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .level_i    (level_i),
        .delayed_o  (level_delayed)
    );
    
    // 边沿检测模块实例化
    edge_detector_logic edge_unit (
        .current_i  (level_i),
        .delayed_i  (level_delayed),
        .pulse_o    (pulse_o)
    );
    
endmodule

// 延迟逻辑子模块
module edge_detector_delay (
    input  wire clk_i,
    input  wire rst_i,
    input  wire level_i,
    output reg  delayed_o
);
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delayed_o <= 1'b0;
        end else begin
            delayed_o <= level_i;
        end
    end
endmodule

// 边沿检测逻辑子模块
module edge_detector_logic (
    input  wire current_i,
    input  wire delayed_i,
    output wire pulse_o
);
    // 组合逻辑实现边沿检测
    assign pulse_o = current_i & ~delayed_i;
endmodule