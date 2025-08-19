//SystemVerilog
//IEEE 1364-2005 Verilog
module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    // 将原始WIDTH长度的移位寄存器分为多个流水线级
    localparam STAGE1_WIDTH = WIDTH/3;
    localparam STAGE2_WIDTH = WIDTH/3;
    localparam STAGE3_WIDTH = WIDTH - STAGE1_WIDTH - STAGE2_WIDTH;
    
    // 三级流水线寄存器
    reg [STAGE1_WIDTH-1:0] r_shifter_stage1;
    reg [STAGE2_WIDTH-1:0] r_shifter_stage2;
    reg [STAGE3_WIDTH-1:0] r_shifter_stage3;
    
    // 流水线级之间的连接信号
    wire stage1_out = r_shifter_stage1[0];
    wire stage2_out = r_shifter_stage2[0];
    
    // 第一级流水线 - 采用非阻塞赋值以确保正确时序
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n)
            r_shifter_stage1 <= {STAGE1_WIDTH{1'b0}};
        else if (i_en)
            r_shifter_stage1 <= {i_data, r_shifter_stage1[STAGE1_WIDTH-1:1]};
    end
    
    // 第二级流水线
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n)
            r_shifter_stage2 <= {STAGE2_WIDTH{1'b0}};
        else if (i_en)
            r_shifter_stage2 <= {stage1_out, r_shifter_stage2[STAGE2_WIDTH-1:1]};
    end
    
    // 第三级流水线
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n)
            r_shifter_stage3 <= {STAGE3_WIDTH{1'b0}};
        else if (i_en)
            r_shifter_stage3 <= {stage2_out, r_shifter_stage3[STAGE3_WIDTH-1:1]};
    end
    
    // 输出赋值
    assign o_data = r_shifter_stage3[0];
endmodule