//SystemVerilog
module gray_ring_counter (
    input wire clk,
    input wire rst_n,
    output reg [3:0] gray_out
);

    // 定义下一个状态信号
    reg [3:0] next_gray;
    
    // 组合逻辑 - 计算下一个状态
    always @(*) begin
        next_gray[3] = gray_out[0];
        next_gray[2] = gray_out[3] ^ gray_out[0];
        next_gray[1] = gray_out[2];
        next_gray[0] = gray_out[1] ^ gray_out[0];
    end
    
    // 时序逻辑 - 状态更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            gray_out <= 4'b0001;
        else 
            gray_out <= next_gray;
    end

endmodule