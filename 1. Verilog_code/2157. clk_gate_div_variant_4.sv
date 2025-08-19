//SystemVerilog
module clk_gate_div #(parameter DIV=2) (
    input  wire clk,     // 输入时钟
    input  wire en,      // 使能信号
    output reg  clk_out  // 分频输出时钟
);

    reg [7:0] cnt;       // 分频计数器
    reg en_reg;          // 使能信号寄存器
    
    wire cnt_max;        // 计数最大值指示
    wire cnt_zero;       // 计数为零指示
    wire toggle_clk;     // 时钟切换信号

    // 将使能信号寄存
    always @(posedge clk) begin
        en_reg <= en;
    end

    // 计数条件逻辑 - 移到寄存器后面
    assign cnt_max = (cnt == DIV-1);
    assign cnt_zero = (cnt == 0);
    assign toggle_clk = en_reg && cnt_zero;

    // 计数器逻辑 - 负责计数器的更新
    always @(posedge clk) begin
        if (en_reg) begin
            if (cnt_max)
                cnt <= 8'd0;
            else
                cnt <= cnt + 8'd1;
        end
    end

    // 时钟输出逻辑 - 使用预计算的切换信号
    always @(posedge clk) begin
        if (toggle_clk)
            clk_out <= ~clk_out;
    end

endmodule