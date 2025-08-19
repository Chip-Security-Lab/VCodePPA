module decoder_ecc #(parameter DATA_W=4) (
    input [DATA_W+2:0] encoded_addr, // [7:4]=data, [3:1]=parity, [0]=overall_parity
    output reg [2**DATA_W-1:0] decoded,
    output reg error
);
    wire [DATA_W-1:0] data = encoded_addr[DATA_W+2:3];
    wire calc_parity = ^data; // 简化的奇偶校验
    always @(*) begin
        error = (calc_parity != encoded_addr[0]);
        decoded = error ? 0 : (1'b1 << data);
    end
endmodule