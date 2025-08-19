//SystemVerilog
module dual_cnt_div #(parameter DIV1=3, DIV2=5) (
    input wire clk, 
    input wire sel,
    output reg clk_out
);
    reg [3:0] cnt1, cnt2;
    wire cnt1_reset, cnt2_reset;
    wire cnt1_pulse, cnt2_pulse;
    wire mux_out;
    
    // 使用比较器明确生成复位和脉冲信号
    assign cnt1_reset = (cnt1 == DIV1-1);
    assign cnt2_reset = (cnt2 == DIV2-1);
    assign cnt1_pulse = (cnt1 == 0);
    assign cnt2_pulse = (cnt2 == 0);
    
    // 使用if-else结构替代三元运算符
    reg selected_pulse;
    always @(*) begin
        if (sel) begin
            selected_pulse = cnt2_pulse;
        end else begin
            selected_pulse = cnt1_pulse;
        end
    end
    assign mux_out = selected_pulse;
    
    always @(posedge clk) begin
        // 计数器逻辑
        if (cnt1_reset) begin
            cnt1 <= 4'b0000;
        end else begin
            cnt1 <= cnt1 + 4'b0001;
        end
        
        if (cnt2_reset) begin
            cnt2 <= 4'b0000;
        end else begin
            cnt2 <= cnt2 + 4'b0001;
        end
        
        // 输出逻辑
        clk_out <= mux_out;
    end
endmodule