//SystemVerilog
module int_ctrl_error_log #(
    parameter ERR_BITS = 4
)(
    input  wire                clk,
    input  wire                rst,
    input  wire [ERR_BITS-1:0] err_in,
    output reg  [ERR_BITS-1:0] err_log
);

    wire [ERR_BITS-1:0] next_err_log;
    wire                err_in_higher;
    
    // 直接比较err_in和err_log，避免使用大型查找表
    assign err_in_higher = (err_in > err_log);
    
    // 计算下一个错误日志值
    assign next_err_log = err_in_higher ? err_in : (err_log | err_in);
    
    // 更新输出寄存器
    always @(posedge clk) begin
        if (rst)
            err_log <= {ERR_BITS{1'b0}};
        else
            err_log <= next_err_log;
    end

endmodule