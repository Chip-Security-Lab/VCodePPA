//SystemVerilog
module AdaptHuffman (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    reg [31:0] freq [0:255];
    integer i;
    
    // 将寄存器提前至组合逻辑前
    reg [7:0] data_reg;
    reg [31:0] freq_data;
    
    // Internal signals for carry-lookahead adder
    wire [31:0] adder_result;
    
    // Carry-lookahead adder module instantiation
    CarryLookaheadAdder cla (
        .a(freq_data),
        .b(32'h00000001),
        .sum(adder_result)
    );
    
    // Frequency table initialization
    initial begin
        for(i=0; i<256; i=i+1)
            freq[i] = 0;
    end
    
    always @(posedge clk) begin
        if(!rst_n) begin
            for(i=0; i<256; i=i+1)
                freq[i] <= 0;
            data_reg <= 8'b0;
            freq_data <= 32'b0;
            code <= 16'b0;
        end
        else begin
            // 寄存器重定时：先采样输入数据
            data_reg <= data;
            // 读取当前地址的频率计数
            freq_data <= freq[data];
            // 更新频率表
            freq[data_reg] <= adder_result;
            // 更新输出代码
            code <= freq_data[15:0];
        end
    end
endmodule

// 32-bit Carry-Lookahead Adder
module CarryLookaheadAdder (
    input [31:0] a,
    input [31:0] b,
    output [31:0] sum
);
    wire [31:0] p; // Propagate
    wire [31:0] g; // Generate
    wire [32:0] c; // Carry
    
    // Calculate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Carry calculation using lookahead logic
    assign c[0] = 1'b0;
    
    // 4-bit CLA blocks
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin: cla_blocks
            wire [3:0] block_p;
            wire [3:0] block_g;
            wire [4:0] block_c;
            
            assign block_p = p[j*4+3:j*4];
            assign block_g = g[j*4+3:j*4];
            assign block_c[0] = c[j*4];
            
            // Carry lookahead logic for 4-bit block
            assign block_c[1] = block_g[0] | (block_p[0] & block_c[0]);
            assign block_c[2] = block_g[1] | (block_p[1] & block_g[0]) | (block_p[1] & block_p[0] & block_c[0]);
            assign block_c[3] = block_g[2] | (block_p[2] & block_g[1]) | (block_p[2] & block_p[1] & block_g[0]) | (block_p[2] & block_p[1] & block_p[0] & block_c[0]);
            assign block_c[4] = block_g[3] | (block_p[3] & block_g[2]) | (block_p[3] & block_p[2] & block_g[1]) | (block_p[3] & block_p[2] & block_p[1] & block_g[0]) | (block_p[3] & block_p[2] & block_p[1] & block_p[0] & block_c[0]);
            
            // Connect block carries to global carry chain
            assign c[j*4+1:j*4+1] = block_c[1:1];
            assign c[j*4+2:j*4+2] = block_c[2:2];
            assign c[j*4+3:j*4+3] = block_c[3:3];
            assign c[j*4+4:j*4+4] = block_c[4:4];
        end
    endgenerate
    
    // Final sum calculation
    assign sum = p ^ c[31:0];
endmodule