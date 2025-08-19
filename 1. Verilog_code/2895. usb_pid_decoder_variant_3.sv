//SystemVerilog
/*
 * USB PID Decoder - Top Module
 * IEEE 1364-2005 Verilog standard
 * Hierarchical design with dedicated sub-modules for each PID type
 */
module usb_pid_decoder (
    input  wire [3:0] pid,
    output wire token_type,
    output wire data_type,
    output wire handshake_type, 
    output wire special_type,
    output wire [1:0] pid_type
);
    // Internal signals
    wire [3:0] pid_to_decoders;
    
    // Assign PID to internal signals for distribution to sub-modules
    assign pid_to_decoders = pid;
    
    // Extract and assign PID type directly
    assign pid_type = pid[1:0];
    
    // Instantiate specialized decoders for each PID type
    usb_token_decoder u_token_decoder (
        .pid(pid_to_decoders),
        .token_detected(token_type)
    );
    
    usb_data_decoder u_data_decoder (
        .pid(pid_to_decoders),
        .data_detected(data_type)
    );
    
    usb_handshake_decoder u_handshake_decoder (
        .pid(pid_to_decoders),
        .handshake_detected(handshake_type)
    );
    
    usb_special_decoder u_special_decoder (
        .pid(pid_to_decoders),
        .special_detected(special_type)
    );
    
endmodule

/*
 * USB Token Decoder Sub-module
 * Decodes and identifies TOKEN type PIDs
 */
module usb_token_decoder (
    input  wire [3:0] pid,
    output reg  token_detected
);
    // Token PID values
    localparam OUT   = 4'b0001;
    localparam IN    = 4'b1001;
    localparam SOF   = 4'b0101;
    localparam SETUP = 4'b1101;
    
    always @(*) begin
        if ((pid == OUT) || (pid == IN) || (pid == SOF) || (pid == SETUP)) begin
            token_detected = 1'b1;
        end
        else begin
            token_detected = 1'b0;
        end
    end
endmodule

/*
 * USB Data Decoder Sub-module
 * Decodes and identifies DATA type PIDs
 */
module usb_data_decoder (
    input  wire [3:0] pid,
    output reg  data_detected
);
    // Data PID values
    localparam DATA0 = 4'b0011;
    localparam DATA1 = 4'b1011;
    
    always @(*) begin
        if ((pid == DATA0) || (pid == DATA1)) begin
            data_detected = 1'b1;
        end
        else begin
            data_detected = 1'b0;
        end
    end
endmodule

/*
 * USB Handshake Decoder Sub-module
 * Decodes and identifies HANDSHAKE type PIDs
 */
module usb_handshake_decoder (
    input  wire [3:0] pid,
    output reg  handshake_detected
);
    // Handshake PID values
    localparam ACK = 4'b0010;
    localparam NAK = 4'b1010;
    
    always @(*) begin
        if ((pid == ACK) || (pid == NAK)) begin
            handshake_detected = 1'b1;
        end
        else begin
            handshake_detected = 1'b0;
        end
    end
endmodule

/*
 * USB Special Decoder Sub-module
 * Decodes and identifies SPECIAL type PIDs
 */
module usb_special_decoder (
    input  wire [3:0] pid,
    output reg  special_detected
);
    // Special PID values
    localparam SPLIT = 4'b0110;
    
    always @(*) begin
        if (pid == SPLIT) begin
            special_detected = 1'b1;
        end
        else begin
            special_detected = 1'b0;
        end
    end
endmodule