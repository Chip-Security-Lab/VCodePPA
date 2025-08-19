//SystemVerilog
module counter_preload #(parameter WIDTH=8) (
    input wire clk, load, en,
    input wire [WIDTH-1:0] data,
    output reg [WIDTH-1:0] cnt
);
    // 内部连线，连接组合逻辑和时序逻辑
    wire [WIDTH-1:0] next_cnt;
    
    // 实例化组合逻辑模块
    counter_preload_comb #(
        .WIDTH(WIDTH)
    ) comb_logic (
        .load(load),
        .en(en),
        .data(data),
        .cnt(cnt),
        .next_cnt(next_cnt)
    );
    
    // 时序逻辑部分
    always @(posedge clk) begin
        cnt <= next_cnt;
    end
endmodule

// 纯组合逻辑模块
module counter_preload_comb #(parameter WIDTH=8) (
    input wire load, en,
    input wire [WIDTH-1:0] data,
    input wire [WIDTH-1:0] cnt,
    output wire [WIDTH-1:0] next_cnt
);
    // 内部信号
    reg [WIDTH-1:0] next_cnt_reg;
    wire subtract_op;
    wire [WIDTH-1:0] subtrahend;
    wire [WIDTH-1:0] adder_result;
    wire cin;
    
    // 组合逻辑实现
    assign subtract_op = 1'b0; // 加法操作
    assign subtrahend = {WIDTH{1'b0}}; // 加数为1时的处理
    assign cin = en ? 1'b1 : 1'b0; // 使能时进位设为1以实现+1操作
    
    // 条件反相减法器实现加法
    assign adder_result = cnt ^ (subtrahend ^ {WIDTH{subtract_op}}) ^ {WIDTH{1'b0}};
    
    // 组合逻辑确定next_cnt的值
    always @(*) begin
        if (load) begin
            next_cnt_reg = data;
        end else if (en) begin
            next_cnt_reg = adder_result + cin + subtract_op;
        end else begin
            next_cnt_reg = cnt;
        end
    end
    
    // 将寄存器类型转换为线网类型输出
    assign next_cnt = next_cnt_reg;
endmodule