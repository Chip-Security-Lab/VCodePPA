//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: priority_clock_gate_top.v
// Description: Top level module for priority-based clock gating
///////////////////////////////////////////////////////////////////////////////

module priority_clock_gate (
    input  wire       clk_in,
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] clk_out
);
    wire [3:0] grant_vec;
    
    // 优先级仲裁器子模块实例化
    priority_arbiter u_priority_arbiter (
        .prio_vec   (prio_vec),
        .req_vec    (req_vec),
        .grant_vec  (grant_vec)
    );
    
    // 时钟门控子模块实例化
    clock_gater u_clock_gater (
        .clk_in     (clk_in),
        .enable_vec (grant_vec),
        .clk_out    (clk_out)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 优先级仲裁器子模块 - 计算每个请求的优先级授权
///////////////////////////////////////////////////////////////////////////////

module priority_arbiter (
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] grant_vec
);
    // 内部信号，表示每一级的优先级授权
    wire [3:0] level_grant;
    
    // 计算每一级的独立授权，考虑优先级
    assign level_grant[0] = req_vec[0] & prio_vec[0];
    assign level_grant[1] = req_vec[1] & prio_vec[1];
    assign level_grant[2] = req_vec[2] & prio_vec[2];
    assign level_grant[3] = req_vec[3] & prio_vec[3];
    
    // 应用优先级规则计算最终授权
    assign grant_vec[0] = req_vec[0];  // 最高优先级总是被授权
    assign grant_vec[1] = req_vec[1] & ~level_grant[0];  // 被0级屏蔽
    assign grant_vec[2] = req_vec[2] & ~(level_grant[0] | level_grant[1]);  // 被0和1级屏蔽
    assign grant_vec[3] = req_vec[3] & ~(level_grant[0] | level_grant[1] | level_grant[2]);  // 被0、1和2级屏蔽
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// 时钟门控子模块 - 根据授权信号控制时钟输出
///////////////////////////////////////////////////////////////////////////////

module clock_gater (
    input  wire       clk_in,
    input  wire [3:0] enable_vec,
    output reg  [3:0] clk_out
);
    // 使用always块实现时钟门控以提高电源效率
    always @(*) begin
        integer i;
        for (i = 0; i < 4; i = i + 1) begin
            clk_out[i] = enable_vec[i] ? clk_in : 1'b0;
        end
    end
    
endmodule