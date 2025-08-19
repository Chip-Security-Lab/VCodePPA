//SystemVerilog
module threshold_comparator(
    input clk,
    input rst,
    input [7:0] threshold,
    input [7:0] data_input,
    input req_threshold,
    output reg ack_threshold,
    output reg req_result,
    output reg [2:0] result_data
);

    reg [7:0] threshold_reg;
    reg [2:0] comparison_result;
    reg threshold_update_pending;
    reg result_ack_pending;
    
    // Buffer registers for high fanout signals
    reg [7:0] data_input_buf;
    reg [7:0] threshold_reg_buf;
    reg [2:0] comparison_result_buf;
    reg [2:0] comparison_result_buf2;
    
    // First stage buffer for data_input and threshold_reg
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_input_buf <= 8'h00;
            threshold_reg_buf <= 8'h00;
        end else begin
            data_input_buf <= data_input;
            threshold_reg_buf <= threshold_reg;
        end
    end
    
    // Threshold register update logic with req-ack handshake
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            threshold_reg <= 8'h00;
            ack_threshold <= 1'b0;
            threshold_update_pending <= 1'b0;
        end else begin
            if (req_threshold && !threshold_update_pending) begin
                threshold_reg <= threshold;
                ack_threshold <= 1'b1;
                threshold_update_pending <= 1'b1;
            end else if (!req_threshold && threshold_update_pending) begin
                ack_threshold <= 1'b0;
                threshold_update_pending <= 1'b0;
            end
        end
    end
    
    // Comparison logic with two-stage buffering
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            comparison_result <= 3'b000;
            comparison_result_buf <= 3'b000;
            comparison_result_buf2 <= 3'b000;
            req_result <= 1'b0;
            result_ack_pending <= 1'b0;
        end else begin
            // First stage comparison
            comparison_result[2] <= (data_input_buf > threshold_reg_buf);
            comparison_result[1] <= (data_input_buf < threshold_reg_buf);
            comparison_result[0] <= (data_input_buf == threshold_reg_buf);
            
            // Second stage buffer
            comparison_result_buf <= comparison_result;
            comparison_result_buf2 <= comparison_result_buf;
            
            // Request handling with buffered results
            if (!result_ack_pending) begin
                req_result <= 1'b1;
                result_data <= comparison_result_buf2;
                result_ack_pending <= 1'b1;
            end else if (result_ack_pending && req_result) begin
                req_result <= 1'b0;
            end else if (!req_result && result_ack_pending) begin
                result_ack_pending <= 1'b0;
            end
        end
    end
endmodule