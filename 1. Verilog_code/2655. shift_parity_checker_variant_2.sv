//SystemVerilog
module shift_parity_checker (
    input clk,
    input rst_n,
    input serial_in,
    input req,          // Request signal (replacing valid)
    output reg ack,     // Acknowledge signal (replacing ready)
    output reg parity
);

reg [7:0] shift_reg;
reg data_received;
reg processing;

// Handshake control FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ack <= 1'b0;
        processing <= 1'b0;
        data_received <= 1'b0;
    end else begin
        // Create a case statement based on {req, processing, data_received}
        case ({req, processing, data_received})
            3'b100, 3'b101: begin // req && !processing
                ack <= 1'b1;
                processing <= 1'b1;
                data_received <= 1'b1;
            end
            3'b011: begin // processing && data_received
                ack <= 1'b0;
                data_received <= 1'b0;
            end
            3'b010: begin // processing && !data_received
                ack <= 1'b0;
                processing <= 1'b0;
            end
            default: begin
                ack <= ack;
                processing <= processing;
                data_received <= data_received;
            end
        endcase
    end
end

// Data processing logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'b0;
        parity <= 1'b0;
    end else begin
        case (data_received)
            1'b1: begin
                shift_reg <= {shift_reg[6:0], serial_in};
                parity <= ^{shift_reg[6:0], serial_in};
            end
            default: begin
                shift_reg <= shift_reg;
                parity <= parity;
            end
        endcase
    end
end

endmodule