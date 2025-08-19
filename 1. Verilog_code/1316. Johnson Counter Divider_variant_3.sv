//SystemVerilog
module johnson_divider #(parameter WIDTH = 4) (
    input  wire clock_i,  // 输入时钟
    input  wire rst_i,    // 复位信号，高电平有效
    output wire clock_o   // 输出时钟
);
    // 约翰逊计数器寄存器
    reg [WIDTH-1:0] johnson;
    
    // 为高扇出信号添加缓冲寄存器
    reg [WIDTH-1:0] johnson_buf1;
    reg [WIDTH-1:0] johnson_buf2;
    
    // 处理复位和计数逻辑 - 合并到一个always块中以避免冲突
    always @(posedge clock_i) begin
        if (rst_i) begin
            johnson <= {WIDTH{1'b0}};
        end
        else begin
            johnson <= {~johnson[0], johnson[WIDTH-1:1]};
        end
    end
    
    // 添加缓冲寄存器，分散johnson信号的负载
    always @(posedge clock_i) begin
        johnson_buf1 <= johnson;
        johnson_buf2 <= johnson_buf1;
    end
    
    // 输出时钟赋值 - 使用缓冲后的信号
    assign clock_o = johnson_buf1[0];
    
endmodule