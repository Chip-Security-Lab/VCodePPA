//SystemVerilog
module RangeDetector_CDC #(
    parameter WIDTH = 8
)(
    input src_clk,
    input dst_clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output flag_out
);
    // 内部信号定义
    wire src_flag;
    wire dst_flag;
    
    // 源时钟域阈值检测模块
    ThresholdDetector #(
        .WIDTH(WIDTH)
    ) src_detector (
        .clk(src_clk),
        .data_in(data_in),
        .threshold(threshold),
        .flag_out(src_flag)
    );
    
    // 时钟域同步模块
    ClockDomainSynchronizer sync_module (
        .src_flag(src_flag),
        .dst_clk(dst_clk),
        .rst_n(rst_n),
        .dst_flag(dst_flag)
    );
    
    // 目标时钟域输出寄存模块
    OutputRegister out_reg (
        .clk(dst_clk),
        .flag_in(dst_flag),
        .flag_out(flag_out)
    );
endmodule

// 阈值检测模块：在源时钟域检测数据是否超过阈值
module ThresholdDetector #(
    parameter WIDTH = 8
)(
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag_out
);
    // 在时钟上升沿进行数据捕获和阈值比较
    always @(posedge clk) begin
        flag_out <= (data_in > threshold);
    end
endmodule

// 时钟域同步模块：使用双触发器同步机制安全跨越时钟域
module ClockDomainSynchronizer (
    input src_flag,
    input dst_clk,
    input rst_n,
    output reg dst_flag
);
    // 中间同步寄存器
    reg meta_flag;
    
    // 两级同步器链 (双触发器)
    always @(posedge dst_clk or negedge rst_n) begin
        if(!rst_n) begin
            meta_flag <= 1'b0;
            dst_flag <= 1'b0;
        end
        else begin
            meta_flag <= src_flag;
            dst_flag <= meta_flag;
        end
    end
endmodule

// 输出寄存模块：在目标时钟域寄存输出信号
module OutputRegister (
    input clk,
    input flag_in,
    output reg flag_out
);
    // 寄存输出信号
    always @(posedge clk) begin
        flag_out <= flag_in;
    end
endmodule