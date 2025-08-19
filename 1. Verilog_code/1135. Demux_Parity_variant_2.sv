//SystemVerilog
`timescale 1ns / 1ps

module Demux_Parity #(
    parameter DW = 9
)(
    input                  clk,           // 时钟输入以支持流水线
    input                  rst_n,         // 复位信号
    input      [DW-2:0]    data_in,       // 输入数据
    input      [2:0]       addr,          // 地址选择
    output reg [7:0][DW-1:0] data_out     // 输出数据数组
);

    // 第一级流水线 - 计算奇偶校验与借位减法
    reg [DW-2:0] data_in_r;
    reg [2:0]    addr_r;
    reg          parity_r;
    reg [DW-2:0] subtracted_data_r;
    
    // 固定的减数值
    localparam [DW-2:0] SUBTRACTOR = 8'h55; // 选择一个固定值作为减数
    
    // 计算奇偶校验的组合逻辑
    wire parity = ^data_in;
    
    // 先行借位减法器实现
    wire [DW-2:0] p, g, borrow;
    wire [DW-1:0] result; // 额外一位用于处理可能的下溢
    
    // 生成传播信号和生成信号
    assign p = data_in | SUBTRACTOR;
    assign g = ~data_in & SUBTRACTOR;
    
    // 计算借位
    assign borrow[0] = g[0];
    genvar i;
    generate
        for (i = 1; i < DW-1; i = i + 1) begin : borrow_gen
            assign borrow[i] = g[i] | (p[i] & borrow[i-1]);
        end
    endgenerate
    
    // 计算减法结果
    assign result[0] = data_in[0] ^ SUBTRACTOR[0];
    generate
        for (i = 1; i < DW-1; i = i + 1) begin : sub_gen
            assign result[i] = data_in[i] ^ SUBTRACTOR[i] ^ borrow[i-1];
        end
    endgenerate
    
    // 第二级流水线 - 数据路由
    reg [7:0][DW-1:0] data_out_comb;
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_r <= {(DW-1){1'b0}};
            addr_r    <= 3'b000;
            parity_r  <= 1'b0;
            subtracted_data_r <= {(DW-1){1'b0}};
        end else begin
            data_in_r <= data_in;
            addr_r    <= addr;
            parity_r  <= parity;
            subtracted_data_r <= result[DW-2:0]; // 存储减法结果
        end
    end
    
    // 数据路由组合逻辑
    always @(*) begin
        // 默认所有输出置零
        data_out_comb = {8{{{(DW){1'b0}}}}};
        
        // 根据地址选择决定使用原始数据还是减法结果
        if (addr_r[0]) begin
            // 奇数地址使用减法结果
            data_out_comb[addr_r] = {parity_r, subtracted_data_r};
        end else begin
            // 偶数地址使用原始数据
            data_out_comb[addr_r] = {parity_r, data_in_r};
        end
    end
    
    // 第二级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {8{{{(DW){1'b0}}}}};
        end else begin
            data_out <= data_out_comb;
        end
    end

endmodule