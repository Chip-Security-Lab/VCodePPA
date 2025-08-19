//SystemVerilog
module param_jk_register #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire [WIDTH-1:0] j,
    input wire [WIDTH-1:0] k,
    output wire [WIDTH-1:0] q
);
    // 实例化 WIDTH 个优化后的 JK 触发器单元
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : jk_ff_gen
            jk_flip_flop_opt jk_ff_inst (
                .clk(clk),
                .j(j[i]),
                .k(k[i]),
                .q(q[i])
            );
        end
    endgenerate
endmodule

// 优化后的 JK 触发器子模块
module jk_flip_flop_opt (
    input wire clk,
    input wire j,
    input wire k,
    output reg q
);
    // 预解码控制信号减少关键路径长度
    reg keep_state, reset_state, set_state, toggle_state;
    
    // 将组合逻辑分解为并行的简单条件，平衡路径延迟
    always @(*) begin
        keep_state = (j == 1'b0) && (k == 1'b0);
        reset_state = (j == 1'b0) && (k == 1'b1);
        set_state = (j == 1'b1) && (k == 1'b0);
        toggle_state = (j == 1'b1) && (k == 1'b1);
    end
    
    // 使用预解码信号控制状态转换，减少关键路径长度
    always @(posedge clk) begin
        if (reset_state)
            q <= 1'b0;
        else if (set_state)
            q <= 1'b1;
        else if (toggle_state)
            q <= ~q;
        // keep_state隐含在else条件中，不需要额外判断
    end
endmodule