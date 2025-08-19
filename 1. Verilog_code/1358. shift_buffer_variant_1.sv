//SystemVerilog
// 顶层模块：整合各个子模块
module shift_buffer #(
    parameter WIDTH = 8,
    parameter STAGES = 4
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 子模块间的连接信号
    wire [WIDTH-1:0] stage_data [0:STAGES-1];
    
    // 输入处理模块实例化
    input_stage #(
        .WIDTH(WIDTH)
    ) u_input_stage (
        .data_in(data_in),
        .stage_out(stage_data[0])
    );
    
    // 生成中间移位寄存器级联
    genvar g;
    generate
        for (g = 0; g < STAGES-1; g = g + 1) begin : stage_gen
            shift_stage #(
                .WIDTH(WIDTH)
            ) u_shift_stage (
                .clk(clk),
                .enable(enable),
                .stage_in(stage_data[g]),
                .stage_out(stage_data[g+1])
            );
        end
    endgenerate
    
    // 输出处理模块实例化
    output_stage #(
        .WIDTH(WIDTH)
    ) u_output_stage (
        .stage_in(stage_data[STAGES-1]),
        .data_out(data_out)
    );
endmodule

// 输入阶段子模块：前向重定时优化
module input_stage #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] stage_out
);
    // 直接传递，实现前向重定时
    assign stage_out = data_in;
endmodule

// 移位级子模块：保存并传递数据
module shift_stage #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire enable,
    input wire [WIDTH-1:0] stage_in,
    output wire [WIDTH-1:0] stage_out
);
    // 优化移位寄存器实现，使用单一寄存器
    reg [WIDTH-1:0] shift_reg;
    
    // 时序逻辑处理
    always @(posedge clk) begin
        if (enable) begin
            shift_reg <= stage_in;
        end
    end
    
    // 数据输出
    assign stage_out = shift_reg;
endmodule

// 输出阶段子模块：提供最终输出
module output_stage #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] stage_in,
    output wire [WIDTH-1:0] data_out
);
    // 直接传递到输出
    assign data_out = stage_in;
endmodule