//SystemVerilog
module mem_mapped_decoder(
    input [7:0] addr,
    input [1:0] bank_sel,
    output reg [3:0] chip_sel
);
    // 使用最高位检测简化比较逻辑
    wire addr_in_range;
    
    // 检查地址是否在0x00-0x7F范围内，只需检查最高位
    assign addr_in_range = ~addr[7];
    
    always @(*) begin
        chip_sel = 4'b0000;
        
        // 只有当地址在有效范围内时才进行bank_sel解码
        if (addr_in_range) begin
            if (bank_sel == 2'b00) begin
                chip_sel = 4'b0001;
            end
            else if (bank_sel == 2'b01) begin
                chip_sel = 4'b0010;
            end
            else if (bank_sel == 2'b10) begin
                chip_sel = 4'b0100;
            end
            else if (bank_sel == 2'b11) begin
                chip_sel = 4'b1000;
            end
        end
    end
endmodule