module crc8_generator #(
    parameter POLY = 8'h07  // CRC-8多项式 x^8 + x^2 + x + 1
)(
    input clk, rst, enable,
    input data_in,
    output [7:0] crc_out,
    input init  // 初始化信号
);
    reg [7:0] crc_reg;
    wire feedback = crc_reg[7] ^ data_in;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_reg <= 8'h00;
        else if (init)
            crc_reg <= 8'h00;
        else if (enable) begin
            crc_reg <= {crc_reg[6:0], 1'b0};
            if (feedback)
                crc_reg <= {crc_reg[6:0], 1'b0} ^ POLY;
        end
    end
    
    assign crc_out = crc_reg;
endmodule