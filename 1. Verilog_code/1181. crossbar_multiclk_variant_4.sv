//SystemVerilog
module crossbar_multiclk #(
    parameter DW = 8
) (
    input  wire             clk_a,
    input  wire             clk_b,
    input  wire [1:0][DW-1:0] din_a,
    input  wire             valid_in,  // 输入数据有效信号
    output wire             ready_in,  // 输入准备好接收信号
    output reg  [1:0][DW-1:0] dout_b,
    output reg              valid_out  // 输出数据有效信号
);
    // 流水线控制信号
    reg valid_stage1;
    reg valid_stage2_a, valid_stage2_b;  // 分割高扇出控制信号
    reg valid_stage3_a, valid_stage3_b;  // 分割高扇出控制信号
    
    // 流水线数据路径
    reg [1:0][DW-1:0] din_a_reg;         // 输入寄存器
    reg [DW-1:0] sync_stage1_ch0;        // CDC第一级通道0
    reg [DW-1:0] sync_stage1_ch1;        // CDC第一级通道1
    reg [DW-1:0] sync_stage2_ch0;        // CDC第二级通道0
    reg [DW-1:0] sync_stage2_ch1;        // CDC第二级通道1
    reg [DW-1:0] dout_stage_ch0;         // 输出寄存通道0
    reg [DW-1:0] dout_stage_ch1;         // 输出寄存通道1

    // 输入端准备好信号
    assign ready_in = 1'b1;  // 始终准备好接收新数据

    // 第一级流水线 - 输入寄存 (clk_a域)
    always @(posedge clk_a) begin
        if (valid_in && ready_in) begin
            din_a_reg <= din_a;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // 第二级流水线 - 时钟域同步第一级 (clk_a域到clk_b域)
    // 分离数据通道以减少扇出负载
    always @(posedge clk_b) begin
        sync_stage1_ch0 <= din_a_reg[0];
        sync_stage1_ch1 <= din_a_reg[1];
        valid_stage2_a <= valid_stage1;
        valid_stage2_b <= valid_stage1;
    end
    
    // 第三级流水线 - 时钟域同步第二级 (clk_b域)
    always @(posedge clk_b) begin
        sync_stage2_ch0 <= sync_stage1_ch0;
        sync_stage2_ch1 <= sync_stage1_ch1;
        valid_stage3_a <= valid_stage2_a;
        valid_stage3_b <= valid_stage2_b;
    end
    
    // 第四级流水线 - 输出寄存 (clk_b域)
    always @(posedge clk_b) begin
        dout_b[0] <= sync_stage2_ch0;
        dout_b[1] <= sync_stage2_ch1;
        valid_out <= valid_stage3_a & valid_stage3_b; // 确保两路数据同步
    end
endmodule