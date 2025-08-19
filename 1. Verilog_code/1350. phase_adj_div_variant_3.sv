//SystemVerilog
module phase_adj_div #(parameter PHASE_STEP=2) (
    input clk, rst, adj_up,
    output reg clk_out
);
    reg [7:0] phase;
    reg [7:0] cnt;
    wire [7:0] phase_half;
    wire [7:0] cnt_threshold;
    
    // 优化：使用条件运算符直接计算phase变化值，避免中间信号
    wire [7:0] phase_change = adj_up ? PHASE_STEP : -PHASE_STEP;
    
    // 优化：直接计算phase_half，不需要显式右移
    assign phase_half = phase >> 1;
    
    // 优化：直接计算比较阈值，避免多余的补码操作
    assign cnt_threshold = 8'd200 - phase;
    
    always @(posedge clk) begin
        if(rst) begin
            cnt <= 8'd0;
            phase <= 8'd0;
            clk_out <= 1'b0;
        end else begin
            // 更新phase
            phase <= phase + phase_change;
            
            // 优化：使用等于比较而不是带补码的比较
            cnt <= (cnt >= cnt_threshold) ? 8'd0 : cnt + 8'd1;
            
            // 优化：直接使用比较而不是计算中间比较值
            clk_out <= (cnt < (8'd100 - phase_half));
        end
    end
endmodule