//SystemVerilog
module PrescalerTimer #(parameter PRESCALE=8) (
    input clk, rst_n,
    output reg tick
);

reg [$clog2(PRESCALE)-1:0] ps_cnt;
wire [$clog2(PRESCALE)-1:0] next_cnt;
wire borrow;

// 借位减法器实现
assign {borrow, next_cnt} = ps_cnt - (PRESCALE-1) - 1'b1;

always @(posedge clk) begin
    if (!rst_n) begin
        ps_cnt <= 0;
        tick <= 0;
    end else begin
        // 使用借位减法器结果来确定计数器值
        ps_cnt <= borrow ? ps_cnt + 1'b1 : 0;
        tick <= ~borrow;
    end
end

endmodule