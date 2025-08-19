//SystemVerilog
module PartialProduct(
    input clk,
    input rst_n,
    input [3:0] a, b,
    input req,
    output reg [7:0] result,
    output reg ack
);
    // Buffer registers for high fanout signals
    reg [3:0] a_buf, b_buf;
    reg req_buf, req_buf2;
    reg b0_buf, b1_buf, b2_buf, b3_buf;
    
    // Original registers
    reg [7:0] pp0, pp1, pp2, pp3;
    reg req_r;
    
    // First stage: Buffer high fanout inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_buf <= 4'b0;
            b_buf <= 4'b0;
            req_buf <= 1'b0;
            req_buf2 <= 1'b0;
            b0_buf <= 1'b0;
            b1_buf <= 1'b0;
            b2_buf <= 1'b0;
            b3_buf <= 1'b0;
        end else begin
            a_buf <= a;
            b_buf <= b;
            req_buf <= req;
            req_buf2 <= req_buf;
            b0_buf <= b[0];
            b1_buf <= b[1];
            b2_buf <= b[2];
            b3_buf <= b[3];
        end
    end
    
    // Second stage: Partial product calculation and result generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'b0;
            ack <= 1'b0;
            req_r <= 1'b0;
            pp0 <= 8'b0;
            pp1 <= 8'b0;
            pp2 <= 8'b0;
            pp3 <= 8'b0;
        end else begin
            req_r <= req_buf;
            
            if (req_buf && !req_r) begin
                // Calculate partial products using buffered signals
                pp0 <= b0_buf ? {4'b0, a_buf} : 8'b0;
                pp1 <= b1_buf ? {3'b0, a_buf, 1'b0} : 8'b0;
                pp2 <= b2_buf ? {2'b0, a_buf, 2'b0} : 8'b0;
                pp3 <= b3_buf ? {1'b0, a_buf, 3'b0} : 8'b0;
                ack <= 1'b0;
            end else if (req_r && !ack) begin
                // Sum the partial products
                result <= pp0 + pp1 + pp2 + pp3;
                ack <= 1'b1;
            end else if (!req_buf && req_r) begin
                // Reset acknowledge when request is deasserted
                ack <= 1'b0;
            end
        end
    end
endmodule