//SystemVerilog
// 顶层模块 - 峰值检测与恢复系统
module peak_detection_recovery (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output wire [9:0] peak_value,
    output wire peak_detected
);
    // 内部连线声明
    wire [9:0] current_value;
    wire [9:0] prev_value;
    wire [9:0] prev_prev_value;
    
    // 实例化信号采样子模块
    signal_sampler u_signal_sampler (
        .clk(clk),
        .rst_n(rst_n),
        .signal_in(signal_in),
        .current_value(current_value)
    );
    
    // 实例化信号延迟流水线子模块
    signal_pipeline u_signal_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .current_value(current_value),
        .prev_value(prev_value),
        .prev_prev_value(prev_prev_value)
    );
    
    // 实例化峰值检测子模块
    peak_detector u_peak_detector (
        .clk(clk),
        .rst_n(rst_n),
        .current_value(current_value),
        .prev_value(prev_value),
        .prev_prev_value(prev_prev_value),
        .peak_value(peak_value),
        .peak_detected(peak_detected)
    );
    
endmodule

// 信号采样子模块 - 负责对输入信号进行初次采样
module signal_sampler (
    input wire clk,
    input wire rst_n,
    input wire [9:0] signal_in,
    output reg [9:0] current_value
);
    // 对输入信号进行采样以减少输入到寄存器的延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_value <= 10'h0;
        end else begin
            current_value <= signal_in;
        end
    end
endmodule

// 信号延迟流水线子模块 - 创建延迟信号用于比较
module signal_pipeline (
    input wire clk,
    input wire rst_n,
    input wire [9:0] current_value,
    output reg [9:0] prev_value,
    output reg [9:0] prev_prev_value
);
    // 移动寄存器流水线，创建延迟的信号序列
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_value <= 10'h0;
            prev_prev_value <= 10'h0;
        end else begin
            prev_prev_value <= prev_value;
            prev_value <= current_value;
        end
    end
endmodule

// 峰值检测子模块 - 核心比较逻辑，判断何时发生峰值
module peak_detector (
    input wire clk,
    input wire rst_n,
    input wire [9:0] current_value,
    input wire [9:0] prev_value,
    input wire [9:0] prev_prev_value,
    output reg [9:0] peak_value,
    output reg peak_detected
);
    // 峰值检测逻辑 - 通过比较前一个值与其前后值判断是否为局部最大值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            peak_value <= 10'h0;
            peak_detected <= 1'b0;
        end else begin
            // 检测局部最大值 - 只有当前一值大于前前值且大于当前值时才是峰值
            if ((prev_value > prev_prev_value) && (prev_value > current_value)) begin
                peak_value <= prev_value;
                peak_detected <= 1'b1;
            end else begin
                peak_detected <= 1'b0;
            end
        end
    end
endmodule