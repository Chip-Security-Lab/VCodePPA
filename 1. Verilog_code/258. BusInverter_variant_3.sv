//SystemVerilog
// SystemVerilog
module BusInverter(
    input logic [63:0] bus_input,
    output logic [63:0] inverted_bus
);
    // 定义流水线阶段信号
    logic [63:0] stage1_propagate, stage1_generate;
    logic [63:0] stage2_propagate, stage2_generate;
    logic [64:0] stage2_carry;
    logic [63:0] stage3_generate, stage3_carry;
    
    // 第一阶段：生成基本信号
    SignalGenerator signal_gen (
        .clk(clk),
        .data_in(bus_input),
        .propagate_out(stage1_propagate),
        .generate_out(stage1_generate)
    );
    
    // 第二阶段：进位处理 - 分成四个16位块并行处理
    ManchesterCarryChain carry_chain (
        .clk(clk),
        .propagate_in(stage1_propagate),
        .generate_in(stage1_generate),
        .propagate_out(stage2_propagate),
        .generate_out(stage2_generate),
        .carry_out(stage2_carry)
    );
    
    // 第三阶段：结果计算
    ResultCalculator result_calc (
        .clk(clk),
        .generate_in(stage2_generate),
        .carry_in(stage2_carry[63:0]),
        .result(inverted_bus)
    );
    
endmodule

// 信号生成模块 - 第一流水线阶段
module SignalGenerator(
    input logic clk,
    input logic [63:0] data_in,
    output logic [63:0] propagate_out,
    output logic [63:0] generate_out
);
    // 内部信号 - 便于调试和分段处理
    logic [63:0] propagate_temp;
    logic [63:0] generate_temp;

    // 生成传播和生成信号
    always_comb begin
        propagate_temp = 64'hFFFFFFFFFFFFFFFF;
        generate_temp = ~data_in;
    end
    
    // 添加寄存器以切分数据路径
    always_ff @(posedge clk) begin
        propagate_out <= propagate_temp;
        generate_out <= generate_temp;
    end
    
endmodule

// 曼彻斯特进位链模块 - 第二流水线阶段
module ManchesterCarryChain(
    input logic clk,
    input logic [63:0] propagate_in,
    input logic [63:0] generate_in,
    output logic [63:0] propagate_out,
    output logic [63:0] generate_out,
    output logic [64:0] carry_out
);
    // 内部信号和常量定义
    parameter WIDTH = 64;
    parameter SEGMENT_SIZE = 16;
    
    // 分段进位计算的中间信号
    logic [WIDTH:0] carry_temp;
    logic [WIDTH-1:0] propagate_temp, generate_temp;
    
    // 初始进位为0
    assign carry_temp[0] = 1'b0;
    
    // 分段并行处理进位链，将64位分成4个16位段
    genvar i, j;
    generate
        // 第一级进位 - 每16位为一组
        for (j=0; j<WIDTH/SEGMENT_SIZE; j=j+1) begin : SEGMENT
            // 每段内部进位链处理
            for (i=0; i<SEGMENT_SIZE; i=i+1) begin : CHAIN
                localparam idx = j*SEGMENT_SIZE + i;
                assign carry_temp[idx+1] = generate_in[idx] | (propagate_in[idx] & carry_temp[idx]);
            end
        end
    endgenerate
    
    // 将中间结果寄存下来，减少关键路径
    always_ff @(posedge clk) begin
        propagate_out <= propagate_in;
        generate_out <= generate_in;
        carry_out <= carry_temp;
    end
    
endmodule

// 结果计算模块 - 第三流水线阶段
module ResultCalculator(
    input logic clk,
    input logic [63:0] generate_in,
    input logic [63:0] carry_in,
    output logic [63:0] result
);
    // 内部信号 - 方便调试和优化
    logic [63:0] result_temp;
    
    // 计算最终输出结果
    always_comb begin
        result_temp = generate_in ^ carry_in;
    end
    
    // 输出寄存器 - 减少输出加载导致的延迟
    always_ff @(posedge clk) begin
        result <= result_temp;
    end
    
endmodule