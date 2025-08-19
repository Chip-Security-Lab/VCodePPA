//SystemVerilog - IEEE 1364-2005
// 顶层模块 - 使用AXI-Stream接口
module Parity_XNOR (
    input  wire        aclk,
    input  wire        aresetn,
    // AXI-Stream输入接口
    input  wire [7:0]  s_axis_tdata,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    // AXI-Stream输出接口
    output wire        m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);
    // 内部信号
    wire [3:0] partial_parity_low;
    wire [3:0] partial_parity_high;
    wire       parity_low;
    wire       parity_high;
    wire       parity_result;
    
    // 握手控制逻辑
    reg  processing_reg;
    wire input_handshake;
    wire output_handshake;
    
    assign input_handshake = s_axis_tvalid & s_axis_tready;
    assign output_handshake = m_axis_tvalid & m_axis_tready;
    assign s_axis_tready = !processing_reg || output_handshake;
    
    // 处理状态寄存器
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn)
            processing_reg <= 1'b0;
        else if (input_handshake && !output_handshake)
            processing_reg <= 1'b1;
        else if (output_handshake) 
            processing_reg <= 1'b0;
    end
    
    // 实例化低4位奇偶校验计算子模块
    Parity_Calculator_4bit low_bits (
        .data_4bit   (s_axis_tdata[3:0]),
        .partial_res (partial_parity_low)
    );

    // 实例化高4位奇偶校验计算子模块
    Parity_Calculator_4bit high_bits (
        .data_4bit   (s_axis_tdata[7:4]),
        .partial_res (partial_parity_high)
    );

    // 合并低4位计算结果
    Parity_Combiner low_combiner (
        .partial_res (partial_parity_low),
        .parity_out  (parity_low)
    );

    // 合并高4位计算结果
    Parity_Combiner high_combiner (
        .partial_res (partial_parity_high),
        .parity_out  (parity_high)
    );

    // 最终奇偶校验计算 - XNOR操作
    Final_Parity_Calculator final_calculator (
        .parity_low   (parity_low),
        .parity_high  (parity_high),
        .final_parity (parity_result)
    );
    
    // 输出控制逻辑
    reg  result_valid_reg;
    reg  result_data_reg;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            result_valid_reg <= 1'b0;
            result_data_reg <= 1'b0;
        end
        else if (input_handshake) begin
            result_valid_reg <= 1'b1;
            result_data_reg <= parity_result;
        end
        else if (output_handshake) begin
            result_valid_reg <= 1'b0;
        end
    end
    
    // 连接输出信号
    assign m_axis_tdata = result_data_reg;
    assign m_axis_tvalid = result_valid_reg;

endmodule

// 4位奇偶校验计算子模块
module Parity_Calculator_4bit (
    input  wire [3:0] data_4bit,
    output wire [3:0] partial_res
);
    // 为每个位生成部分结果，便于后续组合
    assign partial_res = data_4bit;
endmodule

// 奇偶校验合并子模块
module Parity_Combiner (
    input  wire [3:0] partial_res,
    output wire       parity_out
);
    // 计算4位的奇偶校验
    assign parity_out = ^partial_res;
endmodule

// 最终奇偶校验计算子模块
module Final_Parity_Calculator (
    input  wire parity_low,
    input  wire parity_high,
    output wire final_parity
);
    // 执行最终的XNOR操作
    wire combined_parity;
    
    // 先合并低位和高位的结果
    assign combined_parity = parity_low ^ parity_high;
    
    // 然后执行NOT操作得到XNOR结果
    assign final_parity = ~combined_parity;
endmodule