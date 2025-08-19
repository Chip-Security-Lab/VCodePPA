//SystemVerilog
module ripple_counter (
    input wire clk, rst_n,
    output reg [3:0] q
);
    // 内部信号声明
    reg [3:0] next_q;
    
    // 复位逻辑处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 4'b0000;
        else
            q <= next_q;
    end
    
    // 计数逻辑处理
    always @(*) begin
        next_q = q + 4'b0001;
    end
endmodule