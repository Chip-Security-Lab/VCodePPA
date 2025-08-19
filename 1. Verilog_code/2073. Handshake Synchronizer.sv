module handshake_sync (
    input wire clk_a, clk_b, rst_n,
    input wire req_a,
    output reg req_b,
    output reg ack_a,
    input wire ack_b
);
    reg req_a_meta, req_a_sync;
    reg ack_b_meta, ack_b_sync;
    
    // A to B synchronization
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) {req_a_meta, req_a_sync, req_b} <= 3'b000;
        else {req_a_meta, req_a_sync, req_b} <= {req_a, req_a_meta, req_a_sync};
    end
    
    // B to A synchronization
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) {ack_b_meta, ack_b_sync, ack_a} <= 3'b000;
        else {ack_b_meta, ack_b_sync, ack_a} <= {ack_b, ack_b_meta, ack_b_sync};
    end
endmodule