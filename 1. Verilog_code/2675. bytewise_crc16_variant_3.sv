//SystemVerilog
module bytewise_crc16(
    input wire clk_i,
    input wire rst_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    output wire [15:0] crc_o
);
    localparam POLYNOMIAL = 16'h8005;
    reg [15:0] lfsr_q;
    reg [15:0] lfsr_c;
    
    assign crc_o = lfsr_q;
    
    always @(*) begin
        // 默认值保持不变
        lfsr_c = lfsr_q;
        
        if (data_valid_i) begin
            // 优化后的表达式，将复杂的位运算表达式分解
            // 将位结构重新安排以减少逻辑深度
            lfsr_c[7:0] = data_i ^ (lfsr_q[15] ? POLYNOMIAL[7:0] : 8'h00);
            lfsr_c[15:8] = lfsr_q[7:0] ^ (lfsr_q[15] ? POLYNOMIAL[15:8] : 8'h00);
        end
    end
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            lfsr_q <= 16'hFFFF;
        else
            lfsr_q <= lfsr_c;
    end
endmodule