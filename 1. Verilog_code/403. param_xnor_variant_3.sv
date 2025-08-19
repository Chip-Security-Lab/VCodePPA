//SystemVerilog
module param_xnor #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] Y
);

    // 第一级：比较逻辑
    reg                comp_stage_eq;      // 相等标志
    reg                comp_stage_lt;      // 小于标志
    reg [WIDTH-1:0]    comp_stage_data_a;  // 保存A的值
    reg [WIDTH-1:0]    comp_stage_data_b;  // 保存B的值
    
    // 第二级：使用条件求和减法
    reg                arithmetic_stage_eq;
    reg                arithmetic_stage_lt;
    reg [WIDTH-1:0]    arithmetic_stage_minus;  // 存储减法结果
    
    // 条件求和减法算法使用的信号
    reg [WIDTH-1:0]    minuend, subtrahend;  // 被减数和减数
    reg [WIDTH:0]      borrow;               // 借位信号，多1位
    reg [WIDTH-1:0]    diff;                 // 差值
    
    // 第三级：结果生成
    reg [WIDTH-1:0]    result_stage;

    // 实现流水线结构
    always @(*) begin
        // 第一级：比较逻辑
        comp_stage_eq = (A == B);
        comp_stage_lt = (A < B);
        comp_stage_data_a = A;
        comp_stage_data_b = B;
    end
    
    always @(*) begin
        // 第二级：条件求和减法算法
        arithmetic_stage_eq = comp_stage_eq;
        arithmetic_stage_lt = comp_stage_lt;
        
        // 确定被减数和减数
        if (comp_stage_eq) begin
            minuend = '0;
            subtrahend = '0;
        end else if (comp_stage_lt) begin
            minuend = comp_stage_data_b;
            subtrahend = comp_stage_data_a;
        end else begin
            minuend = comp_stage_data_a;
            subtrahend = comp_stage_data_b;
        end
        
        // 条件求和减法算法实现
        borrow[0] = 1'b0;  // 初始无借位
        
        for (int i = 0; i < WIDTH; i++) begin
            // 当前位的差值 = 被减数 - 减数 - 借位
            diff[i] = minuend[i] ^ subtrahend[i] ^ borrow[i];
            
            // 计算下一位的借位
            borrow[i+1] = (~minuend[i] & subtrahend[i]) | 
                          (~minuend[i] & borrow[i]) | 
                          (subtrahend[i] & borrow[i]);
        end
        
        arithmetic_stage_minus = diff;
    end
    
    always @(*) begin
        // 第三级：结果生成
        if (arithmetic_stage_eq) begin
            // 两数相等，输出全1
            result_stage = {WIDTH{1'b1}};
        end else begin
            // 两数不等，计算最终结果
            result_stage = ~arithmetic_stage_minus;
        end
    end
    
    // 输出赋值
    assign Y = result_stage;

endmodule