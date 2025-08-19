//SystemVerilog
// 顶层模块
module sync_fir_filter #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output [DATA_W+TAP_W-1:0] filtered_out
);
    // 内部连线
    wire [DATA_W-1:0] delay_samples [TAPS-1:0];
    wire [DATA_W+TAP_W-1:0] dot_product_result;
    
    // 实例化移位寄存器子模块
    shift_register #(
        .DATA_W(DATA_W),
        .TAPS(TAPS)
    ) shift_reg_inst (
        .clk(clk),
        .rst(rst),
        .sample_in(sample_in),
        .delay_samples(delay_samples)
    );
    
    // 实例化点积计算子模块
    dot_product #(
        .DATA_W(DATA_W),
        .TAP_W(TAP_W),
        .TAPS(TAPS)
    ) dot_product_inst (
        .clk(clk),
        .rst(rst),
        .samples(delay_samples),
        .coeffs(coeffs),
        .result(dot_product_result)
    );
    
    // 实例化输出寄存器子模块
    output_register #(
        .WIDTH(DATA_W+TAP_W)
    ) output_reg_inst (
        .clk(clk),
        .rst(rst),
        .data_in(dot_product_result),
        .data_out(filtered_out)
    );
    
endmodule

// 移位寄存器子模块 - 管理延迟线
module shift_register #(
    parameter DATA_W = 12,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] sample_in,
    output reg [DATA_W-1:0] delay_samples [TAPS-1:0]
);
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1)
                delay_samples[i] <= 0;
        end else begin
            for (i = TAPS-1; i > 0; i = i - 1)
                delay_samples[i] <= delay_samples[i-1];
            delay_samples[0] <= sample_in;
        end
    end
endmodule

// 点积计算子模块 - 计算样本和系数的点积
module dot_product #(
    parameter DATA_W = 12,
    parameter TAP_W = 8,
    parameter TAPS = 4
)(
    input clk, rst,
    input [DATA_W-1:0] samples [TAPS-1:0],
    input [TAP_W-1:0] coeffs [TAPS-1:0],
    output reg [DATA_W+TAP_W-1:0] result
);
    reg [DATA_W+TAP_W-1:0] acc;
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
            result <= 0;
        end else begin
            acc = 0;
            for (i = 0; i < TAPS; i = i + 1)
                acc = acc + (samples[i] * coeffs[i]);
            result <= acc;
        end
    end
endmodule

// 输出寄存器子模块 - 管理输出缓存
module output_register #(
    parameter WIDTH = 20
)(
    input clk, rst,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= 0;
        else
            data_out <= data_in;
    end
endmodule