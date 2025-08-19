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
    output reg valid_b
);
    // Double-flop synchronizer for clock domain crossing
    reg [7:0] data_a_sync1, data_a_sync2;
    reg req_a_sync1, req_a_sync2, req_a_sync3;
    reg ack_b, ack_b_sync1, ack_b_sync2;
    reg req_a_edge_detected;
    reg req_a_falling_edge;
    
    //---------- Clock Domain A Logic ----------//
    
    // Domain A acknowledgment logic
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_a <= 1'b0;
        end else begin
            ack_a <= ack_b_sync2;
        end
    end
    
    // Clock domain A synchronizer for ack_b
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
        end
    end
    
    //---------- Clock Domain B Logic ----------//
    
    // Data synchronizer from domain A to B
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            data_a_sync1 <= 8'h00;
            data_a_sync2 <= 8'h00;
        end else begin
            data_a_sync1 <= data_a;
            data_a_sync2 <= data_a_sync1;
        end
    end
    
    // Request signal synchronizer from domain A to B
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            req_a_sync1 <= 1'b0;
            req_a_sync2 <= 1'b0;
            req_a_sync3 <= 1'b0;
        end else begin
            req_a_sync1 <= req_a;
            req_a_sync2 <= req_a_sync1;
            req_a_sync3 <= req_a_sync2;
        end
    end
    
    // Edge detection logic
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            req_a_edge_detected <= 1'b0;
            req_a_falling_edge <= 1'b0;
        end else begin
            req_a_edge_detected <= req_a_sync2 && !req_a_sync3;
            req_a_falling_edge <= !req_a_sync2 && req_a_sync3;
        end
    end
    
    // Comparison and output generation logic
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            match_b <= 1'b0;
            valid_b <= 1'b0;
        end else if (req_a_edge_detected) begin
            match_b <= (data_a_sync2 == data_b);
            valid_b <= 1'b1;
        end else if (req_a_falling_edge) begin
            valid_b <= 1'b0;
        end
    end
    
    // Acknowledgment generation in domain B
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            ack_b <= 1'b0;
        end else if (req_a_edge_detected) begin
            ack_b <= 1'b1;
        end else if (req_a_falling_edge) begin
            ack_b <= 1'b0;
        end
    end
    
endmodule