//SystemVerilog
//=============================================================================
// USB PID Decoder - Hierarchical Implementation with Shift-Add Multiplier
//=============================================================================

//-----------------------------------------------------------------------------
// Top-level module that instances all sub-modules
//-----------------------------------------------------------------------------
module usb_pid_decoder(
    input  wire [3:0] pid,
    output wire token_type,
    output wire data_type,
    output wire handshake_type,
    output wire special_type,
    output wire [1:0] pid_type
);
    // Extract PID type directly from the PID field
    assign pid_type = pid[1:0];
    
    // Instantiate sub-modules for each type detection
    pid_token_detector u_token_detector (
        .pid(pid),
        .token_detected(token_type)
    );
    
    pid_data_detector u_data_detector (
        .pid(pid),
        .data_detected(data_type)
    );
    
    pid_handshake_detector u_handshake_detector (
        .pid(pid),
        .handshake_detected(handshake_type)
    );
    
    pid_special_detector u_special_detector (
        .pid(pid),
        .special_detected(special_type)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Sub-module for token packet detection
//-----------------------------------------------------------------------------
module pid_token_detector(
    input  wire [3:0] pid,
    output wire token_detected
);
    // Constants for multiplier-based detection
    wire [3:0] token_mask = 4'b0001;
    wire [7:0] product;
    
    // Instantiate shift-add multiplier
    shift_add_multiplier u_mult (
        .a(pid),
        .b(token_mask),
        .p(product)
    );
    
    // Token detected when product matches expected values
    assign token_detected = (product == 8'h01) || // OUT
                            (product == 8'h09) || // IN
                            (product == 8'h05) || // SOF
                            (product == 8'h0D);   // SETUP
endmodule

//-----------------------------------------------------------------------------
// Sub-module for data packet detection
//-----------------------------------------------------------------------------
module pid_data_detector(
    input  wire [3:0] pid,
    output wire data_detected
);
    // Constants for multiplier-based detection
    wire [3:0] data_mask = 4'b0011;
    wire [7:0] product;
    
    // Instantiate shift-add multiplier
    shift_add_multiplier u_mult (
        .a(pid),
        .b(data_mask),
        .p(product)
    );
    
    // Data detected when product matches expected values
    assign data_detected = (product == 8'h09) || // DATA0
                           (product == 8'h21);   // DATA1
endmodule

//-----------------------------------------------------------------------------
// Sub-module for handshake packet detection
//-----------------------------------------------------------------------------
module pid_handshake_detector(
    input  wire [3:0] pid,
    output wire handshake_detected
);
    // Constants for multiplier-based detection
    wire [3:0] handshake_mask = 4'b0010;
    wire [7:0] product;
    
    // Instantiate shift-add multiplier
    shift_add_multiplier u_mult (
        .a(pid),
        .b(handshake_mask),
        .p(product)
    );
    
    // Handshake detected when product matches expected values
    assign handshake_detected = (product == 8'h04) || // ACK
                                (product == 8'h14);   // NAK
endmodule

//-----------------------------------------------------------------------------
// Sub-module for special packet detection
//-----------------------------------------------------------------------------
module pid_special_detector(
    input  wire [3:0] pid,
    output wire special_detected
);
    // Constants for multiplier-based detection
    wire [3:0] special_mask = 4'b0110;
    wire [7:0] product;
    
    // Instantiate shift-add multiplier
    shift_add_multiplier u_mult (
        .a(pid),
        .b(special_mask),
        .p(product)
    );
    
    // Special detected when product matches expected value
    assign special_detected = (product == 8'h24); // SPLIT
endmodule

//-----------------------------------------------------------------------------
// 4-bit Shift-Add Multiplier module
//-----------------------------------------------------------------------------
module shift_add_multiplier(
    input  wire [3:0] a,  // Multiplicand
    input  wire [3:0] b,  // Multiplier
    output wire [7:0] p   // Product
);
    reg [7:0] product;
    reg [7:0] shifted_a;
    integer i;
    
    always @(*) begin
        product = 8'b0;
        shifted_a = {4'b0, a};
        
        for (i = 0; i < 4; i = i + 1) begin
            if (b[i]) begin
                product = product + shifted_a;
            end
            shifted_a = shifted_a << 1;
        end
    end
    
    assign p = product;
endmodule