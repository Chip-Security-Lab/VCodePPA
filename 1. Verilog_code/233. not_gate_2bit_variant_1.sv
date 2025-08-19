//SystemVerilog
//顶层模块
module not_gate_2bit #(
    parameter GATE_DELAY = 1,      // 统一延迟参数配置
    parameter POWER_OPT = 1         // 功耗优化参数，0=标准模式，1=低功耗模式
) (
    input  wire        clk,         // 时钟输入（用于同步模式）
    input  wire        rst_n,       // 复位信号
    input  wire        enable,      // 使能信号
    input  wire [1:0]  A,           // 2位输入数据
    output wire [1:0]  Y            // 2位输出数据
);
    // 内部信号声明
    wire [1:0] inverter_out;
    wire       gate_enable;
    
    // 使能控制逻辑子模块
    not_gate_control ctrl_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .gate_enable(gate_enable)
    );
    
    // 数据处理子模块
    not_gate_datapath #(
        .GATE_DELAY(GATE_DELAY),
        .POWER_OPT(POWER_OPT)
    ) data_unit (
        .in_data(A),
        .gate_enable(gate_enable),
        .out_data(inverter_out)
    );
    
    // 输出驱动子模块
    not_gate_output_driver output_unit (
        .in_data(inverter_out),
        .out_data(Y)
    );
endmodule

// 控制逻辑子模块
module not_gate_control (
    input  wire clk,
    input  wire rst_n,
    input  wire enable,
    output reg  gate_enable
);
    // 同步使能控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gate_enable <= 1'b0;
        end else begin
            gate_enable <= enable;
        end
    end
endmodule

// 数据处理子模块
module not_gate_datapath #(
    parameter GATE_DELAY = 1,
    parameter POWER_OPT = 1
) (
    input  wire [1:0] in_data,
    input  wire       gate_enable,
    output wire [1:0] out_data
);
    // 低功耗模式实现
    generate
        if (POWER_OPT == 1) begin: low_power_mode
            // 使用门控实现
            assign #(GATE_DELAY) out_data = gate_enable ? ~in_data : 2'b00;
        end else begin: standard_mode
            // 标准实现
            assign #(GATE_DELAY) out_data = ~in_data;
        end
    endgenerate
endmodule

// 输出驱动子模块
module not_gate_output_driver (
    input  wire [1:0] in_data,
    output wire [1:0] out_data
);
    // 简单的缓冲驱动，可以根据需要添加额外的驱动能力
    assign out_data = in_data;
endmodule