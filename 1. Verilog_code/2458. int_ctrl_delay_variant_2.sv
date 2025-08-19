//SystemVerilog
// SystemVerilog - IEEE 1364-2005
// 顶层模块 - 流水线版本（优化后）
module int_ctrl_delay #(
    parameter DLY = 2
)(
    input  wire        clk,
    input  wire        rst_n,      // 复位信号
    input  wire        valid_in,   // 输入有效信号
    input  wire        int_in,
    output wire        int_out,
    output wire        valid_out   // 输出有效信号
);
    // 内部信号定义
    wire [DLY-1:0] delay_signals;
    wire [DLY:0]   stage_valid;    // 流水线各级有效信号
    
    // 延迟链生成器模块实例化 - 流水线版本
    delay_chain_generator #(
        .DELAY_LENGTH(DLY)
    ) delay_chain_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .valid_in     (valid_in),
        .signal_in    (int_in),
        .delay_signals(delay_signals),
        .stage_valid  (stage_valid)
    );
    
    // 输出选择器模块实例化 - 流水线版本
    output_selector #(
        .DELAY_LENGTH(DLY)
    ) output_select_inst (
        .clk          (clk),          // 添加时钟
        .rst_n        (rst_n),        // 添加复位
        .delay_signals(delay_signals),
        .valid_in     (stage_valid[DLY-1]),
        .signal_out   (int_out),
        .valid_out    (valid_out)
    );
    
endmodule

// 延迟链生成器子模块 - 流水线版本（优化后）
module delay_chain_generator #(
    parameter DELAY_LENGTH = 2
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       valid_in,
    input  wire                       signal_in,
    output wire [DELAY_LENGTH-1:0]    delay_signals,
    output reg  [DELAY_LENGTH:0]      stage_valid
);
    // 前向寄存器重定时 - 将输入寄存器推到组合逻辑后
    reg signal_in_d;  // 输入信号延迟寄存器
    reg [DELAY_LENGTH-2:0] delay_chain;
    
    // 保留输入信号 - 实现无寄存器路径到第一级
    assign delay_signals[0] = signal_in;
    
    // 延迟链剩余部分
    assign delay_signals[DELAY_LENGTH-1:1] = delay_chain;
    
    // 流水线寄存器 - 前向重定时后的数据路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_in_d <= 1'b0;
            delay_chain <= {(DELAY_LENGTH-1){1'b0}};
        end else begin
            if (valid_in || stage_valid[0]) begin
                signal_in_d <= signal_in;
                if (DELAY_LENGTH > 2) begin
                    delay_chain <= {delay_chain[DELAY_LENGTH-3:0], signal_in_d};
                end else if (DELAY_LENGTH == 2) begin
                    delay_chain <= signal_in_d;
                end
            end
        end
    end
    
    // 流水线控制 - valid信号传播
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_valid <= {(DELAY_LENGTH+1){1'b0}};
        end else begin
            stage_valid <= {stage_valid[DELAY_LENGTH-1:0], valid_in};
        end
    end
    
endmodule

// 输出选择器子模块 - 流水线版本（优化后）
module output_selector #(
    parameter DELAY_LENGTH = 2
)(
    input  wire                     clk,         // 添加时钟
    input  wire                     rst_n,       // 添加复位
    input  wire [DELAY_LENGTH-1:0]  delay_signals,
    input  wire                     valid_in,
    output reg                      signal_out,
    output reg                      valid_out
);
    // 流水线输出阶段 - 添加寄存器优化关键路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            signal_out <= delay_signals[DELAY_LENGTH-1];
            valid_out <= valid_in;
        end
    end
    
endmodule