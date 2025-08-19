//SystemVerilog
module counter_pulse #(parameter CYCLE=10) (
    input clk, rst,
    output reg pulse
);
    reg [$clog2(CYCLE)-1:0] cnt_reg;
    wire [$clog2(CYCLE)-1:0] cnt_next;
    wire next_pulse;
    
    // 将组合逻辑计算移到寄存器前
    assign next_pulse = (cnt_reg == CYCLE-2);
    assign cnt_next = (cnt_reg == CYCLE-1) ? 0 : cnt_reg + 1;
    
    // 寄存器推移到组合逻辑之后
    always @(posedge clk) begin
        if (rst) begin
            cnt_reg <= 0;
            pulse <= 0;
        end else begin
            cnt_reg <= cnt_next;
            pulse <= next_pulse;
        end
    end
endmodule