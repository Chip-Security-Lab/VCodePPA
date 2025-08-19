//SystemVerilog
// 顶层模块
module counter_max #(
    parameter MAX = 15
)(
    input  wire clk,
    input  wire rst,
    output wire [$clog2(MAX):0] cnt
);
    // 内部信号
    wire [$clog2(MAX):0] next_cnt;
    wire max_reached;
    
    // 子模块实例化
    counter_logic #(
        .MAX(MAX)
    ) counter_logic_inst (
        .current_cnt(cnt),
        .max_reached(max_reached),
        .next_cnt(next_cnt)
    );
    
    counter_register #(
        .WIDTH($clog2(MAX)+1)
    ) counter_register_inst (
        .clk(clk),
        .rst(rst),
        .next_value(next_cnt),
        .current_value(cnt)
    );
    
    max_detector #(
        .MAX(MAX)
    ) max_detector_inst (
        .current_cnt(cnt),
        .max_reached(max_reached)
    );
    
endmodule

// 计数逻辑子模块 - 负责确定下一个计数值
module counter_logic #(
    parameter MAX = 15
)(
    input  wire [$clog2(MAX):0] current_cnt,
    input  wire max_reached,
    output reg  [$clog2(MAX):0] next_cnt
);
    always @(*) begin
        if (max_reached) begin
            next_cnt = MAX;
        end else begin
            next_cnt = current_cnt + 1'b1;
        end
    end
endmodule

// 寄存器子模块 - 负责存储计数值
module counter_register #(
    parameter WIDTH = 5
)(
    input  wire clk,
    input  wire rst,
    input  wire [WIDTH-1:0] next_value,
    output reg  [WIDTH-1:0] current_value
);
    always @(posedge clk) begin
        if (rst)
            current_value <= {WIDTH{1'b0}};
        else
            current_value <= next_value;
    end
endmodule

// 最大值检测子模块 - 检查是否达到最大值
module max_detector #(
    parameter MAX = 15
)(
    input  wire [$clog2(MAX):0] current_cnt,
    output reg  max_reached
);
    always @(*) begin
        if (current_cnt == MAX) begin
            max_reached = 1'b1;
        end else begin
            max_reached = 1'b0;
        end
    end
endmodule