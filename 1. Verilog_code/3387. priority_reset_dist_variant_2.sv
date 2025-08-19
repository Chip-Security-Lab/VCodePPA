//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// 文件名: priority_reset_dist.v
// 描述: 优先级复位分配器顶层模块
// 标准: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module priority_reset_dist #(
    parameter NUM_SOURCES = 4,
    parameter NUM_OUTPUTS = 8
)(
    input wire [NUM_SOURCES-1:0] reset_sources,
    input wire [NUM_SOURCES-1:0] priority_levels,
    output wire [NUM_OUTPUTS-1:0] reset_outputs
);
    // 内部连线
    wire [$clog2(NUM_SOURCES+1)-1:0] highest_priority_index;
    wire valid_reset;
    
    // 子模块实例化
    priority_encoder #(
        .WIDTH(NUM_SOURCES)
    ) u_priority_encoder (
        .sources(reset_sources),
        .index(highest_priority_index),
        .valid(valid_reset)
    );
    
    reset_mask_generator #(
        .NUM_SOURCES(NUM_SOURCES),
        .NUM_OUTPUTS(NUM_OUTPUTS)
    ) u_reset_mask_generator (
        .priority_index(highest_priority_index),
        .priority_levels(priority_levels),
        .valid_reset(valid_reset),
        .reset_outputs(reset_outputs)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 模块名: priority_encoder
// 描述: 确定最高优先级活跃复位源的编码器
///////////////////////////////////////////////////////////////////////////////

module priority_encoder #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] sources,
    output reg [$clog2(WIDTH+1)-1:0] index,
    output wire valid
);
    // 本地参数
    localparam INVALID_INDEX = {$clog2(WIDTH+1){1'b1}};
    
    // 最高优先级检测逻辑
    always @(*) begin
        index = INVALID_INDEX;
    end
    
    // 单独的优先级扫描逻辑
    integer i;
    always @(*) begin
        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            if (sources[i]) begin
                index = i[$clog2(WIDTH+1)-1:0];
            end
        end
    end
    
    // 有效信号生成
    assign valid = (index != INVALID_INDEX);
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 模块名: reset_mask_generator
// 描述: 基于优先级索引和级别生成复位输出掩码
///////////////////////////////////////////////////////////////////////////////

module reset_mask_generator #(
    parameter NUM_SOURCES = 4,
    parameter NUM_OUTPUTS = 8
)(
    input wire [$clog2(NUM_SOURCES+1)-1:0] priority_index,
    input wire [NUM_SOURCES-1:0] priority_levels,
    input wire valid_reset,
    output wire [NUM_OUTPUTS-1:0] reset_outputs
);
    // 本地变量
    wire [NUM_SOURCES-1:0] selected_priority;
    wire [NUM_OUTPUTS-1:0] mask;
    
    // 选择相应的优先级级别
    priority_selector #(
        .NUM_SOURCES(NUM_SOURCES)
    ) u_priority_selector (
        .priority_levels(priority_levels),
        .index(priority_index),
        .selected_priority(selected_priority)
    );
    
    // 生成掩码
    mask_generator #(
        .WIDTH(NUM_OUTPUTS)
    ) u_mask_generator (
        .shift_amount(selected_priority),
        .mask(mask)
    );
    
    // 输出控制逻辑
    assign reset_outputs = valid_reset ? mask : {NUM_OUTPUTS{1'b0}};
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 模块名: priority_selector
// 描述: 根据索引选择相应的优先级级别
///////////////////////////////////////////////////////////////////////////////

module priority_selector #(
    parameter NUM_SOURCES = 4
)(
    input wire [NUM_SOURCES-1:0] priority_levels,
    input wire [$clog2(NUM_SOURCES+1)-1:0] index,
    output reg [NUM_SOURCES-1:0] selected_priority
);
    // 默认值设置
    always @(*) begin
        selected_priority = {NUM_SOURCES{1'b0}};
    end
    
    // 索引匹配检测
    integer i;
    always @(*) begin
        for (i = 0; i < NUM_SOURCES; i = i + 1) begin
            if (index == i[$clog2(NUM_SOURCES+1)-1:0]) begin
                selected_priority = priority_levels[i];
            end
        end
    end
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 模块名: mask_generator
// 描述: 生成复位掩码 (全1右移指定数量)
///////////////////////////////////////////////////////////////////////////////

module mask_generator #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] shift_amount,
    output wire [WIDTH-1:0] mask
);
    // 预设掩码值
    reg [WIDTH-1:0] full_mask;
    
    // 生成初始全1掩码
    always @(*) begin
        full_mask = {WIDTH{1'b1}};
    end
    
    // 右移生成最终掩码
    assign mask = full_mask >> shift_amount;
    
endmodule