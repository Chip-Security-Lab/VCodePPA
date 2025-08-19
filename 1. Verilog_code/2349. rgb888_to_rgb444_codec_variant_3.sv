//SystemVerilog
///////////////////////////////////////////////////////////////////////////
// File: rgb888_to_rgb444_codec.v
// Module: rgb888_to_rgb444_codec
// Description: Top-level module for RGB888 to RGB444 conversion with dithering
///////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module rgb888_to_rgb444_codec (
    input wire clk,
    input wire rst,
    input wire [23:0] rgb888_in,
    input wire dither_en,
    input wire [3:0] dither_seed,
    output wire [11:0] rgb444_out
);

    // Internal signals
    wire dither_bit;
    
    // Instantiate LFSR-based dithering generator
    dithering_generator u_dithering_generator (
        .clk(clk),
        .rst(rst),
        .dither_en(dither_en),
        .dither_seed(dither_seed),
        .dither_bit(dither_bit)
    );
    
    // Instantiate RGB format converter
    rgb_format_converter u_rgb_format_converter (
        .clk(clk),
        .rst(rst),
        .rgb888_in(rgb888_in),
        .dither_en(dither_en),
        .dither_bit(dither_bit),
        .rgb444_out(rgb444_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: dithering_generator
// Description: Generates dithering bit using LFSR
///////////////////////////////////////////////////////////////////////////
module dithering_generator (
    input wire clk,
    input wire rst,
    input wire dither_en,
    input wire [3:0] dither_seed,
    output wire dither_bit
);

    reg [3:0] lfsr;
    
    // Simple LFSR for dithering
    always @(posedge clk) begin
        if (rst)
            lfsr <= dither_seed;
        else if (dither_en)
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
    end
    
    assign dither_bit = lfsr[0];

endmodule

///////////////////////////////////////////////////////////////////////////
// Module: rgb_format_converter
// Description: Converts RGB888 to RGB444 format with optional dithering
///////////////////////////////////////////////////////////////////////////
module rgb_format_converter (
    input wire clk,
    input wire rst,
    input wire [23:0] rgb888_in,
    input wire dither_en,
    input wire dither_bit,
    output wire [11:0] rgb444_out
);

    // RGB components extraction
    wire [7:0] red_in = rgb888_in[23:16];
    wire [7:0] green_in = rgb888_in[15:8];
    wire [7:0] blue_in = rgb888_in[7:0];
    
    // Dithering condition checks
    wire red_dither_cond = dither_en & dither_bit & (red_in[3:0] > 4'h8);
    wire green_dither_cond = dither_en & dither_bit & (green_in[3:0] > 4'h8);
    wire blue_dither_cond = dither_en & dither_bit & (blue_in[3:0] > 4'h8);
    
    // Register at input stage (moved from output)
    reg [7:0] red_in_reg, green_in_reg, blue_in_reg;
    reg red_dither_cond_reg, green_dither_cond_reg, blue_dither_cond_reg;
    reg rst_reg;
    
    // First pipeline stage - register inputs and dither conditions
    always @(posedge clk) begin
        red_in_reg <= red_in;
        green_in_reg <= green_in;
        blue_in_reg <= blue_in;
        red_dither_cond_reg <= red_dither_cond;
        green_dither_cond_reg <= green_dither_cond;
        blue_dither_cond_reg <= blue_dither_cond;
        rst_reg <= rst;
    end
    
    // Calculate RGB444 with registered inputs
    wire [3:0] red_out = rst_reg ? 4'h0 : (red_in_reg[7:4] + {3'b000, red_dither_cond_reg});
    wire [3:0] green_out = rst_reg ? 4'h0 : (green_in_reg[7:4] + {3'b000, green_dither_cond_reg});
    wire [3:0] blue_out = rst_reg ? 4'h0 : (blue_in_reg[7:4] + {3'b000, blue_dither_cond_reg});
    
    // Assemble output
    assign rgb444_out = {red_out, green_out, blue_out};

endmodule