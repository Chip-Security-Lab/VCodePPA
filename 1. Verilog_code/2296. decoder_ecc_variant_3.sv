//SystemVerilog
//IEEE 1364-2005 Verilog
module decoder_ecc #(parameter DATA_W=4) (
    input [DATA_W+2:0] encoded_addr, // [7:4]=data, [3:1]=parity, [0]=overall_parity
    output reg [2**DATA_W-1:0] decoded,
    output reg error
);
    // 提取数据位和奇偶校验位
    wire [DATA_W-1:0] data = encoded_addr[DATA_W+2:3];
    wire [2:0] parity_bits = encoded_addr[2:0];
    
    // 使用带状进位加法器计算奇偶校验
    wire [2:0] p;
    wire [2:0] g;
    wire [2:0] c;
    
    // 生成和传播信号
    assign p[0] = data[0] | data[1];
    assign p[1] = data[2] | data[3];
    assign p[2] = 1'b0;
    
    assign g[0] = data[0] & data[1];
    assign g[1] = data[2] & data[3];
    assign g[2] = 1'b0;
    
    // 带状进位加法器逻辑
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    
    // 最终的奇偶校验结果
    wire calc_parity = c[1] ^ (data[0] ^ data[1] ^ data[2] ^ data[3]);
    
    // 优化的错误检测逻辑
    wire parity_error = calc_parity ^ parity_bits[0];
    
    // 解码逻辑
    always @(*) begin
        error = parity_error;
        decoded = parity_error ? {(2**DATA_W){1'b0}} : (1'b1 << data);
    end
endmodule