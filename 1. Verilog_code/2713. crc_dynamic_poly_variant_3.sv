//SystemVerilog
module crc_dynamic_poly #(parameter WIDTH=16)(
    input clk, load_poly,
    input [WIDTH-1:0] data_in, new_poly,
    output reg [WIDTH-1:0] crc
);
    reg [WIDTH-1:0] poly_reg;
    reg [WIDTH-1:0] next_crc;
    reg [WIDTH-1:0] sub_result;
    
    // 跳跃进位加法器实现
    wire [7:0] p, g; // 传播和生成信号
    wire [7:0] c; // 进位信号
    
    // 计算传播和生成信号
    assign p[7:0] = crc[7:0] ^ data_in[7:0];
    assign g[7:0] = (~crc[7:0]) & data_in[7:0];
    
    // 跳跃进位计算
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & g[0]);
    assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    assign c[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign c[4] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | 
                 (p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[5] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | 
                 (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[6] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | 
                 (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                 (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    assign c[7] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | 
                 (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | 
                 (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                 (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]);
    
    always @(*) begin
        // 8位跳跃进位减法实现
        sub_result[0] = p[0];
        for (integer i = 1; i < 8; i = i + 1) begin
            sub_result[i] = p[i] ^ c[i-1];
        end
        
        // 对于剩余位，保持原有的CRC计算逻辑
        for (integer i = 8; i < WIDTH; i = i + 1) begin
            sub_result[i] = crc[i] ^ data_in[i];
        end
        
        // 确定下一个CRC值
        next_crc = (crc << 1);
        if (crc[WIDTH-1]) begin
            next_crc = next_crc ^ poly_reg;
        end
        next_crc = next_crc ^ sub_result;
    end
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (load_poly) 
            poly_reg <= new_poly;
        else 
            crc <= next_crc;
    end
endmodule