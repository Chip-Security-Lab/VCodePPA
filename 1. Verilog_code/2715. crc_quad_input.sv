module crc_quad_input (
    input clk, [3:0] valid,
    input [31:0] data [0:3],
    output [31:0] crc [0:3]
);
    // 拆分为多个always块
    reg [31:0] crc_reg [0:3];
    
    // 分别处理每个通道
    always @(posedge clk) begin
        if (valid[0]) crc_reg[0] <= crc_reg[0] ^ {data[0], 8'h00};
    end
    
    always @(posedge clk) begin
        if (valid[1]) crc_reg[1] <= crc_reg[1] ^ {data[1], 8'h00};
    end
    
    always @(posedge clk) begin
        if (valid[2]) crc_reg[2] <= crc_reg[2] ^ {data[2], 8'h00};
    end
    
    always @(posedge clk) begin
        if (valid[3]) crc_reg[3] <= crc_reg[3] ^ {data[3], 8'h00};
    end
    
    assign crc = crc_reg;
endmodule