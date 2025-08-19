//SystemVerilog
module protocol_handler(
    input wire clock, reset_n,
    input wire rx_data, rx_valid,
    output reg tx_data, tx_valid, error
);
    localparam IDLE=0, HEADER=1, PAYLOAD=2, CHECKSUM=3;
    reg [1:0] state, next;
    reg [3:0] byte_count;
    reg [7:0] checksum;
    wire payload_complete;
    
    assign payload_complete = (byte_count == 4'd14);
    
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            state <= IDLE;
            byte_count <= 4'd0;
            checksum <= 8'd0;
        end else begin
            state <= next;
            if (rx_valid) begin
                case (state)
                    PAYLOAD: begin
                        byte_count <= byte_count + 4'd1;
                        checksum <= checksum ^ {7'd0, rx_data};
                    end
                    HEADER: begin
                        byte_count <= 4'd0;
                        checksum <= 8'd0;
                    end
                    default: ;
                endcase
            end
        end
    
    always @(*) begin
        // Default values
        next = state;
        tx_data = rx_data;
        tx_valid = 1'b0;
        error = 1'b0;
        
        // State transition logic using explicit mux
        case (state)
            IDLE: begin
                next = (rx_valid & rx_data) ? HEADER : IDLE;
            end
            HEADER: begin
                next = rx_valid ? PAYLOAD : HEADER;
            end
            PAYLOAD: begin
                tx_valid = rx_valid;
                next = (rx_valid & payload_complete) ? CHECKSUM : PAYLOAD;
            end
            CHECKSUM: begin
                error = rx_valid & (checksum != {7'd0, rx_data});
                next = rx_valid ? IDLE : CHECKSUM;
            end
        endcase
    end
endmodule