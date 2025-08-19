//SystemVerilog
module not_gate_3bit #(
    parameter DRIVE_STRENGTH = 1, // 顶层参数，可配置所有子模块的驱动强度
    parameter USE_PARALLEL = 1    // 新参数：控制是否使用并行处理
) (
    input wire [2:0] A,
    output wire [2:0] Y
);
    // 实例化向量处理子模块
    not_vector_processor #(
        .DRIVE_STRENGTH(DRIVE_STRENGTH),
        .VECTOR_WIDTH(3),
        .USE_PARALLEL(USE_PARALLEL)
    ) vector_processor_inst (
        .vector_in(A),
        .vector_out(Y)
    );
endmodule

// 向量处理子模块，处理多位输入
module not_vector_processor #(
    parameter DRIVE_STRENGTH = 1,
    parameter VECTOR_WIDTH = 3,
    parameter USE_PARALLEL = 1
) (
    input wire [VECTOR_WIDTH-1:0] vector_in,
    output wire [VECTOR_WIDTH-1:0] vector_out
);
    genvar i;
    generate
        if (USE_PARALLEL) begin: parallel_impl
            // 并行实现方式，直接对整个向量进行求反
            not_parallel_unit #(
                .DRIVE_STRENGTH(DRIVE_STRENGTH),
                .WIDTH(VECTOR_WIDTH)
            ) parallel_unit_inst (
                .data_in(vector_in),
                .data_out(vector_out)
            );
        end else begin: bit_by_bit_impl
            // 逐位实现方式，使用单个NOT门
            for (i = 0; i < VECTOR_WIDTH; i = i + 1) begin: bit_loop
                not_gate_1bit #(
                    .DRIVE_STRENGTH(DRIVE_STRENGTH)
                ) not_gate_inst (
                    .A(vector_in[i]),
                    .Y(vector_out[i])
                );
            end
        end
    endgenerate
endmodule

// 并行向量处理单元，一次处理整个向量
module not_parallel_unit #(
    parameter DRIVE_STRENGTH = 1,
    parameter WIDTH = 3
) (
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 并行向量求反，可针对综合工具优化
    assign data_out = ~data_in;
endmodule

// 基本NOT门单元，处理单个位
module not_gate_1bit #(
    parameter DRIVE_STRENGTH = 1
) (
    input wire A,
    output wire Y
);
    // 根据驱动强度参数可配置不同实现
    generate
        if (DRIVE_STRENGTH == 1) begin: low_power
            // 低功耗实现
            assign Y = ~A;
        end else if (DRIVE_STRENGTH == 2) begin: balanced
            // 平衡功耗和速度的实现
            assign #(0.5) Y = ~A; // 仅用于仿真示意，实际综合时会被移除
        end else begin: high_speed
            // 高速实现
            assign #(0.3) Y = ~A; // 仅用于仿真示意，实际综合时会被移除
        end
    endgenerate
endmodule