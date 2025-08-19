//SystemVerilog
module scan_d_ff (
    input wire clk,
    input wire rst_n,
    input wire scan_en,
    input wire scan_in,
    input wire d,
    output wire q,
    output wire scan_out
);
    // Pipeline stage 1 - Input capture
    reg stage1_scan_en;
    reg stage1_scan_in;
    reg stage1_d;
    reg stage1_valid;
    
    // Pipeline stage 2 - Processing
    reg stage2_muxed_data;
    reg stage2_valid;
    
    // Pipeline stage 3 - Output register
    reg stage3_q;
    reg stage3_valid;
    
    // Pipeline control signals
    wire ready_to_accept;
    reg [1:0] pipeline_status;  // Tracks active pipeline stages
    
    // Stage 1: Input capture with ready signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_scan_en <= 1'b0;
            stage1_scan_in <= 1'b0;
            stage1_d <= 1'b0;
            stage1_valid <= 1'b0;
            pipeline_status <= 2'b00;
        end
        else if (ready_to_accept) begin
            stage1_scan_en <= scan_en;
            stage1_scan_in <= scan_in;
            stage1_d <= d;
            stage1_valid <= 1'b1;
            pipeline_status[0] <= 1'b1;
        end
        else if (stage2_valid) begin
            // Keep stage1 values when stage2 advances but we can't accept new input
            stage1_valid <= 1'b0;
            pipeline_status[0] <= 1'b0;
        end
    end
    
    // Stage 2: Processing (multiplexing) with forwarding logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_muxed_data <= 1'b0;
            stage2_valid <= 1'b0;
            pipeline_status[1] <= 1'b0;
        end
        else if (stage1_valid) begin
            stage2_muxed_data <= stage1_scan_en ? stage1_scan_in : stage1_d;
            stage2_valid <= 1'b1;
            pipeline_status[1] <= 1'b1;
        end
        else if (stage3_valid) begin
            // Clear stage2 valid when stage3 consumes the data
            stage2_valid <= 1'b0;
            pipeline_status[1] <= 1'b0;
        end
    end
    
    // Stage 3: Output register with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_q <= 1'b0;
            stage3_valid <= 1'b0;
        end
        else if (stage2_valid) begin
            stage3_q <= stage2_muxed_data;
            stage3_valid <= 1'b1;
        end
    end
    
    // Pipeline handshaking and flow control
    assign ready_to_accept = (pipeline_status == 2'b00) || 
                            (pipeline_status == 2'b01 && !stage1_valid) || 
                            (pipeline_status == 2'b10 && !stage2_valid) ||
                            (pipeline_status == 2'b11 && stage3_valid);
    
    // Output assignment with forwarding for reduced latency
    // Direct forwarding from stage3 to output for improved timing
    assign q = stage3_q;
    assign scan_out = stage3_q;
    
endmodule