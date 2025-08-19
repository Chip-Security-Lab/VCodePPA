//SystemVerilog
// 顶层模块
module compare_match_timer (
    input wire i_clock,
    input wire i_nreset,
    input wire i_enable,
    input wire [23:0] i_compare,
    output wire o_match,
    output wire [23:0] o_counter
);
    // 内部信号定义
    wire [23:0] compare_reg;
    wire enable_reg;
    wire [23:0] timer_cnt;
    
    // 子模块实例化
    input_register input_reg_inst (
        .i_clock(i_clock),
        .i_nreset(i_nreset),
        .i_enable(i_enable),
        .i_compare(i_compare),
        .o_enable_reg(enable_reg),
        .o_compare_reg(compare_reg)
    );
    
    counter_module counter_inst (
        .i_clock(i_clock),
        .i_nreset(i_nreset),
        .i_enable(enable_reg),
        .o_counter(timer_cnt)
    );
    
    match_detector match_inst (
        .i_clock(i_clock),
        .i_nreset(i_nreset),
        .i_enable(enable_reg),
        .i_counter(timer_cnt),
        .i_compare(compare_reg),
        .o_match(o_match)
    );
    
    // 输出计数器值
    assign o_counter = timer_cnt;
    
endmodule

// 输入寄存模块
module input_register (
    input wire i_clock,
    input wire i_nreset,
    input wire i_enable,
    input wire [23:0] i_compare,
    output reg o_enable_reg,
    output reg [23:0] o_compare_reg
);
    // 将输入寄存器化以减少输入到第一级寄存器的延迟
    always @(posedge i_clock) begin
        if (!i_nreset) begin
            o_compare_reg <= 24'h000000;
            o_enable_reg <= 1'b0;
        end else begin
            o_compare_reg <= i_compare;
            o_enable_reg <= i_enable;
        end
    end
endmodule

// 计数器模块
module counter_module (
    input wire i_clock,
    input wire i_nreset,
    input wire i_enable,
    output reg [23:0] o_counter
);
    // 计数器逻辑
    always @(posedge i_clock) begin
        if (!i_nreset) 
            o_counter <= 24'h000000;
        else if (i_enable) 
            o_counter <= o_counter + 24'h000001;
    end
endmodule

// 匹配检测模块
module match_detector (
    input wire i_clock,
    input wire i_nreset,
    input wire i_enable,
    input wire [23:0] i_counter,
    input wire [23:0] i_compare,
    output reg o_match
);
    // 匹配检测逻辑
    always @(posedge i_clock) begin
        if (!i_nreset) 
            o_match <= 1'b0;
        else 
            o_match <= (i_counter == i_compare) && i_enable;
    end
endmodule