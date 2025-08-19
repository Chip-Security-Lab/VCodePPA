//SystemVerilog
//========================================================================
// 顶层模块: 多数表决系统
//========================================================================
module MajorityVote #(
    parameter N = 5,  // 输入信号数量
    parameter M = 3   // 多数表决阈值
)(
    input  [N-1:0] inputs,  // 输入信号向量
    output         vote_out // 表决结果输出
);
    // 内部信号
    wire [($clog2(N)+1)-1:0] count_value;
    
    // 计数子系统
    CountingSystem #(
        .WIDTH(N)
    ) counting_system_inst (
        .data_in    (inputs),
        .ones_count (count_value)
    );
    
    // 决策子系统
    DecisionSystem #(
        .THRESHOLD  (M),
        .COUNT_WIDTH($clog2(N)+1)
    ) decision_system_inst (
        .count_value  (count_value),
        .threshold_met(vote_out)
    );
    
endmodule

//========================================================================
// 计数子系统: 包含高效的位计数功能
//========================================================================
module CountingSystem #(
    parameter WIDTH = 5
)(
    input  [WIDTH-1:0]                 data_in,    // 输入数据向量
    output reg [($clog2(WIDTH)+1)-1:0] ones_count  // 计数结果
);
    // 分段计数，提高计数效率
    generate
        if (WIDTH <= 4) begin : small_counter
            // 小型计数器直接计数
            OptimizedCounter #(
                .WIDTH(WIDTH)
            ) counter_inst (
                .data_in    (data_in),
                .ones_count (ones_count)
            );
        end
        else begin : large_counter
            // 大型计数器分段计数
            localparam SEGMENT_SIZE = WIDTH/2;
            localparam REM_SIZE = WIDTH - SEGMENT_SIZE;
            
            wire [($clog2(SEGMENT_SIZE)+1)-1:0] lower_count;
            wire [($clog2(REM_SIZE)+1)-1:0] upper_count;
            
            // 计算低位段
            OptimizedCounter #(
                .WIDTH(SEGMENT_SIZE)
            ) lower_counter (
                .data_in    (data_in[SEGMENT_SIZE-1:0]),
                .ones_count (lower_count)
            );
            
            // 计算高位段
            OptimizedCounter #(
                .WIDTH(REM_SIZE)
            ) upper_counter (
                .data_in    (data_in[WIDTH-1:SEGMENT_SIZE]),
                .ones_count (upper_count)
            );
            
            // 合并结果
            always @(*) begin
                ones_count = lower_count + upper_count;
            end
        end
    endgenerate
endmodule

//========================================================================
// 优化的计数器: 实现单段计数功能
//========================================================================
module OptimizedCounter #(
    parameter WIDTH = 5
)(
    input  [WIDTH-1:0]                 data_in,    // 输入数据段
    output reg [($clog2(WIDTH)+1)-1:0] ones_count  // 计数结果
);
    integer i;
    
    always @(*) begin
        ones_count = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (data_in[i]) 
                ones_count = ones_count + 1'b1;
        end
    end
endmodule

//========================================================================
// 决策子系统: 阈值比较与输出处理
//========================================================================
module DecisionSystem #(
    parameter THRESHOLD = 3,
    parameter COUNT_WIDTH = 3
)(
    input  [COUNT_WIDTH-1:0] count_value,   // 输入计数值
    output                   threshold_met  // 阈值达成标志
);
    // 比较器和输出逻辑
    ThresholdComparator #(
        .THRESHOLD   (THRESHOLD),
        .COUNT_WIDTH (COUNT_WIDTH)
    ) comparator_inst (
        .count_value  (count_value),
        .threshold_met(threshold_met)
    );
endmodule

//========================================================================
// 阈值比较器: 将计数值与阈值比较并输出结果
//========================================================================
module ThresholdComparator #(
    parameter THRESHOLD = 3,
    parameter COUNT_WIDTH = 3
)(
    input  [COUNT_WIDTH-1:0] count_value,   // 输入计数值
    output                   threshold_met  // 阈值达成标志
);
    // 当计数值大于或等于阈值时，输出高电平
    assign threshold_met = (count_value >= THRESHOLD);
endmodule