//SystemVerilog
module usb_pid_decoder(
    input wire [3:0] pid,
    output reg token_type,
    output reg data_type,
    output reg handshake_type,
    output reg special_type,
    output reg [1:0] pid_type
);
    // PID type definitions
    localparam TOKEN_PID     = 2'b01;
    localparam DATA_PID      = 2'b11;
    localparam HANDSHAKE_PID = 2'b10;
    localparam SPECIAL_PID   = 2'b00;
    
    // Token PID definitions
    localparam OUT_TOKEN   = 4'b0001;
    localparam IN_TOKEN    = 4'b1001;
    localparam SOF_TOKEN   = 4'b0101;
    localparam SETUP_TOKEN = 4'b1101;
    
    // Data PID definitions
    localparam DATA0_PID = 4'b0011;
    localparam DATA1_PID = 4'b1011;
    
    // Handshake PID definitions
    localparam ACK_PID = 4'b0010;
    localparam NAK_PID = 4'b1010;
    
    // Special PID definitions
    localparam SPLIT_PID = 4'b0110;
    
    // Extract PID type - this is a simple direct assignment
    always @(*) begin
        pid_type = pid[1:0];
    end
    
    // Decode token type PIDs based on PID type and specific token values
    always @(*) begin
        if (pid_type == TOKEN_PID) begin
            case(pid[3:0])
                OUT_TOKEN:   token_type = 1'b1;
                IN_TOKEN:    token_type = 1'b1;
                SOF_TOKEN:   token_type = 1'b1;
                SETUP_TOKEN: token_type = 1'b1;
                default:     token_type = 1'b0;
            endcase
        end
        else begin
            token_type = 1'b0;
        end
    end
    
    // Decode data type PIDs based on PID type and specific data values
    always @(*) begin
        if (pid_type == DATA_PID) begin
            case(pid[3:0])
                DATA0_PID: data_type = 1'b1;
                DATA1_PID: data_type = 1'b1;
                default:   data_type = 1'b0;
            endcase
        end
        else begin
            data_type = 1'b0;
        end
    end
    
    // Decode handshake type PIDs based on PID type and specific handshake values
    always @(*) begin
        if (pid_type == HANDSHAKE_PID) begin
            case(pid[3:0])
                ACK_PID: handshake_type = 1'b1;
                NAK_PID: handshake_type = 1'b1;
                default: handshake_type = 1'b0;
            endcase
        end
        else begin
            handshake_type = 1'b0;
        end
    end
    
    // Decode special type PIDs based on PID type and specific special values
    always @(*) begin
        if (pid_type == SPECIAL_PID) begin
            case(pid[3:0])
                SPLIT_PID: special_type = 1'b1;
                default:   special_type = 1'b0;
            endcase
        end
        else begin
            special_type = 1'b0;
        end
    end
    
endmodule