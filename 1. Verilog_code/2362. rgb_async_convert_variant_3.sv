//SystemVerilog
// Top level module
module rgb_async_convert (
    // AXI-Stream input interface
    input                  aclk,
    input                  aresetn,
    input      [23:0]      s_axis_tdata,
    input                  s_axis_tvalid,
    output                 s_axis_tready,
    input                  s_axis_tlast,
    
    // AXI-Stream output interface
    output     [15:0]      m_axis_tdata,
    output                 m_axis_tvalid,
    input                  m_axis_tready,
    output                 m_axis_tlast
);
    // Internal signals
    wire [4:0] red_565;
    wire [5:0] green_565;
    wire [4:0] blue_565;
    
    // Register to store RGB888 data
    reg [23:0] rgb888_reg;
    reg        last_reg;
    
    // Ready to accept data when output is ready or when not sending valid data
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    
    // Control logic for data flow
    reg data_valid_reg;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rgb888_reg <= 24'h0;
            data_valid_reg <= 1'b0;
            last_reg <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                rgb888_reg <= s_axis_tdata;
                data_valid_reg <= 1'b1;
                last_reg <= s_axis_tlast;
            end else if (m_axis_tready && m_axis_tvalid) begin
                data_valid_reg <= 1'b0;
            end
        end
    end
    
    // Output valid signal
    assign m_axis_tvalid = data_valid_reg;
    assign m_axis_tlast = last_reg;

    // Instantiate color channel extraction modules
    red_channel_converter red_conv (
        .red_888(rgb888_reg[23:16]),
        .red_565(red_565)
    );
    
    green_channel_converter green_conv (
        .green_888(rgb888_reg[15:8]),
        .green_565(green_565)
    );
    
    blue_channel_converter blue_conv (
        .blue_888(rgb888_reg[7:0]),
        .blue_565(blue_565)
    );

    // Instantiate RGB565 packer module
    rgb565_packer packer (
        .red_565(red_565),
        .green_565(green_565),
        .blue_565(blue_565),
        .rgb565(m_axis_tdata)
    );

endmodule

// Red channel conversion module
module red_channel_converter (
    input  [7:0] red_888,
    output [4:0] red_565
);
    // Extract 5 most significant bits from 8-bit red channel
    assign red_565 = red_888[7:3];
endmodule

// Green channel conversion module
module green_channel_converter (
    input  [7:0] green_888,
    output [5:0] green_565
);
    // Extract 6 most significant bits from 8-bit green channel
    assign green_565 = green_888[7:2];
endmodule

// Blue channel conversion module
module blue_channel_converter (
    input  [7:0] blue_888,
    output [4:0] blue_565
);
    // Extract 5 most significant bits from 8-bit blue channel
    assign blue_565 = blue_888[7:3];
endmodule

// RGB565 packing module
module rgb565_packer (
    input  [4:0] red_565,
    input  [5:0] green_565,
    input  [4:0] blue_565,
    output [15:0] rgb565
);
    // Pack the individual color components into a 16-bit RGB565 format
    assign rgb565 = {red_565, green_565, blue_565};
endmodule