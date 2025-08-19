//SystemVerilog
// Hierarchical PipeMux with modular submodules

module PipeMux #(
    parameter DW = 8,         // Data width
    parameter STAGES = 2      // Number of pipeline stages
)(
    input wire clk,
    input wire rst,
    input wire [3:0] sel,
    input wire [(16*DW)-1:0] din,
    output wire [DW-1:0] dout
);

    wire [DW-1:0] mux_out;
    wire [DW-1:0] stage0_out;
    wire [DW-1:0] stage1_out;

    // 多路选择子模块实例化
    Mux16to1 #(
        .DW(DW)
    ) u_mux16to1 (
        .sel(sel),
        .din(din),
        .dout(mux_out)
    );

    // 一级流水线寄存器
    PipeReg #(
        .DW(DW)
    ) u_stage0 (
        .clk(clk),
        .rst(rst),
        .din(mux_out),
        .dout(stage0_out)
    );

    // 二级流水线寄存器，仅当STAGES>1时启用
    generate
        if (STAGES > 1) begin : gen_stage1
            PipeReg #(
                .DW(DW)
            ) u_stage1 (
                .clk(clk),
                .rst(rst),
                .din(stage0_out),
                .dout(stage1_out)
            );
            assign dout = stage1_out;
        end else begin : gen_stage1_bypass
            assign dout = stage0_out;
        end
    endgenerate

endmodule

// -------------------------------------------------------------------------
// 16:1 多路选择器子模块
// 根据sel选择din中的一个DW宽的数据输出
module Mux16to1 #(
    parameter DW = 8
)(
    input  wire [3:0] sel,
    input  wire [(16*DW)-1:0] din,
    output reg  [DW-1:0] dout
);
    always @(*) begin
        case (sel)
            4'd0 : dout = din[DW*1-1:DW*0];
            4'd1 : dout = din[DW*2-1:DW*1];
            4'd2 : dout = din[DW*3-1:DW*2];
            4'd3 : dout = din[DW*4-1:DW*3];
            4'd4 : dout = din[DW*5-1:DW*4];
            4'd5 : dout = din[DW*6-1:DW*5];
            4'd6 : dout = din[DW*7-1:DW*6];
            4'd7 : dout = din[DW*8-1:DW*7];
            4'd8 : dout = din[DW*9-1:DW*8];
            4'd9 : dout = din[DW*10-1:DW*9];
            4'd10: dout = din[DW*11-1:DW*10];
            4'd11: dout = din[DW*12-1:DW*11];
            4'd12: dout = din[DW*13-1:DW*12];
            4'd13: dout = din[DW*14-1:DW*13];
            4'd14: dout = din[DW*15-1:DW*14];
            4'd15: dout = din[DW*16-1:DW*15];
            default: dout = {DW{1'b0}};
        endcase
    end
endmodule

// -------------------------------------------------------------------------
// 同步流水线寄存器子模块
// 在时钟上升沿将输入数据锁存到输出
module PipeReg #(
    parameter DW = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire [DW-1:0] din,
    output reg  [DW-1:0] dout
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= {DW{1'b0}};
        end else begin
            dout <= din;
        end
    end
endmodule