module rgb888_to_rgb444_codec (
    input clk, rst,
    input [23:0] rgb888_in,
    input dither_en,
    input [3:0] dither_seed,
    output reg [11:0] rgb444_out
);
    reg [3:0] lfsr;
    wire dither_bit;
    
    // Simple LFSR for dithering
    always @(posedge clk) begin
        if (rst)
            lfsr <= dither_seed;
        else if (dither_en)
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
    end
    
    assign dither_bit = lfsr[0];
    
    always @(posedge clk) begin
        if (rst)
            rgb444_out <= 12'h000;
        else begin
            // Extract most significant 4 bits from each color component
            // Add dither if enabled (1 LSB adjustment)
            rgb444_out[11:8] <= rgb888_in[23:20] + (dither_en & dither_bit & (rgb888_in[19:16] > 4'h8));
            rgb444_out[7:4] <= rgb888_in[15:12] + (dither_en & dither_bit & (rgb888_in[11:8] > 4'h8));
            rgb444_out[3:0] <= rgb888_in[7:4] + (dither_en & dither_bit & (rgb888_in[3:0] > 4'h8));
        end
    end
endmodule