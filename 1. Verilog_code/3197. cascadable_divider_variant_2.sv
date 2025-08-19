//SystemVerilog
module cascadable_divider (
    input  wire       clk_in,
    input  wire       reset_n,
    input  wire       cascade_en,
    input  wire       ready,
    output reg        clk_out,
    output wire       cascade_out,
    output wire       valid
);

reg [3:0] counter;       // 计数器寄存器
reg       div_complete;  // 分频完成标志
reg       cascade_en_r;  // 寄存输入信号cascade_en
reg       ready_r;       // 寄存输入信号ready

// 输入信号寄存 - 前向重定时优化
always @(posedge clk_in or negedge reset_n) begin
    if (!reset_n) begin
        cascade_en_r <= 1'b0;
        ready_r <= 1'b0;
    end else begin
        cascade_en_r <= cascade_en;
        ready_r <= ready;
    end
end

// 主计数和时钟生成逻辑
always @(posedge clk_in or negedge reset_n) begin
    if (!reset_n) begin
        counter <= 4'd0;
        clk_out <= 1'b0;
        div_complete <= 1'b0;
    end else begin
        // 更新分频完成标志
        div_complete <= (counter == 4'd9);
        
        if (counter == 4'd9) begin
            // 使用寄存后的信号进行逻辑判断
            counter <= (div_complete & cascade_en_r & ready_r) ? 4'd0 : counter;
            clk_out <= (div_complete & cascade_en_r & ready_r) ? ~clk_out : clk_out;
        end else begin
            counter <= counter + 1'b1;
        end
    end
end

// 更新输出逻辑使用寄存的信号
assign valid = div_complete & cascade_en_r;
assign cascade_out = valid & ready_r;

endmodule