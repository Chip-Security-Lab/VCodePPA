//SystemVerilog
module fixed_encoder (
    input      [7:0] symbol,
    input            req_in,    // Replaces valid_in
    output reg [3:0] code,
    output reg       req_out,   // Replaces valid_out
    input            ack_in,    // New input for acknowledgment
    output reg       ack_out    // New output for acknowledgment
);
    // Internal registers for state tracking
    reg processing;
    reg [7:0] symbol_reg;

    // Combinational logic for encoding
    always @(*) begin
        if (processing) begin
            code = symbol_reg[3:0] ^ 4'h8;
            req_out = 1'b1;
        end else begin
            code = 4'h0;
            req_out = 1'b0;
        end
    end

    // Control logic for handshaking
    always @(posedge req_in or posedge ack_in) begin
        if (ack_in) begin
            // Complete the transaction when receiver acknowledges
            processing <= 1'b0;
            ack_out <= 1'b0;
        end else if (req_in && !processing) begin
            // Start processing when new request comes in
            processing <= 1'b1;
            symbol_reg <= symbol;
            ack_out <= 1'b1;
        end
    end

    // Reset handling
    initial begin
        processing = 1'b0;
        req_out = 1'b0;
        ack_out = 1'b0;
        symbol_reg = 8'h0;
    end
endmodule