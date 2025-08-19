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
    // Clock buffering for clk_b to reduce fanout
    reg clk_b_buf1, clk_b_buf2, clk_b_buf3;
    
    // Stage indicators for pipeline control
    reg req_valid_stage1_b, req_valid_stage2_b, req_valid_stage3_b;
    
    // Pipeline registers for data
    reg [7:0] data_a_stage1_b, data_a_stage2_b, data_a_stage3_b;
    reg [7:0] data_b_stage1, data_b_stage2, data_b_stage3;
    
    // Cross-domain synchronization registers
    reg [7:0] data_a_sync1, data_a_sync2;
    reg req_a_sync1, req_a_sync2;
    reg ack_b, ack_b_sync1, ack_b_sync2;
    
    // Edge detection registers
    reg req_a_edge_detected;
    
    // Reset signal buffering for B domain
    reg rst_b_buf1, rst_b_buf2, rst_b_buf3;
    
    // Initial value buffering to reduce fanout
    reg [7:0] h00_buf1, h00_buf2, h00_buf3;

    // Clock buffer for clk_b - implements clock tree
    always @(posedge clk_b) begin
        clk_b_buf1 <= 1'b1;
        clk_b_buf2 <= 1'b1;
        clk_b_buf3 <= 1'b1;
    end
    
    // Reset buffering for domain B
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            rst_b_buf1 <= 1'b1;
            rst_b_buf2 <= 1'b1;
            rst_b_buf3 <= 1'b1;
            h00_buf1 <= 8'h00;
            h00_buf2 <= 8'h00;
            h00_buf3 <= 8'h00;
        end else begin
            rst_b_buf1 <= 1'b0;
            rst_b_buf2 <= 1'b0;
            rst_b_buf3 <= 1'b0;
            h00_buf1 <= 8'h00;
            h00_buf2 <= 8'h00;
            h00_buf3 <= 8'h00;
        end
    end
    
    // Clock domain A logic
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            ack_a <= 1'b0;
            ack_b_sync1 <= 1'b0;
            ack_b_sync2 <= 1'b0;
        end else begin
            // Synchronize acknowledgment back to domain A
            ack_b_sync1 <= ack_b;
            ack_b_sync2 <= ack_b_sync1;
            ack_a <= ack_b_sync2;
        end
    end
    
    // Clock domain B - Stage 1: Synchronization and edge detection
    always @(posedge clk_b_buf1 or posedge rst_b_buf1) begin
        if (rst_b_buf1) begin
            data_a_sync1 <= h00_buf1;
            data_a_sync2 <= h00_buf1;
            req_a_sync1 <= 1'b0;
            req_a_sync2 <= 1'b0;
            req_a_edge_detected <= 1'b0;
            req_valid_stage1_b <= 1'b0;
            data_a_stage1_b <= h00_buf1;
            data_b_stage1 <= h00_buf1;
        end else begin
            // CDC synchronization
            data_a_sync1 <= data_a;
            data_a_sync2 <= data_a_sync1;
            req_a_sync1 <= req_a;
            req_a_sync2 <= req_a_sync1;
            
            // Edge detection (rising edge on req_a)
            req_a_edge_detected <= req_a_sync2 & ~req_valid_stage1_b;
            
            // Pipeline Stage 1 input registration
            if (req_a_edge_detected) begin
                data_a_stage1_b <= data_a_sync2;
                data_b_stage1 <= data_b;
                req_valid_stage1_b <= 1'b1;
            end else if (req_valid_stage3_b) begin
                // Reset detection logic for next request
                req_valid_stage1_b <= 1'b0;
            end
        end
    end
    
    // Clock domain B - Stage 2: Data preparation
    always @(posedge clk_b_buf2 or posedge rst_b_buf2) begin
        if (rst_b_buf2) begin
            data_a_stage2_b <= h00_buf2;
            data_b_stage2 <= h00_buf2;
            req_valid_stage2_b <= 1'b0;
        end else begin
            // Forward pipeline stage signals
            data_a_stage2_b <= data_a_stage1_b;
            data_b_stage2 <= data_b_stage1;
            req_valid_stage2_b <= req_valid_stage1_b;
        end
    end
    
    // Clock domain B - Stage 3: Comparison and output generation
    always @(posedge clk_b_buf3 or posedge rst_b_buf3) begin
        if (rst_b_buf3) begin
            data_a_stage3_b <= h00_buf3;
            data_b_stage3 <= h00_buf3;
            req_valid_stage3_b <= 1'b0;
            match_b <= 1'b0;
            valid_b <= 1'b0;
            ack_b <= 1'b0;
        end else begin
            // Forward pipeline signals
            data_a_stage3_b <= data_a_stage2_b;
            data_b_stage3 <= data_b_stage2;
            req_valid_stage3_b <= req_valid_stage2_b;
            
            // Generate outputs when valid data reaches final stage
            if (req_valid_stage3_b && !valid_b) begin
                match_b <= (data_a_stage3_b == data_b_stage3);
                valid_b <= 1'b1;
                ack_b <= 1'b1;
            end else if (valid_b && !req_valid_stage2_b) begin
                valid_b <= 1'b0;
                ack_b <= 1'b0;
            end
        end
    end
endmodule