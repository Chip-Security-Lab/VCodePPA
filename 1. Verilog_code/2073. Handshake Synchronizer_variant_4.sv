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

    // Synchronization registers for req_a (clk_b domain)
    reg req_a_meta;
    reg req_a_sync;

    // Synchronization registers for ack_b (clk_a domain)
    reg ack_b_meta;
    reg ack_b_sync;

    // req_a_meta register (clk_b domain)
    always @(posedge clk_b or negedge rst_n) begin
        req_a_meta <= (!rst_n) ? 1'b0 : req_a;
    end

    // req_a_sync register (clk_b domain)
    always @(posedge clk_b or negedge rst_n) begin
        req_a_sync <= (!rst_n) ? 1'b0 : req_a_meta;
    end

    // req_b output register (clk_b domain)
    always @(posedge clk_b or negedge rst_n) begin
        req_b <= (!rst_n) ? 1'b0 : req_a_sync;
    end

    // ack_b_meta register (clk_a domain)
    always @(posedge clk_a or negedge rst_n) begin
        ack_b_meta <= (!rst_n) ? 1'b0 : ack_b;
    end

    // ack_b_sync register (clk_a domain)
    always @(posedge clk_a or negedge rst_n) begin
        ack_b_sync <= (!rst_n) ? 1'b0 : ack_b_meta;
    end

    // ack_a output register (clk_a domain)
    always @(posedge clk_a or negedge rst_n) begin
        ack_a <= (!rst_n) ? 1'b0 : ack_b_sync;
    end

endmodule