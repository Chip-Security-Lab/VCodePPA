//SystemVerilog
module sine_lut(
    input clk,
    input rst_n,
    input [3:0] addr_step,
    output reg [7:0] sine_out
);
    // 使用较窄的地址变量，仅使用需要的位宽
    reg [7:0] addr;
    
    // 使用ROM风格的实现以便于综合工具推断块RAM
    (* ram_style = "block" *) reg [7:0] sine_table [0:15];
    
    // 使用参数化初始化ROM
    initial begin
        sine_table[0] = 8'd128;
        sine_table[1] = 8'd176;
        sine_table[2] = 8'd218;
        sine_table[3] = 8'd245;
        sine_table[4] = 8'd255;
        sine_table[5] = 8'd245;
        sine_table[6] = 8'd218;
        sine_table[7] = 8'd176;
        sine_table[8] = 8'd128;
        sine_table[9] = 8'd79;
        sine_table[10] = 8'd37;
        sine_table[11] = 8'd10;
        sine_table[12] = 8'd0;
        sine_table[13] = 8'd10;
        sine_table[14] = 8'd37;
        sine_table[15] = 8'd79;
    end
    
    // 优化地址更新逻辑，使用单独的时钟域以提高性能
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr <= 8'd0;
        else
            addr <= addr + {4'b0000, addr_step};
    end
    
    // 添加寄存器操作以改善时序
    reg [3:0] addr_index;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            addr_index <= 4'd0;
        else
            addr_index <= addr[7:4];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sine_out <= 8'd128; // 重置为中点值
        else
            sine_out <= sine_table[addr_index];
    end
endmodule