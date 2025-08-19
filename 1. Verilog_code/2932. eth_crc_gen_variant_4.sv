//SystemVerilog
module eth_crc_gen (
    input wire [7:0] data_in,
    input wire crc_en,
    input wire crc_init,
    input wire clk,
    output wire [31:0] crc_out
);
    reg [31:0] crc_reg;
    wire [31:0] next_crc;
    reg [31:0] out_bit_swap;
    
    // Generate next CRC value based on input
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: crc_gen_loop
            assign next_crc[i] = crc_reg[24+i] ^ data_in[i] ^ crc_reg[31];
        end
    endgenerate
    
    assign next_crc[31:8] = crc_reg[23:0];
    
    // CRC calculation register
    always @(posedge clk) begin
        case ({crc_init, crc_en})
            2'b10, 2'b11: crc_reg <= 32'hFFFFFFFF; // crc_init has priority
            2'b01:        crc_reg <= next_crc;     // only update when crc_en=1, crc_init=0
            2'b00:        crc_reg <= crc_reg;      // hold value
        endcase
    end
    
    // Output bit-swapping register (moved from combinational to sequential)
    always @(posedge clk) begin
        out_bit_swap <= ~{crc_reg[24], crc_reg[25], crc_reg[26], crc_reg[27],
                         crc_reg[28], crc_reg[29], crc_reg[30], crc_reg[31],
                         crc_reg[16], crc_reg[17], crc_reg[18], crc_reg[19],
                         crc_reg[20], crc_reg[21], crc_reg[22], crc_reg[23],
                         crc_reg[8], crc_reg[9], crc_reg[10], crc_reg[11],
                         crc_reg[12], crc_reg[13], crc_reg[14], crc_reg[15],
                         crc_reg[0], crc_reg[1], crc_reg[2], crc_reg[3],
                         crc_reg[4], crc_reg[5], crc_reg[6], crc_reg[7]};
    end
    
    // Output assignment
    assign crc_out = out_bit_swap;
endmodule