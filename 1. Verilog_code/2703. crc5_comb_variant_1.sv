//SystemVerilog
module crc5_comb (
    input wire [4:0] data_in,
    output reg [4:0] crc_out
);
    // 数据路径寄存器
    reg [4:0] shifted_data_reg;
    reg [4:0] xor_result_reg;
    
    // 常量定义
    localparam [4:0] POLY = 5'h15;
    
    // 数据移位级
    always @(*) begin
        shifted_data_reg = {data_in[3:0], 1'b0};
    end
    
    // 条件异或级
    always @(*) begin
        if (data_in[4])
            xor_result_reg = shifted_data_reg ^ POLY;
        else
            xor_result_reg = shifted_data_reg;
    end
    
    // 输出级
    always @(*) begin
        crc_out = xor_result_reg;
    end
endmodule