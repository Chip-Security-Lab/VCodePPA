//SystemVerilog
module sync_reset_dist(
    input wire clk,
    input wire rst_req,       // Reset request (replaces rst_in)
    output reg rst_ack,       // Reset acknowledge
    output reg [7:0] rst_out
);
    // Pipeline registers for reset distribution
    reg rst_stage1;
    reg rst_stage2;
    reg rst_stage3;
    reg [3:0] rst_out_high_stage4;
    reg [3:0] rst_out_low_stage4;
    
    // Request handling state
    reg req_received;
    reg processing_done;

    // Pipeline stage 1 - Request capture with handshaking
    always @(posedge clk) begin
        if (rst_req && !req_received) begin
            rst_stage1 <= 1'b1;
            req_received <= 1'b1;
            rst_ack <= 1'b0;
        end
        else if (req_received && processing_done) begin
            // Reset acknowledgment when processing completes
            rst_ack <= 1'b1;
            if (!rst_req) begin
                // Clear request received flag when request is deasserted
                req_received <= 1'b0;
                rst_ack <= 1'b0;
            end
        end
    end

    // Pipeline stage 2 - First processing stage
    always @(posedge clk) begin
        rst_stage2 <= rst_stage1;
    end

    // Pipeline stage 3 - Second processing stage
    always @(posedge clk) begin
        rst_stage3 <= rst_stage2;
    end

    // Pipeline stage 4 - Output preparation (split for balanced load)
    always @(posedge clk) begin
        if (rst_stage3) begin
            rst_out_high_stage4 <= 4'hF;  // Upper 4 bits active
            rst_out_low_stage4 <= 4'hF;   // Lower 4 bits active
            processing_done <= 1'b1;      // Indicate processing is complete
        end
        else begin
            rst_out_high_stage4 <= 4'h0;  // Upper 4 bits inactive
            rst_out_low_stage4 <= 4'h0;   // Lower 4 bits inactive
            if (!rst_req) begin
                processing_done <= 1'b0;  // Clear processing done flag when request is deasserted
            end
        end
    end

    // Final output composition
    always @(posedge clk) begin
        rst_out <= {rst_out_high_stage4, rst_out_low_stage4};
    end
endmodule