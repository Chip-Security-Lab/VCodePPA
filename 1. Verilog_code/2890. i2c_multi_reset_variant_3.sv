//SystemVerilog
//IEEE 1364-2005 Verilog标准
`timescale 1ns / 1ps
module i2c_multi_reset #(
    parameter RST_SYNC_STAGES = 2
)(
    input clk_core,
    input clk_io,
    input rst_async,
    output rst_sync,
    inout sda,
    inout scl
);
    // 多复位域管理 - 优化后的寄存器结构
    (* ASYNC_REG = "TRUE" *) reg [RST_SYNC_STAGES-1:0] rst_sync_reg;
    wire sda_sync, scl_sync;
    
    // 同步复位生成 - 保持原样，因为这是标准的复位同步器结构
    always @(posedge clk_core or posedge rst_async) begin
        if (rst_async) begin
            rst_sync_reg <= {RST_SYNC_STAGES{1'b1}};
        end else begin
            rst_sync_reg <= {rst_sync_reg[RST_SYNC_STAGES-2:0], 1'b0};
        end
    end

    assign rst_sync = rst_sync_reg[RST_SYNC_STAGES-1];

    // 优化的跨时钟域信号处理 - 使用Baugh-Wooley乘法器实现
    wire [1:0] io_inputs;
    wire [3:0] mul_result; // 2位乘以2位的结果是4位
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage1;
    (* ASYNC_REG = "TRUE" *) reg [1:0] sync_stage2;
    
    // 实现2位Baugh-Wooley乘法器
    wire [1:0] multiplicand; // 乘数
    wire [1:0] multiplier; // 被乘数
    wire p00, p01, p10, p11; // 部分积
    wire neg_p01, neg_p10; // 修正的部分积
    
    assign multiplicand = {sda, scl}; // 使用I/O输入作为乘法输入
    assign multiplier = sync_stage1;  // 使用同步后的值作为另一个乘法输入
    
    // Baugh-Wooley部分积生成
    assign p00 = multiplicand[0] & multiplier[0];
    assign neg_p01 = ~(multiplicand[0] & multiplier[1]); // 取反
    assign neg_p10 = ~(multiplicand[1] & multiplier[0]); // 取反
    assign p11 = multiplicand[1] & multiplier[1];
    
    // 最终乘积计算
    assign mul_result[0] = p00;
    assign mul_result[1] = (~neg_p01 ^ ~neg_p10);
    assign mul_result[2] = (~neg_p01 & ~neg_p10) ^ p11;
    assign mul_result[3] = ((~neg_p01 & ~neg_p10) & p11) | (p11 & 1'b1);
    
    // 输入缓冲器 - 降低输入端负载
    assign io_inputs = {sda, scl};
    
    always @(posedge clk_io) begin
        sync_stage1 <= io_inputs;
        sync_stage2 <= sync_stage1;
    end
    
    // 使用乘法结果的低两位作为同步信号
    assign sda_sync = mul_result[1];
    assign scl_sync = mul_result[0];
    
    // 优化的I2C总线驱动逻辑 - 分离控制和数据路径
    reg sda_oe_ctrl, scl_oe_ctrl;
    reg sda_out_data, scl_out_data;
    reg sda_oe, scl_oe;
    reg sda_out, scl_out;
    
    // 前移控制信号生成逻辑，使用乘法结果控制输出
    always @(posedge clk_io) begin
        if (rst_sync) begin
            sda_oe_ctrl <= 1'b0;
            scl_oe_ctrl <= 1'b0;
            sda_out_data <= 1'b1;
            scl_out_data <= 1'b1;
        end else begin
            // 使用乘法结果控制信号
            sda_oe_ctrl <= mul_result[3]; 
            scl_oe_ctrl <= mul_result[2];
            sda_out_data <= mul_result[1];
            scl_out_data <= mul_result[0];
        end
    end
    
    // 输出寄存器级 - 降低输出切换相关的噪声
    always @(posedge clk_io) begin
        sda_oe <= sda_oe_ctrl;
        scl_oe <= scl_oe_ctrl;
        sda_out <= sda_out_data;
        scl_out <= scl_out_data;
    end
    
    // 三态输出缓冲器
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
endmodule