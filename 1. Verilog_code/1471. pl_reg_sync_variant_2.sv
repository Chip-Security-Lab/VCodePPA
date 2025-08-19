//SystemVerilog
module pl_reg_sync #(parameter W=8) (
    input clk, rst_n, en,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // 中间流水线寄存器
    reg [W-1:0] data_stage1;
    reg [W-1:0] data_stage2;
    
    // 第一级流水线
    always @(posedge clk)
        if (!rst_n) data_stage1 <= 0;
        else if (en) data_stage1 <= data_in;
    
    // 第二级流水线
    always @(posedge clk)
        if (!rst_n) data_stage2 <= 0;
        else if (en) data_stage2 <= data_stage1;
    
    // 第三级流水线（输出级）
    always @(posedge clk)
        if (!rst_n) data_out <= 0;
        else if (en) data_out <= data_stage2;
endmodule