//SystemVerilog
//IEEE 1364-2005 Verilog
`timescale 1ns / 1ps

// 顶层模块 - 外部中断确认与中断状态管理单元
module ext_ack_ismu(
    input wire i_clk, i_rst,
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output wire o_int_req,
    output wire [1:0] o_int_id
);
    // 内部连接信号
    wire [3:0] masked_int;
    wire [3:0] pending_int;
    
    // 中断掩码子模块实例化
    int_mask_unit mask_unit (
        .i_int(i_int),
        .i_mask(i_mask),
        .o_masked_int(masked_int)
    );
    
    // 中断状态管理子模块实例化
    int_status_unit status_unit (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_masked_int(masked_int),
        .i_ext_ack(i_ext_ack),
        .i_ack_id(i_ack_id),
        .o_pending_int(pending_int)
    );
    
    // 中断优先级编码器子模块实例化
    int_priority_encoder priority_encoder (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_pending_int(pending_int),
        .o_int_req(o_int_req),
        .o_int_id(o_int_id)
    );
    
endmodule

// 中断掩码子模块 - 负责应用掩码到输入中断
module int_mask_unit(
    input wire [3:0] i_int,
    input wire [3:0] i_mask,
    output wire [3:0] o_masked_int
);
    // 应用掩码到中断信号
    assign o_masked_int = i_int & ~i_mask;
endmodule

// 中断状态管理子模块 - 跟踪中断状态和确认
module int_status_unit(
    input wire i_clk, i_rst,
    input wire [3:0] i_masked_int,
    input wire i_ext_ack,
    input wire [1:0] i_ack_id,
    output reg [3:0] o_pending_int
);
    // 中断状态寄存器
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_pending_int <= 4'h0;
        end else begin
            // 设置新中断为挂起状态
            o_pending_int <= o_pending_int | i_masked_int;
            
            // 当收到确认时清除相应的中断
            if (i_ext_ack)
                o_pending_int[i_ack_id] <= 1'b0;
        end
    end
endmodule

// 中断优先级编码器子模块 - 对挂起中断进行优先级编码
module int_priority_encoder(
    input wire i_clk, i_rst,
    input wire [3:0] i_pending_int,
    output reg o_int_req,
    output reg [1:0] o_int_id
);
    // 优先级编码逻辑
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            o_int_req <= 1'b0;
            o_int_id <= 2'h0;
        end else begin
            if (|i_pending_int) begin
                o_int_req <= 1'b1;
                
                // 从最低位到最高位的优先级编码
                casez(i_pending_int)
                    4'b???1: o_int_id <= 2'd0; // 最高优先级
                    4'b??10: o_int_id <= 2'd1;
                    4'b?100: o_int_id <= 2'd2;
                    4'b1000: o_int_id <= 2'd3; // 最低优先级
                    default: o_int_id <= 2'd0;
                endcase
            end else begin
                o_int_req <= 1'b0;
            end
        end
    end
endmodule