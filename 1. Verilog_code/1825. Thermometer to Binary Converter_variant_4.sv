//SystemVerilog
//==================================
// 顶层模块 - 温度计码转二进制码转换器
//==================================
module therm2bin_converter #(
    parameter THERM_WIDTH = 7
) (
    input  wire [THERM_WIDTH-1:0] therm_code,
    output wire [$clog2(THERM_WIDTH+1)-1:0] bin_code
);
    // 内部连线
    wire [$clog2(THERM_WIDTH+1)-1:0] count_result;
    
    // 实例化位计数子模块
    ones_counter #(
        .INPUT_WIDTH(THERM_WIDTH),
        .OUTPUT_WIDTH($clog2(THERM_WIDTH+1))
    ) counter_inst (
        .data_in(therm_code),
        .count_out(count_result)
    );
    
    // 输出赋值
    assign bin_code = count_result;
    
endmodule

//==================================
// 子模块 - 1的位计数器
//==================================
module ones_counter #(
    parameter INPUT_WIDTH = 7,
    parameter OUTPUT_WIDTH = 3
) (
    input  wire [INPUT_WIDTH-1:0] data_in,
    output reg  [OUTPUT_WIDTH-1:0] count_out
);
    // 将输入值分成两部分进行处理以减少延迟
    localparam HALF_WIDTH = INPUT_WIDTH/2;
    
    // 内部变量
    reg [OUTPUT_WIDTH-1:0] upper_count;
    reg [OUTPUT_WIDTH-1:0] lower_count;
    integer i;
    
    always @(*) begin
        // 计算下半部分的1的个数
        lower_count = 0;
        // 初始化
        i = 0;
        // 使用while循环替代for循环
        while (i < HALF_WIDTH) begin
            if (data_in[i]) lower_count = lower_count + 1'b1;
            i = i + 1; // 迭代步骤移到循环体末尾
        end
        
        // 计算上半部分的1的个数
        upper_count = 0;
        // 初始化
        i = HALF_WIDTH;
        // 使用while循环替代for循环
        while (i < INPUT_WIDTH) begin
            if (data_in[i]) upper_count = upper_count + 1'b1;
            i = i + 1; // 迭代步骤移到循环体末尾
        end
        
        // 合并结果
        count_out = upper_count + lower_count;
    end
    
endmodule