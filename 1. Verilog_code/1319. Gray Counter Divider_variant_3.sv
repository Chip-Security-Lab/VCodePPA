//SystemVerilog
module gray_counter_div (
    input wire clk, rst,
    output wire divided_clk
);
    reg [3:0] binary_count;
    wire [3:0] gray_count;
    
    // 直接从二进制计数器推导格雷码
    assign gray_count = {binary_count[3], 
                         binary_count[3:1] ^ binary_count[2:0]};
    
    // 使用非阻塞赋值更新二进制计数器
    always @(posedge clk or posedge rst) begin
        if (rst)
            binary_count <= 4'b0000;
        else
            binary_count <= binary_count + 1'b1;
    end
    
    // 直接使用最高位作为分频时钟输出
    assign divided_clk = gray_count[3];
endmodule