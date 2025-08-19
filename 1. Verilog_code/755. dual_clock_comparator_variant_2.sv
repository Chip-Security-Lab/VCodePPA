//SystemVerilog
module dual_clock_comparator(
    // Clock domain A
    input clk_a,
    input rst_a,
    input [7:0] data_a,
    input req_a,
    output reg ack_a,
    
    // Clock domain B
    input clk_b,
    input rst_b,
    input [7:0] data_b,
    output reg match_b,
    output reg req_b
);
    // Double-flop synchronizer for clock domain crossing
    reg [7:0] data_a_sync1, data_a_sync2;
    reg req_a_sync1, req_a_sync2, req_a_sync3;
    reg ack_b, ack_b_sync1, ack_b_sync2;
    
    // Clock domain A logic
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_a <= 1'b0;
        end else begin
            ack_a <= ack_b_sync2;
        end
    end
    
    // Clock domain B synchronizer
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            data_a_sync1 <= 8'h00;
            data_a_sync2 <= 8'h00;
            req_a_sync1 <= 1'b0;
            req_a_sync2 <= 1'b0;
            req_a_sync3 <= 1'b0;
        end else begin
            data_a_sync1 <= data_a;
            data_a_sync2 <= data_a_sync1;
            req_a_sync1 <= req_a;
            req_a_sync2 <= req_a_sync1;
            req_a_sync3 <= req_a_sync2;
        end
    end
    
    // Comparison logic in clock domain B
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            match_b <= 1'b0;
            req_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            // Edge detection on req
            if (req_a_sync2 && !req_a_sync3) begin
                match_b <= (data_a_sync2 == data_b);
                req_b <= 1'b1;
                ack_b <= 1'b1;
            end else if (req_a_sync3 && !req_a_sync2) begin
                req_b <= 1'b0;
                ack_b <= 1'b0;
            end
        end
    end
    
    // Clock domain A synchronizer for ack
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
        end
    end
endmodule