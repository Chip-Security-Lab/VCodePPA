//SystemVerilog
module scan_d_ff (
    input  wire clk,      // 时钟信号
    input  wire rst_n,    // 低电平有效复位信号
    input  wire scan_en,  // 扫描使能信号
    input  wire scan_in,  // 扫描输入数据
    input  wire d,        // 功能输入数据 
    output reg  q,        // 输出寄存器
    output wire scan_out  // 扫描输出数据
);
    // 流水线阶段寄存器声明
    reg scan_en_stage1, scan_en_stage2;   // 扫描使能流水线寄存器
    reg scan_in_stage1, scan_in_stage2;   // 扫描输入流水线寄存器
    reg d_stage1, d_stage2;               // 功能输入流水线寄存器
    reg valid_stage1, valid_stage2;       // 流水线有效信号
    reg data_select_stage1, data_select_stage2; // 数据选择流水线寄存器
    wire mux_out_stage1, mux_out_stage2;  // 多路复用器输出
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_en_stage1 <= 1'b0;
            scan_in_stage1 <= 1'b0;
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            scan_en_stage1 <= scan_en;
            scan_in_stage1 <= scan_in;
            d_stage1 <= d;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第一级流水线 - 数据选择逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_select_stage1 <= 1'b0;
        else
            data_select_stage1 <= scan_en_stage1;
    end
    
    // 第一级流水线 - 多路复用器
    assign mux_out_stage1 = data_select_stage1 ? scan_in_stage1 : d_stage1;
    
    // 第二级流水线 - 中间数据传递
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_en_stage2 <= 1'b0;
            scan_in_stage2 <= 1'b0;
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            data_select_stage2 <= 1'b0;
        end else begin
            scan_en_stage2 <= scan_en_stage1;
            scan_in_stage2 <= scan_in_stage1;
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
            data_select_stage2 <= data_select_stage1;
        end
    end
    
    // 第二级流水线 - 多路复用器
    assign mux_out_stage2 = data_select_stage2 ? scan_in_stage2 : d_stage2;
    
    // 最终输出级 - 存储结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else if (valid_stage2)
            q <= mux_out_stage2;
    end
    
    // 扫描输出赋值
    assign scan_out = q;
    
endmodule