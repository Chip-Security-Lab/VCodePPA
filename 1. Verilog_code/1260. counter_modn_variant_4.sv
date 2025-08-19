//SystemVerilog
//IEEE 1364-2005 Verilog
module counter_modn #(parameter N=10) (
    input wire clk, 
    input wire rst,
    output wire [$clog2(N)-1:0] cnt
);
    // 内部信号连接
    wire [$clog2(N)-1:0] next_cnt;
    reg [$clog2(N)-1:0] cnt_reg;
    
    // 将计数值连接到输出
    assign cnt = cnt_reg;
    
    // 组合逻辑模块实例化
    counter_next_value #(.N(N)) next_value_logic (
        .current_cnt(cnt_reg),
        .next_cnt(next_cnt)
    );
    
    // 时序逻辑模块
    counter_register #(.WIDTH($clog2(N))) register_logic (
        .clk(clk),
        .rst(rst),
        .next_value(next_cnt),
        .current_value(cnt_reg)
    );
endmodule

// 纯组合逻辑模块
module counter_next_value #(parameter N=10) (
    input wire [$clog2(N)-1:0] current_cnt,
    output wire [$clog2(N)-1:0] next_cnt
);
    // 组合逻辑计算下一个计数值
    assign next_cnt = (current_cnt == N-1) ? '0 : current_cnt + 1'b1;
endmodule

// 纯时序逻辑模块
module counter_register #(parameter WIDTH=4) (
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] next_value,
    output reg [WIDTH-1:0] current_value
);
    // 时序逻辑仅在时钟边沿更新
    always @(posedge clk) begin
        if (rst)
            current_value <= {WIDTH{1'b0}};
        else
            current_value <= next_value;
    end
endmodule