//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
module rgb888_to_rgb444_codec (
    input wire clk,
    input wire rst,
    
    // AXI-Stream Input Interface
    input wire [23:0] s_axis_tdata,
    input wire s_axis_tvalid,
    input wire s_axis_tlast,
    output wire s_axis_tready,
    
    // AXI-Stream Output Interface
    output wire [11:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire m_axis_tlast,
    input wire m_axis_tready,
    
    // Configuration inputs
    input wire dither_en,
    input wire [3:0] dither_seed
);
    
    // Internal signals
    reg [3:0] lfsr;
    wire dither_bit;
    wire [7:0] r_comp, g_comp, b_comp;
    
    // Registered signals for pipelining
    reg [11:0] rgb444_out_reg;
    reg m_axis_tvalid_reg;
    reg m_axis_tlast_reg;
    reg [2:0] dither_add;
    
    // Handshake logic
    wire valid_handshake = s_axis_tvalid && s_axis_tready;
    wire output_handshake = m_axis_tvalid && m_axis_tready;
    
    // Ready signal generation - more responsive backpressure handling
    assign s_axis_tready = !m_axis_tvalid_reg || m_axis_tready;
    
    // Output connections
    assign m_axis_tdata = rgb444_out_reg;
    assign m_axis_tvalid = m_axis_tvalid_reg;
    assign m_axis_tlast = m_axis_tlast_reg;
    
    // Optimized LFSR for dithering with gated clock optimization
    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= dither_seed;
        else if (dither_en && valid_handshake)
            lfsr <= {lfsr[2:0], lfsr[3] ^ lfsr[2]};
    end
    
    assign dither_bit = lfsr[0];
    
    // Pre-compute color component values for dithering calculation
    assign r_comp = {4'b0, s_axis_tdata[19:16]};
    assign g_comp = {4'b0, s_axis_tdata[11:8]};
    assign b_comp = {4'b0, s_axis_tdata[3:0]};
    
    // Single-cycle data path with optimized dithering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rgb444_out_reg <= 12'h000;
            m_axis_tvalid_reg <= 1'b0;
            m_axis_tlast_reg <= 1'b0;
            dither_add <= 3'b000;
        end else begin
            // Calculate dither addition in the same cycle for better timing
            if (valid_handshake) begin
                dither_add[2] <= dither_en & dither_bit & (r_comp > 8'h08);
                dither_add[1] <= dither_en & dither_bit & (g_comp > 8'h08);
                dither_add[0] <= dither_en & dither_bit & (b_comp > 8'h08);
                
                // RGB conversion with parallel dithering
                rgb444_out_reg[11:8] <= s_axis_tdata[23:20] + (dither_en & dither_bit & (r_comp > 8'h08));
                rgb444_out_reg[7:4] <= s_axis_tdata[15:12] + (dither_en & dither_bit & (g_comp > 8'h08));
                rgb444_out_reg[3:0] <= s_axis_tdata[7:4] + (dither_en & dither_bit & (b_comp > 8'h08));
                
                m_axis_tvalid_reg <= 1'b1;
                m_axis_tlast_reg <= s_axis_tlast;
            end else if (output_handshake) begin
                m_axis_tvalid_reg <= 1'b0;
                m_axis_tlast_reg <= 1'b0;
            end
        end
    end
    
endmodule