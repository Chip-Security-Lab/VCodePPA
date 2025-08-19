//SystemVerilog
module rle_buffer #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [2*DW-1:0] dout
);
    reg [DW-1:0] prev;
    reg [DW-1:0] count=0;
    reg [DW-1:0] din_reg;
    reg en_reg;
    reg is_same;
    
    // 第一阶段：注册输入信号
    always @(posedge clk) begin
        din_reg <= din;
        en_reg <= en;
        is_same <= (din == prev);
    end
    
    // 第二阶段：处理计数和输出逻辑
    always @(posedge clk) begin
        if(en_reg) begin
            if(is_same) begin
                // 使用补码加法实现加1操作
                count <= count + {{(DW-1){1'b0}}, 1'b1};
            end
            else begin
                dout <= {count, prev};
                prev <= din_reg;
                // 使用补码加法实现设置为1
                count <= {{(DW-1){1'b0}}, 1'b1};
            end
        end
    end
endmodule