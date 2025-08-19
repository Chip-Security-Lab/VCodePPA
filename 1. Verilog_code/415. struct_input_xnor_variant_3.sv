//SystemVerilog
module struct_input_xnor (
    input  wire        clk,         // 添加时钟信号用于流水线
    input  wire        rst_n,       // 添加复位信号
    input  wire [3:0]  a_in,        // 输入数据A
    input  wire [3:0]  b_in,        // 输入数据B
    output wire [3:0]  struct_out   // 结构化输出结果
);
    // 数据流水线寄存器 - 第一级
    reg [3:0] a_in_reg, b_in_reg;
    
    // 中间信号声明 - 明确数据流路径
    wire [3:0] and_result;  // a & b 结果
    wire [3:0] nor_result;  // ~a & ~b 结果
    
    // 第二级流水线寄存器
    reg [3:0] and_result_reg;
    reg [3:0] nor_result_reg;
    
    // 第三级流水线 - 最终结果
    reg [3:0] result_reg;

    // 实例化优化后的位运算子模块
    bit_xnor_datapath bit_xnor_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a_data(a_in_reg),
        .b_data(b_in_reg),
        .and_result(and_result),
        .nor_result(nor_result)
    );
    
    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 第一级流水线寄存器复位
            a_in_reg <= 4'b0;
            b_in_reg <= 4'b0;
            
            // 第二级流水线寄存器复位
            and_result_reg <= 4'b0;
            nor_result_reg <= 4'b0;
            
            // 第三级流水线寄存器复位
            result_reg <= 4'b0;
        end
        else begin
            // 第一级：输入数据寄存
            a_in_reg <= a_in;
            b_in_reg <= b_in;
            
            // 第二级：中间结果寄存
            and_result_reg <= and_result;
            nor_result_reg <= nor_result;
            
            // 第三级：计算最终结果
            result_reg <= and_result_reg | nor_result_reg;
        end
    end
    
    // 输出赋值
    assign struct_out = result_reg;
    
endmodule

// 优化的数据通路子模块：分离计算与流水线逻辑
module bit_xnor_datapath #(
    parameter WIDTH = 4
)(
    input  wire                clk,          // 时钟信号
    input  wire                rst_n,        // 复位信号
    input  wire [WIDTH-1:0]    a_data,       // 数据输入A
    input  wire [WIDTH-1:0]    b_data,       // 数据输入B
    output wire [WIDTH-1:0]    and_result,   // A&B中间结果
    output wire [WIDTH-1:0]    nor_result    // ~A&~B中间结果
);
    // 分解XNOR计算为两个独立的运算路径，减少关键路径长度
    // 分支1: A与B的与运算
    assign and_result = a_data & b_data;
    
    // 分支2: ~A与~B的与运算
    assign nor_result = (~a_data) & (~b_data);
    
    // 注：OR操作被移到顶层模块的流水线逻辑中
endmodule