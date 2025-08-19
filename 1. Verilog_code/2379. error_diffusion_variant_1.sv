//SystemVerilog
module error_diffusion (
    input clk,
    input req,          // 请求信号，替代原valid信号
    input [7:0] in,     // 输入数据
    output reg ack,     // 应答信号，替代原ready信号
    output reg [3:0] out // 输出数据
);

    reg [11:0] err;
    reg [7:0] in_r;     // 寄存器化输入数据
    reg req_r;
    reg processing;
    reg [11:0] sum_r;   // 寄存器化求和结果

    // 前向重定时：将计算逻辑移动到寄存器之后
    always @(posedge clk) begin
        // 寄存器化输入数据
        in_r <= in;
        req_r <= req;
        
        // 寄存器化计算结果
        sum_r <= in + err;
        
        if (req && !req_r && !processing) begin
            // 新请求到达且未处理中
            out <= sum_r[11:8];
            err <= (sum_r << 4) - (sum_r[11:8] << 8);
            ack <= 1'b1;
            processing <= 1'b1;
        end else if (processing && req_r && !req) begin
            // 请求已撤销，完成处理
            ack <= 1'b0;
            processing <= 1'b0;
        end
    end
    
endmodule