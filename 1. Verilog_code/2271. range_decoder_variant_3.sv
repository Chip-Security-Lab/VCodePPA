//SystemVerilog
module range_decoder(
    input [7:0] addr,
    output reg rom_sel,
    output reg ram_sel,
    output reg io_sel,
    output reg error
);
    // 定义地址范围标识
    reg [1:0] addr_range;
    
    // 确定地址范围
    always @(*) begin
        casez (addr)
            8'b0???????: addr_range = 2'b00; // 地址 < 8'h40
            8'b10??????: addr_range = 2'b01; // 地址 < 8'hC0
            8'b110?????: addr_range = 2'b01; // 地址 < 8'hC0
            8'b1110????: addr_range = 2'b10; // 地址 < 8'hFF
            8'b11110???: addr_range = 2'b10; // 地址 < 8'hFF
            8'b111110??: addr_range = 2'b10; // 地址 < 8'hFF
            8'b1111110?: addr_range = 2'b10; // 地址 < 8'hFF
            8'b11111110: addr_range = 2'b10; // 地址 < 8'hFF
            8'b11111111: addr_range = 2'b11; // 地址 = 8'hFF
            default:     addr_range = 2'b11; // 默认错误条件
        endcase
    end
    
    // 根据地址范围设置输出
    always @(*) begin
        // 默认值，避免锁存器
        rom_sel = 1'b0;
        ram_sel = 1'b0;
        io_sel = 1'b0;
        error = 1'b0;
        
        case (addr_range)
            2'b00: rom_sel = 1'b1; // 地址 < 8'h40
            2'b01: ram_sel = 1'b1; // 地址 < 8'hC0
            2'b10: io_sel = 1'b1;  // 地址 < 8'hFF
            2'b11: error = 1'b1;   // 地址 = 8'hFF
        endcase
    end
endmodule