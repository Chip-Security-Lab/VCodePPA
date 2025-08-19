//SystemVerilog
module HoldLatch #(parameter W=4) (
    input clk,
    input hold,
    input [W-1:0] d,
    output [W-1:0] q
);

    // 添加缓冲寄存器
    reg [W-1:0] d_buf;
    reg hold_buf;
    
    // 第一级缓冲
    always @(posedge clk) begin
        d_buf <= d;
        hold_buf <= hold;
    end

    // 实例化数据保持子模块
    HoldLatchCore #(.W(W)) hold_core (
        .clk(clk),
        .hold(hold_buf),
        .d(d_buf),
        .q(q)
    );

endmodule

module HoldLatchCore #(parameter W=4) (
    input clk,
    input hold,
    input [W-1:0] d,
    output reg [W-1:0] q
);

    // 第二级缓冲
    reg [W-1:0] d_buf2;
    reg hold_buf2;
    
    always @(posedge clk) begin
        d_buf2 <= d;
        hold_buf2 <= hold;
    end

    always @(posedge clk) begin
        if(!hold_buf2) q <= d_buf2;
    end

endmodule