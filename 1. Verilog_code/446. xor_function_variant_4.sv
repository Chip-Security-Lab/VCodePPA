//SystemVerilog
// 顶层模块
module xor_function #(
    parameter PIPELINE_STAGES = 1
)(
    input wire clk,       // 添加时钟信号用于流水线寄存
    input wire rst_n,     // 添加复位信号
    input wire a, b,
    output wire y
);
    // 内部连接信号
    wire xor_stage_out;
    wire buffered_out;
    
    // 实例化优化的XOR计算子模块
    xor_compute_unit xor_comp (
        .in_a(a),
        .in_b(b),
        .out_result(xor_stage_out)
    );
    
    // 实例化流水线缓存子模块
    pipeline_buffer #(
        .STAGES(PIPELINE_STAGES),
        .DATA_WIDTH(1)
    ) output_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(xor_stage_out),
        .data_out(buffered_out)
    );
    
    // 实例化输出驱动子模块
    output_driver output_stage (
        .sig_in(buffered_out),
        .sig_out(y)
    );
    
endmodule

// XOR计算单元 - 专注于高效XOR逻辑实现
module xor_compute_unit (
    input wire in_a, in_b,
    output wire out_result
);
    // 直接实现XOR，避免函数调用开销
    assign out_result = in_a ^ in_b;
    
endmodule

// 可配置流水线缓存 - 提供可选的多级流水线寄存
module pipeline_buffer #(
    parameter STAGES = 1,    // 流水线级数
    parameter DATA_WIDTH = 1 // 数据宽度
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 流水线寄存器阵列
    reg [DATA_WIDTH-1:0] pipeline_regs [STAGES-1:0];
    integer i;
    
    // 流水线寄存逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1) begin
                pipeline_regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            pipeline_regs[0] <= data_in;
            for (i = 1; i < STAGES; i = i + 1) begin
                pipeline_regs[i] <= pipeline_regs[i-1];
            end
        end
    end
    
    // 如果STAGES为0，则直接连接；否则使用最后一级寄存器输出
    assign data_out = (STAGES == 0) ? data_in : pipeline_regs[STAGES-1];
    
endmodule

// 输出驱动模块 - 提供输出缓冲和驱动能力
module output_driver (
    input wire sig_in,
    output wire sig_out
);
    // 输出驱动逻辑，可扩展为三态缓冲等
    assign sig_out = sig_in;
    
endmodule