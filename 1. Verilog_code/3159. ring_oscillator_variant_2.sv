//SystemVerilog
module ring_oscillator(
    input enable,
    output clk_out
);
    // 使用reg类型存储状态，避免组合逻辑环路警告
    reg [4:0] chain;
    
    // 使用非阻塞赋值更新每个环节的状态
    always @(*) begin
        if (enable) begin
            chain[0] <= ~chain[4];
            chain[1] <= chain[0];  // 去除多余的非门，使用缓冲提高驱动能力
            chain[2] <= ~chain[1]; // 保留必要的反相
            chain[3] <= chain[2];  // 去除多余的非门，使用缓冲提高驱动能力
            chain[4] <= ~chain[3]; // 保留必要的反相
        end else begin
            chain <= 5'b0;         // 禁用时清零所有链节点
        end
    end
    
    // 缓冲输出以改善驱动能力
    assign clk_out = enable ? chain[4] : 1'b0;
endmodule