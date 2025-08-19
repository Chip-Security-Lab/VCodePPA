//SystemVerilog
`timescale 1ns / 1ps
//IEEE 1364-2005 Verilog标准
module and_xor_nand_gate (
    input  wire         aclk,           // 系统时钟
    input  wire         aresetn,        // 复位信号，低电平有效
    
    // AXI-Stream 输入接口
    input  wire [2:0]   s_axis_tdata,   // 输入数据 {A,B,C}
    input  wire         s_axis_tvalid,  // 输入数据有效
    output wire         s_axis_tready,  // 准备接收数据
    
    // AXI-Stream 输出接口
    output wire         m_axis_tdata,   // 输出数据 Y
    output reg          m_axis_tvalid,  // 输出数据有效
    input  wire         m_axis_tready,  // 下游模块准备接收数据
    output reg          m_axis_tlast    // 指示传输的最后一个数据
);

    // 内部信号声明
    reg [2:0] stage1_data;              // 第一级流水线寄存器
    reg       stage1_valid;             // 第一级有效标志
    
    reg       stage2_AB_and;            // 第二级流水线寄存器
    reg       stage2_AC_nand;           // 第二级流水线寄存器
    reg       stage2_valid;             // 第二级有效标志
    
    reg       stage3_result;            // 第三级流水线寄存器
    reg       stage3_valid;             // 第三级有效标志
    
    reg       stage4_data;              // 第四级流水线寄存器
    reg       stage4_valid;             // 第四级有效标志
    
    wire      internal_ready;           // 内部反压信号
    
    // 生成内部反压信号 - 如果输出未就绪且有效，则停止处理
    assign internal_ready = ~(m_axis_tvalid & ~m_axis_tready);
    
    // 输入接口控制 - 当内部处理就绪时接受新数据
    assign s_axis_tready = internal_ready;
    
    // 输出数据赋值
    assign m_axis_tdata = stage4_data;
    
    // 第一级流水线 - 输入寄存器
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            stage1_data  <= 3'b000;
            stage1_valid <= 1'b0;
        end else if (internal_ready) begin
            if (s_axis_tvalid & s_axis_tready) begin
                stage1_data  <= s_axis_tdata;
                stage1_valid <= 1'b1;
            end else if (stage2_valid) begin
                // 当前级已处理完，但没有新数据到来
                stage1_valid <= 1'b0;
            end
        end
    end

    // 第二级流水线 - 计算逻辑操作结果
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            stage2_AB_and  <= 1'b0;
            stage2_AC_nand <= 1'b0;
            stage2_valid   <= 1'b0;
        end else if (internal_ready) begin
            if (stage1_valid) begin
                stage2_AB_and  <= stage1_data[2] & stage1_data[1];     // A与B的与操作
                stage2_AC_nand <= ~(stage1_data[2] & stage1_data[0]);  // A与C的与非操作
                stage2_valid   <= 1'b1;
            end else if (stage3_valid) begin
                // 当前级已处理完，没有新数据到来
                stage2_valid   <= 1'b0;
            end
        end
    end

    // 第三级流水线 - 合并处理，计算异或结果
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            stage3_result <= 1'b0;
            stage3_valid  <= 1'b0;
        end else if (internal_ready) begin
            if (stage2_valid) begin
                stage3_result <= stage2_AB_and ^ stage2_AC_nand;
                stage3_valid  <= 1'b1;
            end else if (stage4_valid) begin
                // 当前级已处理完，没有新数据到来
                stage3_valid  <= 1'b0;
            end
        end
    end

    // 第四级流水线 - 输出结果
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            stage4_data  <= 1'b0;
            stage4_valid <= 1'b0;
        end else if (internal_ready) begin
            if (stage3_valid) begin
                stage4_data  <= stage3_result;
                stage4_valid <= 1'b1;
            end else if (m_axis_tvalid & m_axis_tready) begin
                // 数据已传输完成
                stage4_valid <= 1'b0;
            end
        end
    end

    // 输出接口控制
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else if (internal_ready) begin
            if (stage4_valid) begin
                m_axis_tvalid <= 1'b1;
                // 此处可根据实际应用确定TLAST信号条件
                // 示例：每个数据都作为一个独立传输
                m_axis_tlast  <= 1'b1;
            end else if (m_axis_tvalid & m_axis_tready) begin
                // 当前数据已被接收，清除有效标志
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule