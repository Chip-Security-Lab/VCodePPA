//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module nand4_3 #(
    parameter PIPELINE_STAGES = 4  // 增加默认流水线级数
)(
    input  wire        clk,        // 时钟信号
    input  wire        rst_n,      // 复位信号
    input  wire        A,
    input  wire        B, 
    input  wire        C, 
    input  wire        D,
    output wire        Y
);
    // 数据流路径信号定义
    wire [3:0] data_in;            // 输入数据总线
    wire [1:0] and_partial1;       // 部分与门结果1
    wire [1:0] and_partial2;       // 部分与门结果2
    wire       and_partial_result; // 部分与门结果
    wire       and_result;         // 与门结果
    
    // 流水线寄存器
    reg [3:0]  data_stage1;        // 第一级流水线寄存器
    reg [1:0]  and_stage2a;        // 第二级流水线寄存器a（A&B）
    reg [1:0]  and_stage2b;        // 第二级流水线寄存器b（C&D）
    reg        and_stage3;         // 第三级流水线寄存器
    reg        and_stage4;         // 第四级流水线寄存器
    
    // 数据输入映射 - 改善数据路径结构
    assign data_in = {A, B, C, D};
    
    // 流水线第一级 - 输入缓存与同步
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0000;
        end else begin
            data_stage1 <= data_in;
        end
    end
    
    // 组合逻辑计算 - 拆分为两部分，减少每级复杂度
    assign and_partial1 = {data_stage1[0] & data_stage1[1], data_stage1[0], data_stage1[1]};
    assign and_partial2 = {data_stage1[2] & data_stage1[3], data_stage1[2], data_stage1[3]};
    
    // 流水线第二级 - 部分与运算结果缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_stage2a <= 2'b00;
            and_stage2b <= 2'b00;
        end else begin
            and_stage2a <= and_partial1;
            and_stage2b <= and_partial2;
        end
    end
    
    // 组合逻辑 - 合并部分结果
    assign and_partial_result = and_stage2a[0] & and_stage2b[0];
    
    // 流水线第三级 - 合并结果缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_stage3 <= 1'b0;
        end else begin
            and_stage3 <= and_partial_result;
        end
    end
    
    // 流水线第四级 - 最终结果缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_stage4 <= 1'b0;
        end else begin
            and_stage4 <= and_stage3;
        end
    end
    
    // 输出逻辑 - 最终NAND结果
    assign Y = ~and_stage4;
    
endmodule