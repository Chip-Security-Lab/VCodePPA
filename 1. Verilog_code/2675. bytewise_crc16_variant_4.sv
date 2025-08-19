//SystemVerilog
module bytewise_crc16(
    input wire clk_i,
    input wire rst_i,
    input wire [7:0] data_i,
    input wire valid_i,
    output wire ready_o,
    output wire [15:0] crc_o
);
    localparam POLYNOMIAL = 16'h8005;
    
    reg [15:0] lfsr_q;
    wire [15:0] next_lfsr;
    wire [15:0] xor_mask;
    reg ready_r;
    
    assign crc_o = lfsr_q;
    assign ready_o = ready_r;
    
    // 预计算所有可能的XOR掩码
    assign xor_mask = {8'h00, data_i} ^ (lfsr_q[15] ? POLYNOMIAL : 16'd0);
    
    // 计算下一个LFSR状态 - 移位并异或
    assign next_lfsr = {lfsr_q[14:0], 1'b0} ^ xor_mask;
    
    // 时序逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            lfsr_q <= 16'hFFFF;
            ready_r <= 1'b1;
        end else if (valid_i && ready_r) begin
            lfsr_q <= next_lfsr;
            ready_r <= 1'b0;
        end else begin
            ready_r <= 1'b1;
        end
    end
endmodule