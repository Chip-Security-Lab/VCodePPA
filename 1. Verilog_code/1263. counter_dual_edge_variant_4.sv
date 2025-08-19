//SystemVerilog
// 顶层模块
module counter_dual_edge #(
    parameter WIDTH = 4
)(
    input clk,
    input rst,
    output reg [WIDTH-1:0] cnt
);
    // 内部连线
    wire [WIDTH-1:0] pos_cnt_comb, neg_cnt_comb;
    wire [WIDTH-1:0] pos_cnt, neg_cnt;
    wire [WIDTH-1:0] total_comb;
    
    // 实例化上升沿计数器子模块
    posedge_counter #(
        .WIDTH(WIDTH)
    ) pos_counter_inst (
        .clk(clk),
        .rst(rst),
        .count_comb(pos_cnt_comb),
        .count(pos_cnt)
    );
    
    // 实例化下降沿计数器子模块
    negedge_counter #(
        .WIDTH(WIDTH)
    ) neg_counter_inst (
        .clk(clk),
        .rst(rst),
        .count_comb(neg_cnt_comb),
        .count(neg_cnt)
    );
    
    // 计数器加法组合逻辑
    assign total_comb = pos_cnt + neg_cnt;
    
    // 移动后的寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) 
            cnt <= {WIDTH{1'b0}};
        else 
            cnt <= total_comb;
    end
endmodule

// 上升沿计数器子模块
module posedge_counter #(
    parameter WIDTH = 4
)(
    input clk,
    input rst,
    output [WIDTH-1:0] count_comb,
    output reg [WIDTH-1:0] count
);
    // 组合逻辑部分
    assign count_comb = count + 1'b1;
    
    // 寄存器部分
    always @(posedge clk or posedge rst) begin
        if (rst) 
            count <= {WIDTH{1'b0}};
        else 
            count <= count_comb;
    end
endmodule

// 下降沿计数器子模块
module negedge_counter #(
    parameter WIDTH = 4
)(
    input clk,
    input rst,
    output [WIDTH-1:0] count_comb,
    output reg [WIDTH-1:0] count
);
    // 组合逻辑部分
    assign count_comb = count + 1'b1;
    
    // 寄存器部分
    always @(negedge clk or posedge rst) begin
        if (rst) 
            count <= {WIDTH{1'b0}};
        else 
            count <= count_comb;
    end
endmodule