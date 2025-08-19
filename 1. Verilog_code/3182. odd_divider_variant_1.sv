//SystemVerilog
module odd_divider #(
    parameter N = 5
)(
    input  wire clk,
    input  wire rst,
    output wire clk_out
);
    // 状态计数器寄存器
    reg [2:0] state_cnt;
    
    // 相位时钟信号
    reg phase_clk_pos;
    reg phase_clk_neg;
    
    // 状态计数器逻辑 - 处理正边沿时钟
    always @(posedge clk or posedge rst) begin
        if (rst) 
            state_cnt <= 3'b000;
        else if (state_cnt == N-1) 
            state_cnt <= 3'b000;
        else 
            state_cnt <= state_cnt + 1'b1;
    end
    
    // 正边沿相位时钟生成 - 处理正边沿时钟
    always @(posedge clk or posedge rst) begin
        if (rst)
            phase_clk_pos <= 1'b0;
        else
            phase_clk_pos <= (state_cnt < (N>>1)) ? 1'b1 : 1'b0;
    end
    
    // 负边沿相位时钟采样 - 处理负边沿时钟
    always @(negedge clk or posedge rst) begin
        if (rst)
            phase_clk_neg <= 1'b0;
        else
            phase_clk_neg <= phase_clk_pos;
    end
    
    // 输出时钟生成
    assign clk_out = phase_clk_pos | phase_clk_neg;
    
endmodule