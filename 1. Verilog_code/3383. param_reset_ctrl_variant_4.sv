//SystemVerilog IEEE 1364-2005
// 顶层模块 - 参数化复位控制器
module param_reset_ctrl #(
    parameter WIDTH = 4,
    parameter ACTIVE_HIGH = 1,
    parameter ENABLE_SYNCHRONOUS = 0,  // 新增参数：是否启用同步复位
    parameter PIPELINE_STAGES = 1      // 新增参数：复位流水线级数
)(
    input wire clk,                    // 新增时钟输入
    input wire reset_in,
    input wire enable,
    output wire [WIDTH-1:0] reset_out
);
    // 内部连线
    wire normalized_reset;
    wire gated_reset;
    wire [WIDTH-1:0] reset_vector;
    
    // 实例化极性转换子模块
    reset_polarity_converter #(
        .ACTIVE_HIGH(ACTIVE_HIGH)
    ) reset_polarity_inst (
        .reset_in(reset_in),
        .normalized_reset(normalized_reset)
    );
    
    // 实例化复位门控子模块
    reset_gate_controller reset_gate_inst (
        .normalized_reset(normalized_reset),
        .enable(enable),
        .gated_reset(gated_reset)
    );
    
    // 实例化复位向量生成器
    reset_vector_generator #(
        .WIDTH(WIDTH)
    ) reset_vector_inst (
        .gated_reset(gated_reset),
        .reset_vector(reset_vector)
    );
    
    // 实例化复位同步与流水线模块
    reset_synchronizer #(
        .WIDTH(WIDTH),
        .ENABLE_SYNCHRONOUS(ENABLE_SYNCHRONOUS),
        .PIPELINE_STAGES(PIPELINE_STAGES)
    ) reset_sync_inst (
        .clk(clk),
        .reset_vector_in(reset_vector),
        .reset_vector_out(reset_out)
    );
    
endmodule

// 子模块：复位极性转换器
module reset_polarity_converter #(
    parameter ACTIVE_HIGH = 1
)(
    input wire reset_in,
    output wire normalized_reset
);
    // 根据参数设置转换复位信号极性
    assign normalized_reset = ACTIVE_HIGH ? reset_in : ~reset_in;
endmodule

// 子模块：复位门控控制器
module reset_gate_controller (
    input wire normalized_reset,
    input wire enable,
    output wire gated_reset
);
    // 只有在使能有效时才传递复位信号
    assign gated_reset = enable & normalized_reset;
endmodule

// 子模块：复位向量生成器
module reset_vector_generator #(
    parameter WIDTH = 4
)(
    input wire gated_reset,
    output wire [WIDTH-1:0] reset_vector
);
    // 生成复位向量
    assign reset_vector = {WIDTH{gated_reset}};
endmodule

// 子模块：复位同步器与流水线
module reset_synchronizer #(
    parameter WIDTH = 4,
    parameter ENABLE_SYNCHRONOUS = 0,
    parameter PIPELINE_STAGES = 1
)(
    input wire clk,
    input wire [WIDTH-1:0] reset_vector_in,
    output wire [WIDTH-1:0] reset_vector_out
);
    // 内部信号定义
    reg [WIDTH-1:0] reset_pipeline [PIPELINE_STAGES-1:0];
    
    generate
        if (ENABLE_SYNCHRONOUS) begin: sync_reset_block
            integer i;
            
            // 同步复位流水线实现
            always @(posedge clk) begin
                reset_pipeline[0] <= reset_vector_in;
                for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                    reset_pipeline[i] <= reset_pipeline[i-1];
                end
            end
            
            // 输出最后一级流水线结果
            assign reset_vector_out = reset_pipeline[PIPELINE_STAGES-1];
        end else begin: async_reset_block
            // 异步模式直接连接
            assign reset_vector_out = reset_vector_in;
        end
    endgenerate
    
endmodule