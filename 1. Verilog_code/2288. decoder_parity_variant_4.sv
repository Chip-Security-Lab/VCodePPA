//SystemVerilog
module decoder_parity (
    input wire [4:0] addr_in,  // addr_in[4]为奇偶校验位
    output reg valid,
    output reg [7:0] decoded
);
    // 直接计算奇偶校验结果
    wire parity_match;
    assign parity_match = ~(addr_in[4] ^ addr_in[3] ^ addr_in[2] ^ addr_in[1] ^ addr_in[0]);
    
    // 简化的校验和解码逻辑
    always @(*) begin
        valid = parity_match;
        decoded = {8{parity_match}} & (8'h01 << addr_in[3:0]);
    end
    
endmodule