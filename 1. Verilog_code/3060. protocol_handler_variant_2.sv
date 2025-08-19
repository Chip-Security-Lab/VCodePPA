//SystemVerilog
module protocol_handler(
    input wire clock, reset_n,
    input wire rx_data, rx_req,
    output reg rx_ack,
    output reg tx_data, tx_req,
    input wire tx_ack,
    output reg error
);
    localparam IDLE=0, HEADER=1, PAYLOAD=2, CHECKSUM=3;
    reg [1:0] state, next;
    reg [3:0] byte_count;
    reg [7:0] checksum;
    reg rx_valid_reg;
    wire [7:0] rx_data_ext;
    wire checksum_match;
    
    assign rx_data_ext = {7'd0, rx_data};
    assign checksum_match = (checksum == rx_data_ext);
    
    always @(posedge clock or negedge reset_n)
        if (!reset_n) begin
            state <= IDLE;
            byte_count <= 4'd0;
            checksum <= 8'd0;
            rx_valid_reg <= 1'b0;
            rx_ack <= 1'b0;
        end else begin
            state <= next;
            rx_valid_reg <= rx_req;
            rx_ack <= rx_req;
            
            if (rx_valid_reg) begin
                if (state == PAYLOAD) begin
                    byte_count <= byte_count + 4'd1;
                    checksum <= checksum ^ rx_data_ext;
                end else if (state == HEADER) begin
                    byte_count <= 4'd0;
                    checksum <= 8'd0;
                end
            end
        end
    
    always @(*) begin
        next = state;
        tx_data = rx_data;
        tx_req = 1'b0;
        error = 1'b0;
        
        case (state)
            IDLE: if (rx_valid_reg && rx_data) next = HEADER;
            HEADER: if (rx_valid_reg) next = PAYLOAD;
            PAYLOAD: begin
                tx_req = rx_valid_reg;
                if (rx_valid_reg && byte_count == 4'd14) next = CHECKSUM;
            end
            CHECKSUM: begin
                if (rx_valid_reg) begin
                    error = ~checksum_match;
                    next = IDLE;
                end
            end
        endcase
    end
endmodule