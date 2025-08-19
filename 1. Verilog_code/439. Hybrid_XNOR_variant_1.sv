//SystemVerilog
`timescale 1ns / 1ps
module Hybrid_XNOR(
    // AXI-Stream输入接口
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [9:0]  s_axis_tdata,  // [9:8]=ctrl, [7:0]=base
    input  wire        s_axis_tlast,
    
    // AXI-Stream输出接口
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [7:0]  m_axis_tdata,  // [7:0]=res
    output wire        m_axis_tlast,
    
    // 系统信号
    input  wire        aclk,
    input  wire        aresetn
);

    // 内部寄存器
    reg [9:0]  input_data_reg;
    reg        data_valid_reg;
    reg        last_reg;
    
    // 提取控制和数据信号
    wire [1:0] ctrl = input_data_reg[9:8];
    wire [7:0] base = input_data_reg[7:0];
    
    // 计算逻辑
    wire [7:0] xnor_pattern;
    wire [3:0] shift_amount = {2'b00, ctrl} << 1; // ctrl * 2
    wire [7:0] multiplier = 8'h01 << shift_amount[2:0];
    assign xnor_pattern = 8'h0F * multiplier;
    
    // 结果计算：XNOR操作
    wire [7:0] res = ~(base ^ xnor_pattern);
    
    // AXI-Stream握手和数据流控制
    assign s_axis_tready = !data_valid_reg || (m_axis_tready && m_axis_tvalid);
    assign m_axis_tvalid = data_valid_reg;
    assign m_axis_tdata = res;
    assign m_axis_tlast = last_reg;
    
    // 输入数据捕获逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            input_data_reg <= 10'b0;
            data_valid_reg <= 1'b0;
            last_reg <= 1'b0;
        end
        else begin
            if (s_axis_tvalid && s_axis_tready) begin
                input_data_reg <= s_axis_tdata;
                data_valid_reg <= 1'b1;
                last_reg <= s_axis_tlast;
            end
            else if (m_axis_tvalid && m_axis_tready) begin
                data_valid_reg <= 1'b0;
            end
        end
    end

endmodule