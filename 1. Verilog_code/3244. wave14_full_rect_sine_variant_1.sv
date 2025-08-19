//SystemVerilog
module wave14_full_rect_sine #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [DATA_WIDTH-1:0] wave_out
);
    reg [ADDR_WIDTH-1:0] addr;
    reg [ADDR_WIDTH-1:0] addr_buf1, addr_buf2;
    wire signed [DATA_WIDTH-1:0] rom_value;
    reg signed [DATA_WIDTH-1:0] rom_value_buf1, rom_value_buf2;
    
    // 使用函数替代ROM初始化
    function signed [DATA_WIDTH-1:0] get_rom_value;
        input [ADDR_WIDTH-1:0] addr;
        begin
            get_rom_value = addr - (1<<(DATA_WIDTH-1));
        end
    endfunction
    
    // 地址生成逻辑
    always @(posedge clk) begin
        if(rst) addr <= 0;
        else    addr <= addr + 1;
    end
    
    // 地址缓冲寄存器 - 分散负载
    always @(posedge clk) begin
        addr_buf1 <= addr;
        addr_buf2 <= addr;
    end
    
    // 使用缓冲的地址计算ROM值
    assign rom_value = get_rom_value(addr_buf1);
    
    // ROM值缓冲寄存器 - 分散负载
    always @(posedge clk) begin
        rom_value_buf1 <= rom_value;
        rom_value_buf2 <= rom_value;
    end
    
    // 使用缓冲的ROM值计算输出
    always @(posedge clk) begin
        wave_out <= (rom_value_buf2 < 0) ? -rom_value_buf2 : rom_value_buf2;
    end
endmodule