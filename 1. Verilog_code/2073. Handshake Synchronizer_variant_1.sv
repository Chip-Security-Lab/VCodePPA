//SystemVerilog
module handshake_sync (
    input wire clk_a,
    input wire clk_b,
    input wire rst_n,
    input wire req_a,
    output reg req_b,
    output reg ack_a,
    input wire ack_b
);

    reg req_a_meta, req_a_sync;
    reg ack_b_meta, ack_b_sync;

    // Buffered version of req_b for fanout load balancing
    reg req_b_buf1, req_b_buf2;

    // A to B synchronization with buffered fanout
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            req_a_meta  <= 1'b0;
            req_a_sync  <= 1'b0;
            req_b_buf1  <= 1'b0;
            req_b_buf2  <= 1'b0;
            req_b       <= 1'b0;
        end else begin
            req_a_meta  <= req_a;
            req_a_sync  <= req_a_meta;
            req_b_buf1  <= req_a_sync;
            req_b_buf2  <= req_a_sync;
            req_b       <= req_a_sync;
        end
    end

    // B to A synchronization (unchanged, as ack_a is not high fanout in this context)
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            ack_b_meta <= 1'b0;
            ack_b_sync <= 1'b0;
            ack_a      <= 1'b0;
        end else begin
            ack_b_meta <= ack_b;
            ack_b_sync <= ack_b_meta;
            ack_a      <= ack_b_sync;
        end
    end

endmodule