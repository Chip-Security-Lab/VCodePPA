//SystemVerilog
module nor4_bits (
    input  wire        clk,         // 时钟信号
    input  wire        rst_n,       // 异步复位，低有效
    input  wire [3:0]  in_data,     // 4位输入数据
    output wire        out_nor      // 输出结果
);

    // 第一流水线级：输入寄存器
    reg [3:0] stage1_in_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_in_data <= 4'b0;
        else
            stage1_in_data <= in_data;
    end

    // 第二流水线级：组合或运算
    reg stage2_or_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_or_result <= 1'b0;
        else
            stage2_or_result <= stage1_in_data[0] | stage1_in_data[1] | stage1_in_data[2] | stage1_in_data[3];
    end

    // 第三流水线级：或非输出寄存器
    reg stage3_nor_output;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_nor_output <= 1'b0;
        else
            stage3_nor_output <= ~stage2_or_result;
    end

    assign out_nor = stage3_nor_output;

endmodule