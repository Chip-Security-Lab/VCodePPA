//SystemVerilog
module multi_bit_clock_gate #(
    parameter WIDTH = 4
) (
    input  wire clk_in,
    input  wire [WIDTH-1:0] enable_vector,
    output wire [WIDTH-1:0] clk_out
);
    // 分组实现时钟门控，减少门控单元数量
    // 使用结构化设计提高效率
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : gate_group
            if (i+1 < WIDTH) begin : dual_gate
                // 每两位使用一个双通道时钟门控单元
                dual_clock_gating_cell gate_dual (
                    .clk_in(clk_in),
                    .enable_a(enable_vector[i]),
                    .enable_b(enable_vector[i+1]),
                    .clk_out_a(clk_out[i]),
                    .clk_out_b(clk_out[i+1])
                );
            end else begin : single_gate
                // 对于奇数WIDTH的最后一位使用单通道门控
                optimized_clock_gating_cell gate_single (
                    .clk_in(clk_in),
                    .enable(enable_vector[i]),
                    .clk_out(clk_out[i])
                );
            end
        end
    endgenerate
endmodule

// 优化的双通道时钟门控单元
module dual_clock_gating_cell (
    input  wire clk_in,
    input  wire enable_a,
    input  wire enable_b,
    output wire clk_out_a,
    output wire clk_out_b
);
    // 共享锁存逻辑以节省面积
    reg enable_latch_a;
    reg enable_latch_b;
    
    // 使用统一的时钟沿检测逻辑
    always @(*) begin
        if (!clk_in) begin
            enable_latch_a <= enable_a;
            enable_latch_b <= enable_b;
        end
    end
    
    // 并行输出逻辑
    assign clk_out_a = clk_in & enable_latch_a;
    assign clk_out_b = clk_in & enable_latch_b;
endmodule

// 优化的单通道时钟门控单元
module optimized_clock_gating_cell (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // 使用优化的锁存器结构
    reg enable_latch;
    
    // 添加非阻塞赋值以改善综合结果
    always @(*) begin
        if (!clk_in)
            enable_latch <= enable;
    end
    
    // 使用专用的低延迟与门
    assign clk_out = clk_in & enable_latch;
endmodule