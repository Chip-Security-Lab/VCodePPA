//SystemVerilog
// Structured and pipelined version of 3-input bitwise NOR gate
module nor3_bitwise (
    input  wire        clk,         // 时钟信号
    input  wire        rst_n,       // 异步低有效复位
    input  wire [2:0]  data_in,     // 3位输入
    output wire        nor3_out     // NOR3 输出
);

    // Stage 1: 输入寄存器
    reg [2:0] stage1_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_data <= 3'b0;
        else
            stage1_data <= data_in;
    end

    // Stage 2: 逐位取反
    reg [2:0] stage2_inverted;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_inverted <= 3'b0;
        else
            stage2_inverted <= ~stage1_data;
    end

    // Stage 3: 取反结果与操作
    reg stage3_and_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_and_result <= 1'b0;
        else
            stage3_and_result <= stage2_inverted[0] & stage2_inverted[1] & stage2_inverted[2];
    end

    // 输出寄存器
    reg stage4_output;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage4_output <= 1'b0;
        else
            stage4_output <= stage3_and_result;
    end

    assign nor3_out = stage4_output;

endmodule