//SystemVerilog
// 顶层模块 - AXI-Stream接口版本
module decoder_multi_protocol (
    input wire aclk,                  // 时钟信号
    input wire aresetn,               // 复位信号，低电平有效
    
    // AXI-Stream输入接口
    input wire [15:0] s_axis_tdata,   // 输入数据，包含地址信息
    input wire s_axis_tvalid,         // 输入数据有效信号
    input wire s_axis_tlast,          // 输入数据结束信号
    output wire s_axis_tready,        // 输入就绪信号
    
    // AXI-Stream输出接口
    output wire [3:0] m_axis_tdata,   // 输出选择信号
    output wire m_axis_tvalid,        // 输出数据有效信号
    output wire m_axis_tlast,         // 输出数据结束信号
    input wire m_axis_tready          // 输出就绪信号
);
    // 内部信号
    reg [15:0] addr_reg;              // 存储地址的寄存器
    reg mode_reg;                     // 存储模式的寄存器
    wire [3:0] mode0_sel;
    wire [3:0] mode1_sel;
    wire [3:0] sel;
    reg processing;                   // 处理状态指示
    reg tlast_reg;                    // 存储tlast信号
    
    // 输入握手和数据捕获逻辑
    assign s_axis_tready = !processing || m_axis_tready;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            addr_reg <= 16'h0;
            mode_reg <= 1'b0;
            processing <= 1'b0;
            tlast_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                addr_reg <= s_axis_tdata;      // 捕获地址
                mode_reg <= s_axis_tdata[15];  // 使用最高位作为模式选择
                tlast_reg <= s_axis_tlast;
                processing <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                processing <= 1'b0;
            end
        end
    end
    
    // 模式0解码器实例
    mode0_decoder mode0_inst (
        .addr(addr_reg),
        .sel(mode0_sel)
    );
    
    // 模式1解码器实例
    mode1_decoder mode1_inst (
        .addr(addr_reg),
        .sel(mode1_sel)
    );
    
    // 模式选择多路复用器
    mode_mux mode_selector (
        .mode(mode_reg),
        .mode0_sel(mode0_sel),
        .mode1_sel(mode1_sel),
        .sel(sel)
    );
    
    // 输出握手逻辑
    assign m_axis_tdata = sel;
    assign m_axis_tvalid = processing;
    assign m_axis_tlast = tlast_reg;
    
endmodule

// 模式0解码器子模块 - 高4位匹配检测
module mode0_decoder (
    input wire [15:0] addr,
    output wire [3:0] sel
);
    // 参数定义
    localparam MATCH_VALUE = 4'ha;
    
    // 高4位匹配逻辑
    wire match;
    assign match = (addr[15:12] == MATCH_VALUE);
    
    // 输出选择逻辑
    assign sel = match ? addr[3:0] : 4'b0000;
    
endmodule

// 模式1解码器子模块 - 中间4位匹配检测
module mode1_decoder (
    input wire [15:0] addr,
    output wire [3:0] sel
);
    // 参数定义
    localparam MATCH_VALUE = 4'h5;
    
    // 中间4位匹配逻辑
    wire match;
    assign match = (addr[7:4] == MATCH_VALUE);
    
    // 输出选择逻辑
    assign sel = match ? addr[3:0] : 4'b0000;
    
endmodule

// 模式选择多路复用器子模块
module mode_mux (
    input wire mode,
    input wire [3:0] mode0_sel,
    input wire [3:0] mode1_sel,
    output wire [3:0] sel
);
    // 基于模式选择输出
    assign sel = mode ? mode1_sel : mode0_sel;
    
endmodule