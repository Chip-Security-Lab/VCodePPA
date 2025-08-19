//SystemVerilog
//====================================================================
// 顶层模块 - 中断服务管理单元
//====================================================================
module nesting_ismu #(
    parameter INT_WIDTH = 8
)(
    input                      clk,
    input                      rst,
    input  [INT_WIDTH-1:0]     intr_src,
    input  [INT_WIDTH-1:0]     intr_enable,
    input  [INT_WIDTH-1:0]     intr_priority,
    input  [2:0]               current_level,
    output [2:0]               intr_level,
    output                     intr_active
);

    // 内部信号
    wire [INT_WIDTH-1:0]       active_src;
    wire [2:0]                 max_level;

    // 中断源过滤模块实例化
    intr_filter #(.WIDTH(INT_WIDTH)) u_intr_filter (
        .intr_src(intr_src),
        .intr_enable(intr_enable),
        .active_src(active_src)
    );

    // 优先级计算模块实例化
    priority_encoder #(.WIDTH(INT_WIDTH)) u_priority_encoder (
        .active_src(active_src),
        .intr_priority(intr_priority),
        .current_level(current_level),
        .max_level(max_level)
    );

    // 中断控制寄存器模块实例化
    intr_control_reg u_intr_control_reg (
        .clk(clk),
        .rst(rst),
        .active_src(active_src),
        .max_level(max_level),
        .current_level(current_level),
        .intr_level(intr_level),
        .intr_active(intr_active)
    );

endmodule

//====================================================================
// 子模块1 - 中断源过滤器
//====================================================================
module intr_filter #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] intr_src,
    input  [WIDTH-1:0] intr_enable,
    output [WIDTH-1:0] active_src
);

    // 过滤出使能且触发的中断源
    assign active_src = intr_src & intr_enable;

endmodule

//====================================================================
// 子模块2 - 优先级编码器
//====================================================================
module priority_encoder #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] active_src,
    input  [WIDTH-1:0] intr_priority,
    input  [2:0]       current_level,
    output [2:0]       max_level
);

    // 中间变量声明
    reg [2:0] priority_level;
    reg [WIDTH-1:0] is_higher_priority;
    
    // 生成优先级高于当前级别的中断标志
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_priority_check
            always @(*) begin
                is_higher_priority[i] = active_src[i] && (intr_priority[i] > current_level);
            end
        end
    endgenerate
    
    // 优先级选择逻辑
    always @(*) begin
        priority_level = 3'd0;
        
        // 高位优先的优先级编码器
        if (is_higher_priority[7]) begin
            priority_level = 3'd7;
        end else if (is_higher_priority[6]) begin
            priority_level = 3'd6;
        end else if (is_higher_priority[5]) begin
            priority_level = 3'd5;
        end else if (is_higher_priority[4]) begin
            priority_level = 3'd4;
        end else if (is_higher_priority[3]) begin
            priority_level = 3'd3;
        end else if (is_higher_priority[2]) begin
            priority_level = 3'd2;
        end else if (is_higher_priority[1]) begin
            priority_level = 3'd1;
        end else if (is_higher_priority[0]) begin
            priority_level = 3'd0;
        end
    end
    
    // 输出赋值
    assign max_level = priority_level;

endmodule

//====================================================================
// 子模块3 - 中断控制寄存器
//====================================================================
module intr_control_reg (
    input            clk,
    input            rst,
    input  [7:0]     active_src,
    input  [2:0]     max_level,
    input  [2:0]     current_level,
    output reg [2:0] intr_level,
    output reg       intr_active
);

    // 中间变量
    wire any_active_src;
    wire level_higher;
    wire should_activate;
    
    // 简化中间计算
    assign any_active_src = |active_src;
    assign level_higher = max_level > current_level;
    assign should_activate = any_active_src && level_higher;

    // 同步更新中断状态
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            intr_level <= 3'd0;
            intr_active <= 1'b0;
        end else begin
            // 使用简化的条件变量
            intr_active <= should_activate;
            intr_level <= max_level;
        end
    end

endmodule