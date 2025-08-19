//SystemVerilog
module dual_edge_d_ff (
    input wire clk,
    input wire d,
    output reg q
);
    reg d_delayed;
    reg q_posedge, q_negedge;
    
    // 前置寄存器捕获输入数据，减少输入到第一级寄存器的延迟
    always @(*) begin
        d_delayed = d;
    end
    
    // 在正边沿捕获预处理后的数据
    always @(posedge clk) begin
        q_posedge <= d_delayed;
    end
    
    // 在负边沿捕获预处理后的数据
    always @(negedge clk) begin
        q_negedge <= d_delayed;
    end
    
    // 输出多路复用器
    always @(*) begin
        q = clk ? q_posedge : q_negedge;
    end
endmodule