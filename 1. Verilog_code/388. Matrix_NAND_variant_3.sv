//SystemVerilog
module Matrix_NAND(
    input wire clk,
    input wire rst_n,
    
    // 输入接口
    input wire [3:0] row,
    input wire [3:0] col,
    input wire       valid_in,  // 输入数据有效信号
    output wire      ready_out, // 输入接口就绪信号
    
    // 输出接口
    output reg [7:0] mat_res,
    output reg       valid_out, // 输出数据有效信号
    input wire       ready_in   // 下游模块就绪信号
);
    // 内部信号和状态
    reg [7:0] input_concat;
    wire [7:0] result;
    reg busy;
    
    // 常量
    localparam [7:0] MASK = 8'b10101010; // 8'hAA
    
    // 计算逻辑 - 使用与非门电路实现异或功能
    assign result = input_concat & ~MASK | ~input_concat & MASK;
    
    // 握手控制逻辑
    assign ready_out = !busy | (busy && valid_out && ready_in);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位状态
            input_concat <= 8'h00;
            mat_res <= 8'h00;
            valid_out <= 1'b0;
            busy <= 1'b0;
        end else begin
            // 正常操作
            if (!busy) begin
                // 获取输入数据
                if (valid_in && ready_out) begin
                    input_concat <= {row, col};
                    busy <= 1'b1;
                end
            end else begin
                // 处理完成，准备输出
                if (!valid_out) begin
                    mat_res <= result;
                    valid_out <= 1'b1;
                end else if (ready_in) begin
                    // 输出被接收，复位状态
                    valid_out <= 1'b0;
                    busy <= 1'b0;
                end
            end
        end
    end
endmodule