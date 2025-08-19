//SystemVerilog
module Timer_PhaseAdjust (
    input clk, rst_n,
    input [3:0] phase,
    output reg out_pulse
);
    reg [3:0] cnt;
    wire phase_match;
    
    // 将等值比较操作移出寄存器逻辑，作为组合逻辑先计算
    assign phase_match = (cnt + 4'h1) == phase;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 4'h0;
            out_pulse <= 1'b0;
        end else begin
            cnt <= cnt + 4'h1;
            // 直接使用预计算的phase_match结果
            out_pulse <= phase_match;
        end
    end
endmodule