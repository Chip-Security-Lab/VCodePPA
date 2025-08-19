module protocol_handler(
    input wire clock, reset_n,
    input wire rx_data, rx_valid,
    output reg tx_data, tx_valid, error
);
    localparam IDLE=0, HEADER=1, PAYLOAD=2, CHECKSUM=3;
    reg [1:0] state, next;
    reg [3:0] byte_count;
    reg [7:0] checksum;
    
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            state <= IDLE;
            byte_count <= 4'd0;
            checksum <= 8'd0;
        end else begin
            state <= next;
            if (rx_valid) begin
                if (state == PAYLOAD) begin
                    byte_count <= byte_count + 4'd1;
                    checksum <= checksum ^ {7'd0, rx_data};
                end else if (state == HEADER) begin
                    byte_count <= 4'd0;
                    checksum <= 8'd0;
                end
            end
        end
    
    always @(*) begin
        next = state;
        tx_data = rx_data;
        tx_valid = 1'b0;
        error = 1'b0;
        
        case (state)
            IDLE: if (rx_valid && rx_data) next = HEADER;
            HEADER: if (rx_valid) next = PAYLOAD;
            PAYLOAD: begin
                tx_valid = rx_valid;
                if (rx_valid && byte_count == 4'd14) next = CHECKSUM;
            end
            CHECKSUM: begin
                if (rx_valid) begin
                    error = (checksum != {7'd0, rx_data});
                    next = IDLE;
                end
            end
        endcase
    end
endmodule