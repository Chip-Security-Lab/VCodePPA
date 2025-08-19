//SystemVerilog
module Comparator_Pipelined #(
    parameter WIDTH = 64,         // 支持大位宽比较
    parameter PIPELINE_STAGES = 3 // 可配置流水级数
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  operand_a,
    input  [WIDTH-1:0]  operand_b,
    output              result
);
    // 使用先行借位减法器算法实现减法
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;
    
    // 初始无借位
    assign borrow[0] = 1'b0;
    
    // 先行借位减法器逻辑
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: gen_borrow
            // 生成借位信号
            assign borrow[j+1] = (~operand_a[j] & operand_b[j]) | 
                                (~operand_a[j] & borrow[j]) | 
                                (operand_b[j] & borrow[j]);
            
            // 差值计算
            assign diff[j] = operand_a[j] ^ operand_b[j] ^ borrow[j];
        end
    endgenerate
    
    // 相等判断逻辑: 当减法结果为0时，两数相等
    wire is_equal;
    assign is_equal = (diff == {WIDTH{1'b0}});
    
    // 分段流水线处理
    reg [PIPELINE_STAGES-1:0] stage_eq;
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_eq <= {PIPELINE_STAGES{1'b0}};
        end else begin
            // 级联移位寄存器
            stage_eq[0] <= is_equal;
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                stage_eq[i] <= stage_eq[i-1];
            end
        end
    end
    
    assign result = stage_eq[PIPELINE_STAGES-1];
endmodule