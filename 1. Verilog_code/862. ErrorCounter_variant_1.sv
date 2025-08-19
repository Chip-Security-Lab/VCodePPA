//SystemVerilog
// 顶层模块
module ErrorCounter #(
    parameter WIDTH = 8,
    parameter MAX_ERR = 3
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output alarm
);
    // 内部信号连接
    wire pattern_mismatch;
    wire [3:0] error_count;
    
    // 子模块实例化
    PatternComparator #(
        .WIDTH(WIDTH)
    ) u_pattern_comparator (
        .data(data),
        .pattern(pattern),
        .mismatch(pattern_mismatch)
    );
    
    ErrorTracker #(
        .MAX_ERR(MAX_ERR)
    ) u_error_tracker (
        .clk(clk),
        .rst_n(rst_n),
        .error_detected(pattern_mismatch),
        .err_count(error_count),
        .alarm(alarm)
    );
    
endmodule

// 子模块：模式比较器
module PatternComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output mismatch
);
    // 纯组合逻辑比较，检测不匹配
    assign mismatch = (data != pattern);
    
endmodule

// 子模块：错误追踪器
module ErrorTracker #(
    parameter MAX_ERR = 3
)(
    input clk,
    input rst_n,
    input error_detected,
    output reg [3:0] err_count,
    output reg alarm
);
    // 错误计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_count <= 4'b0;
            alarm <= 1'b0;
        end else begin
            // 如果检测到错误则计数加1，否则重置
            err_count <= error_detected ? err_count + 1'b1 : 4'b0;
            // 当错误计数达到阈值时触发警报
            alarm <= (err_count >= MAX_ERR);
        end
    end
    
endmodule