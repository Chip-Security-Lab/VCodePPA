//SystemVerilog
module rom_compressed #(parameter AW=8)(
    input [AW-1:0] addr,
    output reg [31:0] data
);
    // 使用带符号乘法优化实现算法
    reg signed [31:0] signed_addr;
    reg signed [31:0] signed_data_1;
    reg signed [31:0] signed_data_2;

    always @(*) begin
        signed_addr = $signed(addr);
        signed_data_1 = signed_addr * -1; // 取反
        signed_data_2 = signed_addr ^ 8'hFF; // 按位取反
        data = {addr, signed_data_1, signed_data_2, signed_addr | 8'h0F};
    end
endmodule