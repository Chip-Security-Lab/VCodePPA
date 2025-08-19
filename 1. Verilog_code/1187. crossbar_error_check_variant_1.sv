//SystemVerilog
module crossbar_error_check #(parameter DW=8) (
    input clk, rst,
    input [7:0] parity_in,
    input [2*DW-1:0] din, // 打平的数组
    output reg [2*DW-1:0] dout, // 打平的数组
    output reg error
);
    // 寄存器化输入数据和校验值，将寄存器从输出端移到输入端
    reg [2*DW-1:0] din_reg;
    reg [7:0] parity_in_reg;
    reg parity_mismatch;
    
    // 计算校验值（放在寄存器前面）
    wire [7:0] calc_parity;
    assign calc_parity = ^{din[0 +: DW], din[DW +: DW]};
    
    // 输入寄存器和校验比较阶段
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            din_reg <= 0;
            parity_in_reg <= 0;
            parity_mismatch <= 0;
        end else begin
            din_reg <= din;
            parity_in_reg <= parity_in;
            parity_mismatch <= (parity_in != calc_parity);
        end
    end
    
    // 输出生成阶段 - 将条件运算符转换为if-else结构
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            dout <= 0;
            error <= 0;
        end else begin
            error <= parity_mismatch;
            
            // 替换条件运算符为if-else结构
            if(parity_mismatch) begin
                dout <= 0;
            end else begin
                dout <= din_reg;
            end
        end
    end
endmodule