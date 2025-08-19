//SystemVerilog
module gray_counter_div (
    input wire clk,
    input wire rst,
    input wire req,          // 请求信号 - 替代了原来隐含的valid
    output wire ack,         // 应答信号 - 替代了原来隐含的ready
    output wire divided_clk
);
    reg [3:0] gray_count;
    reg ack_reg;
    
    // 格雷码与二进制码转换逻辑
    wire [3:0] bin_count;
    wire [3:0] next_bin;
    wire [3:0] next_gray;
    
    // 格雷码转二进制
    assign bin_count[3] = gray_count[3];
    assign bin_count[2] = bin_count[3] ^ gray_count[2];
    assign bin_count[1] = bin_count[2] ^ gray_count[1];
    assign bin_count[0] = bin_count[1] ^ gray_count[0];
    
    // 二进制递增
    assign next_bin = bin_count + 4'b0001;
    
    // 二进制转格雷码
    assign next_gray = {next_bin[3], next_bin[3:1] ^ next_bin[2:0]};
    
    // 请求-应答握手逻辑
    always @(posedge clk) begin
        if (rst) begin
            gray_count <= 4'b0000;
            ack_reg <= 1'b0;
        end
        else begin
            if (req && !ack_reg) begin
                // 当收到请求且尚未响应时，更新计数并发送应答
                gray_count <= next_gray;
                ack_reg <= 1'b1;
            end
            else if (!req) begin
                // 当请求撤销时，清除应答信号
                ack_reg <= 1'b0;
            end
        end
    end
    
    // 输出应答信号
    assign ack = ack_reg;
    
    // 使用格雷码的最高位作为分频时钟
    assign divided_clk = gray_count[3];
endmodule