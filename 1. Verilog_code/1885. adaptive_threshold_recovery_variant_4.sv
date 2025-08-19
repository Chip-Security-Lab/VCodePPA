//SystemVerilog
module adaptive_threshold_recovery (
    input wire clk,
    input wire reset,
    
    // AXI-Stream Input Interface
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [7:0] noise_level,
    
    // AXI-Stream Output Interface
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);
    // Internal registers
    reg [7:0] threshold_r;
    reg [7:0] m_axis_tdata_r;
    reg m_axis_tvalid_r;
    reg processing_done_r;
    
    // Internal combinational signals
    wire [7:0] next_threshold;
    wire [7:0] next_output_data;
    wire next_output_valid;
    wire next_processing_done;
    wire can_accept_data;
    wire data_transfer;
    wire output_transfer;
    
    // Combinational logic module instantiation
    threshold_logic threshold_comb (
        .noise_level(noise_level),
        .input_data(s_axis_tdata),
        .current_threshold(threshold_r),
        .next_threshold(next_threshold),
        .next_output_data(next_output_data),
        .next_output_valid(next_output_valid)
    );
    
    // Control signals - combinational logic
    assign can_accept_data = !processing_done_r || m_axis_tready;
    assign s_axis_tready = can_accept_data;
    assign data_transfer = s_axis_tvalid && can_accept_data;
    assign output_transfer = m_axis_tvalid_r && m_axis_tready;
    assign next_processing_done = data_transfer ? 1'b1 : 
                                 output_transfer ? 1'b0 : processing_done_r;
    
    // Output assignments
    assign m_axis_tdata = m_axis_tdata_r;
    assign m_axis_tvalid = m_axis_tvalid_r;
    
    // Sequential logic block
    always @(posedge clk) begin
        if (reset) begin
            threshold_r <= 8'd128;
            m_axis_tdata_r <= 8'd0;
            m_axis_tvalid_r <= 1'b0;
            processing_done_r <= 1'b0;
        end else begin
            // Update threshold when new data is accepted
            if (data_transfer) begin
                threshold_r <= next_threshold;
                m_axis_tdata_r <= next_output_data;
                m_axis_tvalid_r <= next_output_valid;
            end
            
            // Clear valid when data is accepted by downstream module
            if (output_transfer) begin
                m_axis_tvalid_r <= 1'b0;
            end
            
            // Update processing state
            processing_done_r <= next_processing_done;
        end
    end
endmodule

// Combinational logic module for threshold calculation and comparison
module threshold_logic (
    input wire [7:0] noise_level,
    input wire [7:0] input_data,
    input wire [7:0] current_threshold,
    output wire [7:0] next_threshold,
    output wire [7:0] next_output_data,
    output wire next_output_valid
);
    // Calculate new threshold based on noise level
    assign next_threshold = 8'd64 + (noise_level >> 1);
    
    // Apply threshold to determine output
    assign next_output_valid = (input_data > current_threshold) ? 1'b1 : 1'b0;
    assign next_output_data = (input_data > current_threshold) ? input_data : 8'd0;
endmodule