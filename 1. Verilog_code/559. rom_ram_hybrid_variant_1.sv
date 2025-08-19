//SystemVerilog
module rom_ram_hybrid #(parameter MODE=0)(
    input clk,
    input [7:0] addr,
    input [15:0] din,
    input rst,          // 复位信号
    output reg [15:0] dout
);
    reg [15:0] mem [0:255];
    
    // 用于缓冲高扇出信号的寄存器
    reg [7:0] addr_reg;
    reg [4:0] block_addr;
    reg [2:0] sub_addr;
    
    // 分块缓冲，将memory分为8个块
    reg [15:0] mem_buf0 [0:31];
    reg [15:0] mem_buf1 [0:31];
    reg [15:0] mem_buf2 [0:31];
    reg [15:0] mem_buf3 [0:31];
    reg [15:0] mem_buf4 [0:31];
    reg [15:0] mem_buf5 [0:31];
    reg [15:0] mem_buf6 [0:31];
    reg [15:0] mem_buf7 [0:31];
    
    // 初始化为0
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 16'h0000;
        dout = 16'h0000;
        addr_reg = 8'h00;
        block_addr = 5'h00;
        sub_addr = 3'h0;
    end
    
    // 寄存输入地址，减少扇出
    always @(posedge clk) begin
        addr_reg <= addr;
        block_addr <= addr[4:0];
        sub_addr <= addr[7:5];
    end
    
    // 读取逻辑优化 - 使用寄存器读取并缓存输出
    always @(posedge clk) begin
        case(sub_addr)
            3'b000: dout <= mem_buf0[block_addr];
            3'b001: dout <= mem_buf1[block_addr];
            3'b010: dout <= mem_buf2[block_addr];
            3'b011: dout <= mem_buf3[block_addr];
            3'b100: dout <= mem_buf4[block_addr];
            3'b101: dout <= mem_buf5[block_addr];
            3'b110: dout <= mem_buf6[block_addr];
            3'b111: dout <= mem_buf7[block_addr];
        endcase
    end
    
    // 同步mem和mem_buf，减少mem的直接扇出
    always @(posedge clk) begin
        mem_buf0[block_addr] <= mem[{3'b000, block_addr}];
        mem_buf1[block_addr] <= mem[{3'b001, block_addr}];
        mem_buf2[block_addr] <= mem[{3'b010, block_addr}];
        mem_buf3[block_addr] <= mem[{3'b011, block_addr}];
        mem_buf4[block_addr] <= mem[{3'b100, block_addr}];
        mem_buf5[block_addr] <= mem[{3'b101, block_addr}];
        mem_buf6[block_addr] <= mem[{3'b110, block_addr}];
        mem_buf7[block_addr] <= mem[{3'b111, block_addr}];
    end
    
    // 写入逻辑（带缓冲）
    generate
        if(MODE == 1) begin
            // 分段复位计数器减少i信号的扇出
            reg [2:0] rst_block;
            reg [4:0] rst_addr;
            reg rst_active;
            
            always @(posedge clk) begin
                if (rst && !rst_active) begin
                    rst_active <= 1'b1;
                    rst_block <= 3'b000;
                    rst_addr <= 5'b00000;
                end else if (rst_active) begin
                    // 分阶段复位
                    if (rst_addr == 5'b11111) begin
                        if (rst_block == 3'b111) begin
                            rst_active <= 1'b0;
                        end else begin
                            rst_block <= rst_block + 1'b1;
                            rst_addr <= 5'b00000;
                        end
                    end else begin
                        rst_addr <= rst_addr + 1'b1;
                    end
                    
                    // 为当前复位地址分配清零值
                    mem[{rst_block, rst_addr}] <= 16'h0000;
                end else if (!rst) begin
                    // 普通写入操作
                    mem[addr_reg] <= din;
                end
            end
        end
    endgenerate
endmodule