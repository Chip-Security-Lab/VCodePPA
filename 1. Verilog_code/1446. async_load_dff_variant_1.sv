//SystemVerilog
module async_load_dff (
    input wire clk,
    input wire rst_n,         // Reset signal (active low)
    
    // AXI-Stream Slave Interface (Input)
    input wire [3:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    
    // AXI-Stream Master Interface (Output)
    output wire [3:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

    // Pipeline stage registers
    reg [3:0] data_stage1, data_stage2;
    reg valid_stage1, valid_stage2;
    
    // Pipeline control signals
    wire ready_stage2, ready_stage1;
    reg processing_stage1, processing_stage2;
    
    // Handshaking signals
    assign s_axis_tready = !processing_stage1 || ready_stage1;
    assign ready_stage1 = !valid_stage1 || ready_stage2;
    assign ready_stage2 = !valid_stage2 || m_axis_tready;
    
    // Output interface connections
    assign m_axis_tdata = data_stage2;
    assign m_axis_tvalid = valid_stage2;
    
    // Stage 1: Input handling and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
            processing_stage1 <= 1'b0;
        end else begin
            // Handle stage 1 pipeline flow
            if (ready_stage1) begin
                valid_stage1 <= 1'b0;
                processing_stage1 <= 1'b0;
            end
            
            // Input data handling
            if (s_axis_tvalid && s_axis_tready) begin
                data_stage1 <= s_axis_tdata;
                valid_stage1 <= 1'b1;
                processing_stage1 <= 1'b1;
            end else if (!valid_stage1 && !processing_stage1) begin
                // Increment counter when no valid input and not processing
                data_stage1 <= (valid_stage2) ? data_stage2 + 1 : 4'b0 + 1;
                valid_stage1 <= 1'b1;
                processing_stage1 <= 1'b1;
            end
        end
    end
    
    // Stage 2: Output handling and final processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
            processing_stage2 <= 1'b0;
        end else begin
            // Handle output acceptance
            if (valid_stage2 && m_axis_tready) begin
                valid_stage2 <= 1'b0;
                processing_stage2 <= 1'b0;
            end
            
            // Forward data from stage 1 to stage 2
            if (valid_stage1 && ready_stage1) begin
                data_stage2 <= data_stage1;
                valid_stage2 <= 1'b1;
                processing_stage2 <= 1'b1;
            end
        end
    end

endmodule