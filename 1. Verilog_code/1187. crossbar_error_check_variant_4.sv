//SystemVerilog
//IEEE 1364-2005 Verilog
module crossbar_error_check #(
    parameter DW = 8
) (
    input                 clk,
    input                 rst,
    input      [7:0]      parity_in,
    input      [2*DW-1:0] din,      // 打平的数组
    output reg [2*DW-1:0] dout,     // 打平的数组
    output reg            error
);
    // 数据流水线阶段 1: 校验计算
    reg [7:0]      calc_parity_r;
    reg [2*DW-1:0] din_stage1_r;
    
    wire [7:0] calc_parity_w;
    
    // 将宽数据路径分割成较小的段进行校验计算
    wire [DW-1:0] din_low  = din[0 +: DW];
    wire [DW-1:0] din_high = din[DW +: DW];
    
    // 计算校验值
    assign calc_parity_w = ^{din_low, din_high};
    
    // 阶段1寄存器
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            calc_parity_r <= 8'h0;
            din_stage1_r  <= {(2*DW){1'b0}};
        end else begin
            calc_parity_r <= calc_parity_w;
            din_stage1_r  <= din;
        end
    end
    
    // 数据流水线阶段 2: 错误检测与处理
    wire            parity_error_w;
    wire [2*DW-1:0] data_out_w;
    
    // 错误检测逻辑
    assign parity_error_w = (parity_in != calc_parity_r);
    
    // 数据选择逻辑 - 根据校验结果选择输出数据
    assign data_out_w = parity_error_w ? {(2*DW){1'b0}} : din_stage1_r;
    
    // 阶段2寄存器 - 最终输出
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            dout  <= {(2*DW){1'b0}};
            error <= 1'b0;
        end else begin
            dout  <= data_out_w;
            error <= parity_error_w;
        end
    end
    
endmodule