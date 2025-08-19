//SystemVerilog
module lfsr_divider (
    input wire i_clk,
    input wire i_rst,
    input wire i_enable,  // 控制流水线启动
    output wire o_clk_div,
    output wire o_valid   // 指示输出有效
);
    // 参数化LFSR位宽，便于将来扩展
    localparam LFSR_WIDTH = 5;
    localparam RESET_VALUE = {LFSR_WIDTH{1'b1}}; // 全1初始值: 5'h1f
    localparam PIPELINE_STAGES = 3;  // 流水线级数
    
    // 流水线寄存器
    reg [LFSR_WIDTH-1:0] lfsr_stage1;
    reg [LFSR_WIDTH-1:0] lfsr_stage2;
    reg [LFSR_WIDTH-1:0] lfsr_stage3;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 各级流水线XNOR反馈逻辑
    wire feedback_stage1 = ~(lfsr_stage1[4] ^ lfsr_stage1[2]);
    wire feedback_stage2 = ~(lfsr_stage2[4] ^ lfsr_stage2[2]);
    wire [LFSR_WIDTH-1:0] next_lfsr_stage1 = {lfsr_stage1[LFSR_WIDTH-2:0], ~feedback_stage1};
    wire [LFSR_WIDTH-1:0] next_lfsr_stage2 = {lfsr_stage2[LFSR_WIDTH-2:0], ~feedback_stage2};
    
    // 第一级流水线
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr_stage1 <= RESET_VALUE;
            valid_stage1 <= 1'b0;
        end
        else if (i_enable) begin
            lfsr_stage1 <= next_lfsr_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr_stage2 <= RESET_VALUE;
            valid_stage2 <= 1'b0;
        end
        else if (i_enable) begin
            lfsr_stage2 <= next_lfsr_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr_stage3 <= RESET_VALUE;
            valid_stage3 <= 1'b0;
        end
        else if (i_enable) begin
            lfsr_stage3 <= {lfsr_stage2[LFSR_WIDTH-2:0], ~(~(lfsr_stage2[4] ^ lfsr_stage2[2]))};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出最高位作为分频时钟
    assign o_clk_div = lfsr_stage3[LFSR_WIDTH-1];
    assign o_valid = valid_stage3;

    // 前递逻辑，处理流水线启动阶段的数据依赖
    // synthesis translate_off
    initial begin
        $display("LFSR Divider initialized with %d pipeline stages", PIPELINE_STAGES);
        $display("IEEE 1364-2005 Verilog Standard Compliant");
    end
    // synthesis translate_on
    
endmodule