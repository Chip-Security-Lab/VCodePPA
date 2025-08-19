//SystemVerilog
module handshake_sync (
    input  wire clk_a,
    input  wire clk_b,
    input  wire rst_n,
    input  wire req_a,
    output wire req_b,
    output wire ack_a,
    input  wire ack_b
);

// Pipeline stage signals for req_a synchronization (A to B)
reg req_a_stage1, req_a_stage2, req_a_stage3, req_a_stage4;
reg valid_req_a_stage1, valid_req_a_stage2, valid_req_a_stage3, valid_req_a_stage4;
reg flush_req_a_stage1, flush_req_a_stage2, flush_req_a_stage3, flush_req_a_stage4;

// Pipeline stage signals for ack_b synchronization (B to A)
reg ack_b_stage1, ack_b_stage2, ack_b_stage3, ack_b_stage4;
reg valid_ack_b_stage1, valid_ack_b_stage2, valid_ack_b_stage3, valid_ack_b_stage4;
reg flush_ack_b_stage1, flush_ack_b_stage2, flush_ack_b_stage3, flush_ack_b_stage4;

// A to B pipeline for req_a
always @(posedge clk_b or negedge rst_n) begin
    if (!rst_n) begin
        req_a_stage1         <= 1'b0;
        req_a_stage2         <= 1'b0;
        req_a_stage3         <= 1'b0;
        req_a_stage4         <= 1'b0;
        valid_req_a_stage1   <= 1'b0;
        valid_req_a_stage2   <= 1'b0;
        valid_req_a_stage3   <= 1'b0;
        valid_req_a_stage4   <= 1'b0;
        flush_req_a_stage1   <= 1'b0;
        flush_req_a_stage2   <= 1'b0;
        flush_req_a_stage3   <= 1'b0;
        flush_req_a_stage4   <= 1'b0;
    end else begin
        // Pipeline stage 1
        req_a_stage1         <= req_a;
        valid_req_a_stage1   <= 1'b1;
        flush_req_a_stage1   <= ~rst_n;

        // Pipeline stage 2
        req_a_stage2         <= req_a_stage1;
        valid_req_a_stage2   <= valid_req_a_stage1 & ~flush_req_a_stage1;
        flush_req_a_stage2   <= flush_req_a_stage1;

        // Pipeline stage 3
        req_a_stage3         <= req_a_stage2;
        valid_req_a_stage3   <= valid_req_a_stage2 & ~flush_req_a_stage2;
        flush_req_a_stage3   <= flush_req_a_stage2;

        // Pipeline stage 4 (output)
        req_a_stage4         <= req_a_stage3;
        valid_req_a_stage4   <= valid_req_a_stage3 & ~flush_req_a_stage3;
        flush_req_a_stage4   <= flush_req_a_stage3;
    end
end

// B to A pipeline for ack_b
always @(posedge clk_a or negedge rst_n) begin
    if (!rst_n) begin
        ack_b_stage1         <= 1'b0;
        ack_b_stage2         <= 1'b0;
        ack_b_stage3         <= 1'b0;
        ack_b_stage4         <= 1'b0;
        valid_ack_b_stage1   <= 1'b0;
        valid_ack_b_stage2   <= 1'b0;
        valid_ack_b_stage3   <= 1'b0;
        valid_ack_b_stage4   <= 1'b0;
        flush_ack_b_stage1   <= 1'b0;
        flush_ack_b_stage2   <= 1'b0;
        flush_ack_b_stage3   <= 1'b0;
        flush_ack_b_stage4   <= 1'b0;
    end else begin
        // Pipeline stage 1
        ack_b_stage1         <= ack_b;
        valid_ack_b_stage1   <= 1'b1;
        flush_ack_b_stage1   <= ~rst_n;

        // Pipeline stage 2
        ack_b_stage2         <= ack_b_stage1;
        valid_ack_b_stage2   <= valid_ack_b_stage1 & ~flush_ack_b_stage1;
        flush_ack_b_stage2   <= flush_ack_b_stage1;

        // Pipeline stage 3
        ack_b_stage3         <= ack_b_stage2;
        valid_ack_b_stage3   <= valid_ack_b_stage2 & ~flush_ack_b_stage2;
        flush_ack_b_stage3   <= flush_ack_b_stage2;

        // Pipeline stage 4 (output)
        ack_b_stage4         <= ack_b_stage3;
        valid_ack_b_stage4   <= valid_ack_b_stage3 & ~flush_ack_b_stage3;
        flush_ack_b_stage4   <= flush_ack_b_stage3;
    end
end

// Output assignments with valid control
assign req_b = valid_req_a_stage4 ? req_a_stage4 : 1'b0;
assign ack_a = valid_ack_b_stage4 ? ack_b_stage4 : 1'b0;

endmodule