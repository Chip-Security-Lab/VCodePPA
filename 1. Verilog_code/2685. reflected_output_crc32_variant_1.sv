//SystemVerilog
module reflected_output_crc32(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire valid,
    output wire [31:0] crc_out
);

    reg [31:0] crc_reg;
    reg [31:0] reflected_crc_reg;
    reg [31:0] crc_reg_buf1, crc_reg_buf2;
    
    // Buffer registers for high fan-out crc_reg signal
    always @(posedge clk) begin
        if (rst) begin
            crc_reg_buf1 <= 32'hFFFFFFFF;
            crc_reg_buf2 <= 32'hFFFFFFFF;
        end else begin
            crc_reg_buf1 <= crc_reg;
            crc_reg_buf2 <= crc_reg;
        end
    end
    
    // CRC calculation logic with carry lookahead adder
    wire crc_xor_bit = crc_reg[31] ^ data[0];
    reg crc_xor_bit_buf;
    
    // Carry lookahead adder signals
    wire [31:0] crc_shifted = {crc_reg[30:0], 1'b0};
    wire [31:0] poly_mask = crc_xor_bit ? 32'h04C11DB7 : 32'h0;
    wire [31:0] crc_next;
    
    // Generate and propagate signals
    wire [31:0] g = crc_shifted & poly_mask;
    wire [31:0] p = crc_shifted ^ poly_mask;
    
    // Carry lookahead logic
    wire [31:0] carry;
    assign carry[0] = 1'b0;
    
    genvar j;
    generate
        for (j = 1; j < 32; j = j + 1) begin: carry_gen
            assign carry[j] = g[j-1] | (p[j-1] & carry[j-1]);
        end
    endgenerate
    
    // Final sum calculation
    assign crc_next = p ^ carry;
    
    always @(posedge clk) begin
        crc_xor_bit_buf <= crc_xor_bit;
    end
    
    always @(posedge clk) begin
        if (rst) 
            crc_reg <= 32'hFFFFFFFF;
        else if (valid) 
            crc_reg <= crc_next;
    end

    // Reflection logic moved before output register
    wire [31:0] reflected_crc;
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: bit_reflect_low
            assign reflected_crc[i] = crc_reg_buf1[31-i];
        end
        
        for (i = 16; i < 32; i = i + 1) begin: bit_reflect_high
            assign reflected_crc[i] = crc_reg_buf2[31-i];
        end
    endgenerate

    // Register the reflected CRC
    always @(posedge clk) begin
        if (rst)
            reflected_crc_reg <= 32'h0;
        else
            reflected_crc_reg <= reflected_crc;
    end
    
    // Final output calculation with registered reflection
    assign crc_out = reflected_crc_reg ^ 32'hFFFFFFFF;

endmodule