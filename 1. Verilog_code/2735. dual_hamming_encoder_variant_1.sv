//SystemVerilog
module dual_hamming_encoder(
    input clk, rst_n,
    input [3:0] data_a, data_b,
    input valid_a, valid_b,
    output reg ready_a, ready_b,
    output reg [6:0] encoded_a, encoded_b
);

    // Internal state
    reg [6:0] next_encoded_a, next_encoded_b;
    reg busy_a, busy_b;

    // Channel A encoding logic
    always @(*) begin
        next_encoded_a[0] = data_a[0] ^ data_a[1] ^ data_a[3];
        next_encoded_a[1] = data_a[0] ^ data_a[2] ^ data_a[3];
        next_encoded_a[2] = data_a[0];
        next_encoded_a[3] = data_a[1] ^ data_a[2] ^ data_a[3];
        next_encoded_a[4] = data_a[1];
        next_encoded_a[5] = data_a[2];
        next_encoded_a[6] = data_a[3];
    end

    // Channel B encoding logic
    always @(*) begin
        next_encoded_b[0] = data_b[0] ^ data_b[1] ^ data_b[3];
        next_encoded_b[1] = data_b[0] ^ data_b[2] ^ data_b[3];
        next_encoded_b[2] = data_b[0];
        next_encoded_b[3] = data_b[1] ^ data_b[2] ^ data_b[3];
        next_encoded_b[4] = data_b[1];
        next_encoded_b[5] = data_b[2];
        next_encoded_b[6] = data_b[3];
    end

    // Sequential logic for state and output updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_a <= 7'b0;
            encoded_b <= 7'b0;
            ready_a <= 1'b1;
            ready_b <= 1'b1;
            busy_a <= 1'b0;
            busy_b <= 1'b0;
        end else begin
            // Channel A state machine
            if (valid_a && ready_a) begin
                encoded_a <= next_encoded_a;
                busy_a <= 1'b1;
                ready_a <= 1'b0;
            end else if (!busy_a) begin
                ready_a <= 1'b1;
            end

            // Channel B state machine
            if (valid_b && ready_b) begin
                encoded_b <= next_encoded_b;
                busy_b <= 1'b1;
                ready_b <= 1'b0;
            end else if (!busy_b) begin
                ready_b <= 1'b1;
            end
        end
    end

endmodule