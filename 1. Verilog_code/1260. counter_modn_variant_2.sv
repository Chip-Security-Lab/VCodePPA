//SystemVerilog
module counter_modn #(parameter N=10) (
    input clk, rst,
    output reg [$clog2(N)-1:0] cnt
);
    wire [$clog2(N)-1:0] next_cnt;
    
    // 实例化组合逻辑模块
    counter_comb #(.N(N)) comb_logic (
        .cnt(cnt),
        .next_cnt(next_cnt)
    );
    
    // 时序逻辑部分
    always @(posedge clk) begin
        if (rst)
            cnt <= {$clog2(N){1'b0}};
        else
            cnt <= next_cnt;
    end
endmodule

// 组合逻辑模块
module counter_comb #(parameter N=10) (
    input [$clog2(N)-1:0] cnt,
    output [$clog2(N)-1:0] next_cnt
);
    wire [$clog2(N)-1:0] max_value;
    wire is_max;
    
    // 常数值 N-1
    assign max_value = N-1;
    
    // 计算当前计数是否达到最大值 - 使用优化的比较逻辑
    wire [$clog2(N):0] p, g;
    wire [$clog2(N):0] borrow;
    
    // 初始条件
    assign p[0] = 1'b0;
    assign g[0] = 1'b0;
    
    // 生成和传播信号
    genvar i;
    generate
        for (i = 0; i < $clog2(N); i = i + 1) begin : gen_pg
            assign p[i+1] = ~cnt[i] | max_value[i];
            assign g[i+1] = ~cnt[i] & max_value[i];
        end
    endgenerate
    
    // 借位计算 - 采用并行结构以减少关键路径延迟
    assign borrow[0] = 1'b0;
    generate
        for (i = 0; i < $clog2(N); i = i + 1) begin : gen_borrow
            assign borrow[i+1] = g[i+1] | (p[i+1] & borrow[i]);
        end
    endgenerate
    
    // 确定是否达到最大值
    assign is_max = ~borrow[$clog2(N)];
    
    // 下一个计数值逻辑
    assign next_cnt = is_max ? {$clog2(N){1'b0}} : cnt + 1'b1;
endmodule