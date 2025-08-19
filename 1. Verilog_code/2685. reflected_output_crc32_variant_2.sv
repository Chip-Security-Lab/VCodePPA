//SystemVerilog
module reflected_output_crc32(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire [31:0] crc_out
);
    reg [31:0] crc_reg;
    wire [31:0] reflected_crc;
    wire feedback;
    
    // 使用参数化常量，提高可读性和可维护性
    localparam POLYNOMIAL = 32'h04C11DB7;
    localparam INIT_VALUE = 32'hFFFFFFFF;
    
    // 优化位反转逻辑，使用更紧凑的循环
    generate
        for (genvar i = 0; i < 32; i = i + 1) begin: bit_reflect
            assign reflected_crc[i] = crc_reg[31-i];
        end
    endgenerate
    
    // 提取反馈位计算，减少关键路径
    assign feedback = crc_reg[31] ^ data[0];
    assign crc_out = reflected_crc ^ INIT_VALUE;
    
    // 主要CRC计算逻辑
    always @(posedge clk) begin
        if (rst) 
            crc_reg <= INIT_VALUE;
        else if (valid) 
            crc_reg <= {crc_reg[30:0], 1'b0} ^ (feedback ? POLYNOMIAL : 32'h0);
    end
endmodule