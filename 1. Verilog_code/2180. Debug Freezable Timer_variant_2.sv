//SystemVerilog - IEEE 1364-2005
module debug_timer #(parameter WIDTH = 16)(
    input wire clk, rst_n, enable, debug_mode,
    input wire [WIDTH-1:0] reload,
    output wire [WIDTH-1:0] count,
    output wire expired
);
    // 内部信号
    wire count_max;
    wire should_reload;
    wire should_increment;
    wire reload_pending;

    // 状态控制子模块
    timer_condition_control #(
        .WIDTH(WIDTH)
    ) condition_ctrl (
        .count(count),
        .enable(enable),
        .debug_mode(debug_mode),
        .reload_pending(reload_pending),
        .count_max(count_max),
        .should_reload(should_reload),
        .should_increment(should_increment),
        .expired(expired)
    );

    // 重载控制子模块
    timer_reload_control reload_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .debug_mode(debug_mode),
        .enable(enable),
        .count_max(count_max),
        .reload_pending(reload_pending)
    );

    // 计数器逻辑子模块
    timer_counter #(
        .WIDTH(WIDTH)
    ) counter (
        .clk(clk),
        .rst_n(rst_n),
        .should_reload(should_reload),
        .should_increment(should_increment),
        .reload(reload),
        .count(count)
    );
endmodule

//子模块1: 计算条件控制信号
module timer_condition_control #(parameter WIDTH = 16)(
    input wire [WIDTH-1:0] count,
    input wire enable, debug_mode, reload_pending,
    output wire count_max,
    output wire should_reload,
    output wire should_increment,
    output wire expired
);
    // 提前计算常用条件，减少关键路径
    assign count_max = (count == {WIDTH{1'b1}});
    assign should_reload = (count_max || reload_pending) && enable && !debug_mode;
    assign should_increment = enable && !debug_mode && !count_max && !reload_pending;
    
    // 简化expired计算，使用预计算的条件
    assign expired = count_max && enable && !debug_mode;
endmodule

//子模块2: 重载控制逻辑
module timer_reload_control (
    input wire clk, rst_n,
    input wire debug_mode, enable, count_max,
    output reg reload_pending
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            reload_pending <= 1'b0; 
        end
        else begin
            // 独立处理reload_pending逻辑，消除条件嵌套层次
            if (debug_mode && count_max) begin
                reload_pending <= 1'b1;
            end
            else if ((count_max || reload_pending) && enable && !debug_mode) begin
                reload_pending <= 1'b0;
            end
        end
    end
endmodule

//子模块3: 计数器实现
module timer_counter #(parameter WIDTH = 16)(
    input wire clk, rst_n,
    input wire should_reload, should_increment,
    input wire [WIDTH-1:0] reload,
    output reg [WIDTH-1:0] count
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            count <= {WIDTH{1'b0}}; 
        end
        else begin
            // 分解复杂条件，平衡逻辑路径
            if (should_reload) begin
                count <= reload;
            end 
            else if (should_increment) begin 
                count <= count + 1'b1;
            end
        end
    end
endmodule