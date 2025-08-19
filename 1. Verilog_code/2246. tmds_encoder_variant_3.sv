//SystemVerilog
// Top-level module with AXI-Stream interface
module tmds_encoder(
    // Clock and reset
    input wire aclk,
    input wire aresetn,
    
    // Input AXI-Stream interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,  // Can be used for hsync/vsync signaling
    input wire [1:0] s_axis_tuser, // [0]=hsync, [1]=vsync
    
    // Output AXI-Stream interface
    output wire [9:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast
);
    // Internal signals
    wire [3:0] ones_count;
    wire invert_bit;
    wire [9:0] active_encoded;
    wire [9:0] control_encoded;
    wire [9:0] idle_encoded;
    reg [1:0] mode_select;
    
    // Handshaking signals
    reg internal_ready;
    reg internal_valid;
    wire active;
    wire hsync, vsync;
    
    // Extract control signals from AXI-Stream signals
    assign hsync = s_axis_tuser[0];
    assign vsync = s_axis_tuser[1];
    assign active = s_axis_tvalid & ~s_axis_tlast;
    
    // Input handshaking
    assign s_axis_tready = internal_ready & (m_axis_tready | ~internal_valid);
    
    // Output handshaking
    assign m_axis_tvalid = internal_valid;
    assign m_axis_tlast = s_axis_tlast & s_axis_tvalid & s_axis_tready;
    
    // Always ready to accept data when downstream is ready
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn)
            internal_ready <= 1'b0;
        else
            internal_ready <= m_axis_tready | ~internal_valid;
    end
    
    // Valid signal generation
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn)
            internal_valid <= 1'b0;
        else if (s_axis_tvalid & s_axis_tready)
            internal_valid <= 1'b1;
        else if (m_axis_tready)
            internal_valid <= 1'b0;
    end
    
    // Calculate number of ones in the pixel data
    bit_counter bit_counter_inst(
        .data(s_axis_tdata),
        .ones_count(ones_count)
    );
    
    // Determine if inversion should be applied
    inversion_controller inversion_ctrl_inst(
        .ones_count(ones_count),
        .lsb(s_axis_tdata[0]),
        .invert_bit(invert_bit)
    );
    
    // Generate encoding for active video data
    active_encoder active_enc_inst(
        .pixel_data(s_axis_tdata),
        .invert_bit(invert_bit),
        .encoded(active_encoded)
    );
    
    // Generate encoding for control periods
    control_encoder control_enc_inst(
        .hsync(hsync),
        .vsync(vsync),
        .encoded(control_encoded)
    );
    
    // Generate idle encoding
    idle_encoder idle_enc_inst(
        .encoded(idle_encoded)
    );
    
    // Mode selection logic with simplified conditions
    always @(*) begin
        if (active)
            mode_select = 2'b01;
        else
            mode_select = 2'b00;
    end
    
    // Output multiplexer with improved structure
    output_mux output_mux_inst(
        .active_encoded(active_encoded),
        .control_encoded(control_encoded),
        .idle_encoded(idle_encoded),
        .mode_select(mode_select),
        .encoded(m_axis_tdata)
    );
    
endmodule

// Module to count number of 1s in the pixel data
module bit_counter(
    input [7:0] data,
    output reg [3:0] ones_count
);
    integer i;
    
    always @(*) begin
        ones_count = 4'd0;
        for (i = 0; i < 8; i = i + 1) begin
            if (data[i])
                ones_count = ones_count + 4'd1;
        end
    end
endmodule

// Module to determine if inversion should be applied
module inversion_controller(
    input [3:0] ones_count,
    input lsb,
    output reg invert_bit
);
    always @(*) begin
        if (ones_count > 4'd4) begin
            invert_bit = 1'b1;
        end
        else if (ones_count == 4'd4) begin
            invert_bit = ~lsb;
        end
        else begin
            invert_bit = 1'b0;
        end
    end
endmodule

// Module to encode active video data
module active_encoder(
    input [7:0] pixel_data,
    input invert_bit,
    output reg [9:0] encoded
);
    reg [7:0] transformed_data;
    reg [7:0] xor_pattern;
    reg control_bit;
    
    always @(*) begin
        // Determine XOR pattern based on MSB
        if (pixel_data[7])
            xor_pattern = 8'hFF;
        else
            xor_pattern = 8'h00;
            
        // Apply transformation to bits 0-6
        transformed_data[6:0] = pixel_data[6:0] ^ xor_pattern[6:0];
        
        // Determine control bit
        control_bit = ~pixel_data[7];
        
        // Assemble final encoded value
        encoded = {invert_bit, control_bit, transformed_data};
    end
endmodule

// Module to encode control signals
module control_encoder(
    input hsync,
    input vsync,
    output reg [9:0] encoded
);
    always @(*) begin
        encoded[9:8] = 2'b01;
        encoded[7] = hsync;
        encoded[6] = vsync;
        encoded[5:0] = 6'b000000;
    end
endmodule

// Module to provide idle encoding
module idle_encoder(
    output reg [9:0] encoded
);
    always @(*) begin
        encoded = 10'b1101010100;
    end
endmodule

// Output multiplexer to select final encoding
module output_mux(
    input [9:0] active_encoded,
    input [9:0] control_encoded,
    input [9:0] idle_encoded,
    input [1:0] mode_select,
    output reg [9:0] encoded
);
    always @(*) begin
        if (mode_select == 2'b01) begin
            encoded = active_encoded;
        end
        else if (mode_select == 2'b00) begin
            encoded = control_encoded;
        end
        else begin
            encoded = idle_encoded;
        end
    end
endmodule