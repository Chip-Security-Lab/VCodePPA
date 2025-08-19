//SystemVerilog
// 顶层模块
module crossbar_monitor #(
    parameter DW = 8,
    parameter N = 4
) (
    input                      clk,
    input      [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout,
    output reg [31:0]          traffic_count
);
    wire [31:0] traffic_increment;
    
    // 流量计算子模块实例化
    traffic_calculator #(
        .DW(DW),
        .N(N)
    ) traffic_calc_inst (
        .din(din),
        .traffic_increment(traffic_increment)
    );
    
    // 数据交叉连接子模块实例化
    data_crossbar #(
        .DW(DW),
        .N(N)
    ) data_xbar_inst (
        .clk(clk),
        .din(din),
        .dout(dout)
    );
    
    // 流量统计子模块实例化
    traffic_counter traffic_counter_inst (
        .clk(clk),
        .traffic_increment(traffic_increment),
        .traffic_count(traffic_count)
    );
    
endmodule

// 流量计算子模块
module traffic_calculator #(
    parameter DW = 8,
    parameter N = 4
) (
    input  [N-1:0][DW-1:0] din,
    output [31:0]          traffic_increment
);
    reg [31:0] traffic_sum;
    integer i;
    
    always @(*) begin
        traffic_sum = 0;
        for (i = 0; i < N; i = i + 1) begin
            traffic_sum = traffic_sum + (|din[i]);
        end
    end
    
    assign traffic_increment = traffic_sum;
    
endmodule

// 数据交叉连接子模块
module data_crossbar #(
    parameter DW = 8,
    parameter N = 4
) (
    input                      clk,
    input      [N-1:0][DW-1:0] din,
    output reg [N-1:0][DW-1:0] dout
);
    integer i;
    
    always @(posedge clk) begin
        for (i = 0; i < N; i = i + 1) begin
            dout[i] <= din[N-1-i];
        end
    end
    
endmodule

// 流量统计子模块
module traffic_counter (
    input             clk,
    input      [31:0] traffic_increment,
    output reg [31:0] traffic_count
);
    
    // 更新流量计数
    always @(posedge clk) begin
        traffic_count <= traffic_count + traffic_increment;
    end
    
    // 初始化流量计数器
    initial begin
        traffic_count = 0;
    end
    
endmodule