//SystemVerilog
//IEEE 1364-2005 Verilog
module dual_d_flip_flop (
    input wire clk,
    input wire rst_n,
    input wire req_d1,  // request signal for d1 (replaces valid)
    input wire req_d2,  // request signal for d2 (replaces valid)
    output reg ack_d1,  // acknowledge signal for d1 (replaces ready)
    output reg ack_d2,  // acknowledge signal for d2 (replaces ready)
    input wire d1,
    input wire d2,
    output reg q1,
    output reg q2
);
    reg d1_latched, d2_latched;
    reg req_d1_prev, req_d2_prev;
    
    // Edge detection for request signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_d1_prev <= 1'b0;
            req_d2_prev <= 1'b0;
        end else begin
            req_d1_prev <= req_d1;
            req_d2_prev <= req_d2;
        end
    end
    
    // Latch data on request edge
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1_latched <= 1'b0;
            d2_latched <= 1'b0;
            ack_d1 <= 1'b0;
            ack_d2 <= 1'b0;
        end else begin
            // For d1 channel
            if (req_d1 && !req_d1_prev) begin
                d1_latched <= d1;
                ack_d1 <= 1'b1;
            end else if (!req_d1) begin
                ack_d1 <= 1'b0;
            end
            
            // For d2 channel
            if (req_d2 && !req_d2_prev) begin
                d2_latched <= d2;
                ack_d2 <= 1'b1;
            end else if (!req_d2) begin
                ack_d2 <= 1'b0;
            end
        end
    end
    
    // Update output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q1 <= 1'b0;
            q2 <= 1'b0;
        end else begin
            if (req_d1 && ack_d1) q1 <= d1_latched;
            if (req_d2 && ack_d2) q2 <= d2_latched;
        end
    end
endmodule