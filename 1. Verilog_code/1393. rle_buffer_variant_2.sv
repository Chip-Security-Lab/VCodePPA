//SystemVerilog
module rle_buffer #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [2*DW-1:0] dout
);
    reg [DW-1:0] prev;       // 存储前一个输入值
    reg [DW-1:0] count;      // 计数器，记录相同值连续出现的次数
    reg is_same_reg;         // 寄存器化的比较结果
    
    // 中间寄存器，用于存储输出组合逻辑的结果
    reg [DW-1:0] count_out;
    reg [DW-1:0] prev_out;
    reg output_valid;
    
    // 初始化寄存器
    initial begin
        count = 0;
        prev = {DW{1'b0}};
        is_same_reg = 1'b0;
        count_out = 0;
        prev_out = {DW{1'b0}};
        output_valid = 1'b0;
        dout = {2*DW{1'b0}};
    end
    
    // 寄存器化比较结果以打破组合逻辑路径
    always @(posedge clk) begin
        if (en) begin
            is_same_reg <= (din == prev);
        end
    end
    
    // 更新前一个值寄存器和计数器逻辑
    always @(posedge clk) begin
        if (en) begin
            if (!is_same_reg) begin
                prev <= din;
                count <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end
    
    // 将输出逻辑分为两阶段 - 第一阶段准备数据
    always @(posedge clk) begin
        if (en) begin
            output_valid <= !is_same_reg;
            count_out <= count;
            prev_out <= prev;
        end else begin
            output_valid <= 1'b0;
        end
    end
    
    // 第二阶段 - 最终输出
    always @(posedge clk) begin
        if (output_valid) begin
            dout <= {count_out, prev_out};
        end
    end
endmodule