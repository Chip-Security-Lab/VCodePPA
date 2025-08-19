module bitwise_transform(
    input wire clk,
    input wire rst_n,
    input wire [3:0] in_data,
    output reg [3:0] out_data
);

    // 输入数据寄存器
    reg [3:0] in_reg;
    
    // 中间处理寄存器
    reg [3:0] proc_reg;
    
    // 输入数据锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 4'b0;
        end else begin
            in_reg <= in_data;
        end
    end
    
    // 位重排序处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            proc_reg <= 4'b0;
        end else begin
            proc_reg <= {in_reg[0], in_reg[1], in_reg[2], in_reg[3]};
        end
    end
    
    // 输出数据锁存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 4'b0;
        end else begin
            out_data <= proc_reg;
        end
    end

endmodule