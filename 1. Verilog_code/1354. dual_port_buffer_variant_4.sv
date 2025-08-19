//SystemVerilog
module dual_port_buffer (
    input wire clk,
    input wire [31:0] write_data,
    input wire write_en,
    input wire read_en,
    output reg [31:0] read_data
);
    reg [31:0] buffer;
    wire read_en_d;
    
    // 将read_en信号寄存器移到组合逻辑之后
    // 直接推至数据通路中
    reg read_en_internal;
    
    always @(posedge clk) begin
        // 将read_en的寄存移到这里
        read_en_internal <= read_en;
        
        // 数据写入逻辑保持不变
        if (write_en)
            buffer <= write_data;
            
        // 读取逻辑直接使用内部寄存的使能信号
        if (read_en_internal)
            read_data <= buffer;
    end
    
    // 为了保持接口一致性，将内部信号映射到原始输出
    assign read_en_d = read_en_internal;
endmodule