module reflected_output_crc32(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire [31:0] crc_out
);
    reg [31:0] crc_reg;
    wire [31:0] reflected_crc;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: bit_reflect
            assign reflected_crc[i] = crc_reg[31-i];
        end
    endgenerate
    assign crc_out = reflected_crc ^ 32'hFFFFFFFF;
    always @(posedge clk) begin
        if (rst) crc_reg <= 32'hFFFFFFFF;
        else if (valid) crc_reg <= {crc_reg[30:0], 1'b0} ^ 
                                 ((crc_reg[31] ^ data[0]) ? 32'h04C11DB7 : 32'h0);
    end
endmodule