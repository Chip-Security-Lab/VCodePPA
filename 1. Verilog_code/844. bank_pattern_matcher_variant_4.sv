//SystemVerilog
// 顶层模块
module bank_pattern_matcher #(parameter W = 8, BANKS = 4) (
    input clk, rst_n,
    // AXI-Stream输入接口
    input [W-1:0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready,
    
    // 配置接口
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    
    // AXI-Stream输出接口
    output m_axis_tdata,
    output m_axis_tvalid,
    input m_axis_tready
);
    // 内部信号
    wire pattern_match_result;
    wire [W-1:0] selected_pattern;
    
    // 握手信号生成
    reg s_ready_reg;
    wire processing_valid;
    
    // 数据有效且从机准备好时进行处理
    assign processing_valid = s_axis_tvalid & s_axis_tready;
    
    // AXI-Stream从机准备好信号生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            s_ready_reg <= 1'b1;
        else
            s_ready_reg <= m_axis_tready; // 当下游准备好接收数据时，才接收上游数据
    end
    
    assign s_axis_tready = s_ready_reg;
    
    // 实例化模式选择子模块
    pattern_selector #(
        .W(W),
        .BANKS(BANKS)
    ) u_pattern_selector (
        .patterns(patterns),
        .bank_sel(bank_sel),
        .selected_pattern(selected_pattern)
    );
    
    // 实例化模式比较子模块
    pattern_comparator #(
        .W(W)
    ) u_pattern_comparator (
        .data(s_axis_tdata),
        .pattern(selected_pattern),
        .match_result(pattern_match_result)
    );
    
    // 实例化寄存器控制子模块（现已包含AXI-Stream握手机制）
    register_control u_register_control (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(pattern_match_result),
        .valid_in(processing_valid),
        .ready_out(m_axis_tready),
        .data_out(m_axis_tdata),
        .valid_out(m_axis_tvalid)
    );
endmodule

// 模式选择子模块
module pattern_selector #(parameter W = 8, BANKS = 4) (
    input [W-1:0] patterns [BANKS-1:0],
    input [$clog2(BANKS)-1:0] bank_sel,
    output [W-1:0] selected_pattern
);
    assign selected_pattern = patterns[bank_sel];
endmodule

// 模式比较子模块
module pattern_comparator #(parameter W = 8) (
    input [W-1:0] data,
    input [W-1:0] pattern,
    output match_result
);
    assign match_result = (data == pattern);
endmodule

// 寄存器控制子模块（已更新为AXI-Stream兼容）
module register_control (
    input clk,
    input rst_n,
    input data_in,
    input valid_in,
    input ready_out,
    output reg data_out,
    output reg valid_out
);
    // 数据寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 1'b0;
        else if (valid_in)
            data_out <= data_in;
    end
    
    // 有效信号寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_out <= 1'b0;
        else if (ready_out)
            valid_out <= valid_in;
    end
endmodule