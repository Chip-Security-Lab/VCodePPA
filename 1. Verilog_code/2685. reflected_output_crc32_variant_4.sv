//SystemVerilog
module reflected_output_crc32(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire [31:0] crc_out
);
    // 内部信号定义
    reg [31:0] crc_reg;
    reg [31:0] next_crc;
    wire [31:0] reflected_crc;
    wire select_bit;
    
    // 位反转生成逻辑
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: bit_reflect
            assign reflected_crc[i] = crc_reg[31-i];
        end
    endgenerate
    
    // 输出逻辑
    assign crc_out = reflected_crc ^ 32'hFFFFFFFF;
    
    // 提取共同条件变量
    assign select_bit = crc_reg[31] ^ data[0];
    
    // CRC下一状态逻辑计算
    always @(*) begin: next_state_logic
        if (rst) begin
            next_crc = 32'hFFFFFFFF;
        end
        else if (valid) begin
            if (select_bit) begin
                next_crc = {crc_reg[30:0], 1'b0} ^ 32'h04C11DB7;
            end
            else begin
                next_crc = {crc_reg[30:0], 1'b0};
            end
        end
        else begin
            next_crc = crc_reg;
        end
    end
    
    // CRC寄存器更新
    always @(posedge clk) begin: crc_register_update
        crc_reg <= next_crc;
    end

endmodule