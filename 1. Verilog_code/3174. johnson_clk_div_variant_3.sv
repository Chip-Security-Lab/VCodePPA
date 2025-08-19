//SystemVerilog
module johnson_clk_div(
    input clk_i,
    input rst_i,
    input ready_i,          // 接收方准备好接收数据信号
    output valid_o,         // 数据有效信号
    output [3:0] clk_o      // 数据输出
);
    reg [3:0] johnson_cnt;
    reg valid_r;            // 数据有效寄存器
    
    // Johnson计数器逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            johnson_cnt <= 4'b0000;
            valid_r <= 1'b0;
        end
        else begin
            // 当接收方准备好或数据无效时，更新计数器
            if (ready_i || !valid_r) begin
                johnson_cnt <= {~johnson_cnt[0], johnson_cnt[3:1]};
                valid_r <= 1'b1;  // 新数据有效
            end
            // 否则保持当前值直到接收方准备好
        end
    end
    
    assign clk_o = johnson_cnt;
    assign valid_o = valid_r;
endmodule