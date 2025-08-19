module remap_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    input [AWIDTH-1:0] in_addr,
    input [DWIDTH-1:0] in_data,
    input in_valid, in_write,
    output reg in_ready,
    output reg [AWIDTH-1:0] out_addr,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid, out_write,
    input out_ready
);
    // 重映射表 - 使用参数而非initial块
    parameter [AWIDTH-1:0] REMAP_BASE0 = 32'h1000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE0 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST0 = 32'h2000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE1 = 32'h2000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE1 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST1 = 32'h3000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE2 = 32'h3000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE2 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST2 = 32'h4000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE3 = 32'h4000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE3 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST3 = 32'h5000_0000;
    
    wire [AWIDTH-1:0] remapped_addr;
    
    // 组合式重映射逻辑
    function [AWIDTH-1:0] remap_address;
        input [AWIDTH-1:0] addr;
        begin
            if (addr >= REMAP_BASE0 && addr < (REMAP_BASE0 + REMAP_SIZE0))
                remap_address = REMAP_DEST0 + (addr - REMAP_BASE0);
            else if (addr >= REMAP_BASE1 && addr < (REMAP_BASE1 + REMAP_SIZE1))
                remap_address = REMAP_DEST1 + (addr - REMAP_BASE1);
            else if (addr >= REMAP_BASE2 && addr < (REMAP_BASE2 + REMAP_SIZE2))
                remap_address = REMAP_DEST2 + (addr - REMAP_BASE2);
            else if (addr >= REMAP_BASE3 && addr < (REMAP_BASE3 + REMAP_SIZE3))
                remap_address = REMAP_DEST3 + (addr - REMAP_BASE3);
            else
                remap_address = addr; // 默认：不重映射
        end
    endfunction
    
    assign remapped_addr = remap_address(in_addr);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 0;
            in_ready <= 1;
            out_addr <= 0;
            out_data <= 0;
            out_write <= 0;
        end else if (in_valid && in_ready) begin
            out_data <= in_data;
            out_write <= in_write;
            out_valid <= 1;
            in_ready <= 0;
            out_addr <= remapped_addr;
        end else if (out_valid && out_ready) begin
            out_valid <= 0;
            in_ready <= 1;
        end
    end
endmodule