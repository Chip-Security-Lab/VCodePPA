//SystemVerilog
module modulo_counter #(parameter MOD_VALUE = 10, WIDTH = 4) (
    input wire clk, reset,
    input wire enable,
    output reg [WIDTH-1:0] count,
    output wire tc,
    output reg valid_out
);
    // 将计算逻辑移到寄存器前
    wire [WIDTH-1:0] next_count;
    wire tc_wire;
    
    // 优化的组合逻辑 - 移到寄存器前面
    assign tc_wire = (count == MOD_VALUE - 1);
    assign next_count = tc_wire ? {WIDTH{1'b0}} : count + 1'b1;
    
    // 流水线第一级 - 直接使用计算结果
    reg [WIDTH-1:0] count_stage1;
    reg tc_stage1;
    reg valid_stage1;
    
    // 流水线第二级
    reg [WIDTH-1:0] count_stage2;
    reg tc_stage2;
    reg valid_stage2;
    
    // 第一级流水线寄存器 - 现在直接存储计算结果
    always @(posedge clk) begin
        if (reset) begin
            count_stage1 <= {WIDTH{1'b0}};
            tc_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            count_stage1 <= next_count; // 直接使用组合逻辑计算结果
            tc_stage1 <= tc_wire;       // 直接使用组合逻辑计算结果
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk) begin
        if (reset) begin
            count_stage2 <= {WIDTH{1'b0}};
            tc_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (enable) begin
            count_stage2 <= count_stage1;
            tc_stage2 <= tc_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (reset) begin
            count <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (enable) begin
            count <= count_stage2;
            valid_out <= valid_stage2;
        end
    end
    
    // 终端计数输出
    assign tc = tc_stage2;
    
endmodule