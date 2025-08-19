module usb_pid_decoder(
    input wire [3:0] pid,
    output reg token_type,
    output reg data_type,
    output reg handshake_type,
    output reg special_type,
    output reg [1:0] pid_type
);
    always @(*) begin
        token_type = 1'b0;
        data_type = 1'b0;
        handshake_type = 1'b0;
        special_type = 1'b0;
        pid_type = pid[1:0];
        
        case(pid[3:0])
            4'b0001: token_type = 1'b1;    // OUT
            4'b1001: token_type = 1'b1;    // IN
            4'b0101: token_type = 1'b1;    // SOF
            4'b1101: token_type = 1'b1;    // SETUP
            4'b0011: data_type = 1'b1;     // DATA0
            4'b1011: data_type = 1'b1;     // DATA1
            4'b0010: handshake_type = 1'b1; // ACK
            4'b1010: handshake_type = 1'b1; // NAK
            4'b0110: special_type = 1'b1;   // SPLIT
            default: begin
                token_type = 1'b0;
                data_type = 1'b0;
                handshake_type = 1'b0;
                special_type = 1'b0;
            end
        endcase
    end
endmodule