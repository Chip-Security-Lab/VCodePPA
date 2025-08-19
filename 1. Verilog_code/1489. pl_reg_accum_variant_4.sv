//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
module pl_reg_accum #(parameter W=8) (
    input wire clk,
    input wire rst,
    input wire add_en,
    input wire [W-1:0] add_val,
    output wire [W-1:0] sum
);

    // 寄存器-向后移位重定时优化
    reg [W-1:0] add_val_reg;
    reg add_en_reg;
    reg [W-1:0] sum_internal;
    
    // 将输入信号寄存优化时序裕量
    always @(posedge clk) begin
        if (rst) begin
            add_val_reg <= {W{1'b0}};
            add_en_reg <= 1'b0;
        end else begin
            add_val_reg <= add_val;
            add_en_reg <= add_en;
        end
    end
    
    // 累加逻辑-现在使用寄存的输入信号
    always @(posedge clk) begin
        if (rst) begin
            sum_internal <= {W{1'b0}};
        end else if (add_en_reg) begin
            sum_internal <= sum_internal + add_val_reg;
        end
    end
    
    // 输出直接连接到内部寄存器
    assign sum = sum_internal;

endmodule