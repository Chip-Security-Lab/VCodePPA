//SystemVerilog
// 顶层模块 - 异步分频器系统
module async_divider (
    input  wire master_clk,
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk
);
    // 内部连接信号
    wire div_chain0;
    wire div_chain1;
    wire div_chain2;
    
    // 分频器级联实例化
    div_stage #(.STAGE(1)) div_stage1 (
        .clk_in(master_clk),
        .clk_out(div_chain0)
    );
    
    div_stage #(.STAGE(2)) div_stage2 (
        .clk_in(div_chain0),
        .clk_out(div_chain1)
    );
    
    div_stage #(.STAGE(3)) div_stage3 (
        .clk_in(div_chain1),
        .clk_out(div_chain2)
    );
    
    // 输出缓冲模块实例化
    output_buffer output_buffer_inst (
        .master_clk(master_clk),
        .div_chain0(div_chain0),
        .div_chain1(div_chain1),
        .div_chain2(div_chain2),
        .div2_clk(div2_clk),
        .div4_clk(div4_clk),
        .div8_clk(div8_clk)
    );
endmodule

// 单分频级模块 - 实现二分频功能
module div_stage #(
    parameter STAGE = 1  // 分频器阶段标识
)(
    input  wire clk_in,
    output wire clk_out
);
    reg toggle_ff;
    reg buff_out;
    
    // 分频逻辑 - 每个时钟翻转
    always @(posedge clk_in)
        toggle_ff <= ~toggle_ff;
    
    // 缓冲输出以减少负载影响
    always @(posedge clk_in)
        buff_out <= toggle_ff;
    
    assign clk_out = buff_out;
endmodule

// 输出缓冲模块 - 处理所有时钟输出的缓冲
module output_buffer (
    input  wire master_clk,
    input  wire div_chain0,
    input  wire div_chain1,
    input  wire div_chain2,
    output wire div2_clk,
    output wire div4_clk,
    output wire div8_clk
);
    // 输出缓冲寄存器，降低扇出负载
    reg div2_out_reg;
    reg div4_out_reg;
    reg div8_out_reg;
    
    // 同步所有输出到主时钟
    always @(posedge master_clk) begin
        div2_out_reg <= div_chain0;
        div4_out_reg <= div_chain1;
        div8_out_reg <= div_chain2;
    end
    
    // 连接输出
    assign div2_clk = div2_out_reg;
    assign div4_clk = div4_out_reg;
    assign div8_clk = div8_out_reg;
endmodule