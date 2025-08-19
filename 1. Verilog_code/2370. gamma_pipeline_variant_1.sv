//SystemVerilog
module gamma_pipeline (
    input wire clk,
    input wire aresetn,                // AXI-Stream reset (active low)
    
    // AXI-Stream input interface
    input wire [7:0] s_axis_tdata,     // Input data
    input wire s_axis_tvalid,          // Input valid signal
    output wire s_axis_tready,         // Input ready signal
    
    // AXI-Stream output interface
    output reg [7:0] m_axis_tdata,     // Output data
    output reg m_axis_tvalid,          // Output valid signal
    input wire m_axis_tready           // Output ready signal
);

// Pre-compute combinational logic operations before registering
wire [7:0] scaled_data = s_axis_tdata * 2;
wire [7:0] adjusted_data = scaled_data - 15;
wire [7:0] final_data = adjusted_data >> 1;

reg [7:0] stage1, stage2;              // Pipeline registers
reg stage1_valid, stage2_valid;        // Valid flags for pipeline stages
wire stage1_ready, stage2_ready;       // Ready signals for pipeline stages

// Stage readiness logic (backpressure handling)
assign stage1_ready = !stage1_valid || stage2_ready;
assign stage2_ready = !stage2_valid || m_axis_tready;
assign s_axis_tready = stage1_ready;

// Pipeline stage 1: Register the complete combinational logic output
// Forward retiming - moved register past the combinational logic
always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
        stage1 <= 8'h0;
        stage1_valid <= 1'b0;
    end else if (stage1_ready) begin
        if (s_axis_tvalid) begin
            stage1 <= adjusted_data;  // Register after offset adjustment
            stage1_valid <= 1'b1;
        end else begin
            stage1_valid <= 1'b0;
        end
    end
end

// Pipeline stage 2: Second stage of pipeline
always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
        stage2 <= 8'h0;
        stage2_valid <= 1'b0;
    end else if (stage2_ready) begin
        if (stage1_valid) begin
            stage2 <= stage1;          // Pass through value
            stage2_valid <= 1'b1;
        end else begin
            stage2_valid <= 1'b0;
        end
    end
end

// Pipeline stage 3: Final output
always @(posedge clk or negedge aresetn) begin
    if (!aresetn) begin
        m_axis_tdata <= 8'h0;
        m_axis_tvalid <= 1'b0;
    end else if (m_axis_tready || !m_axis_tvalid) begin
        if (stage2_valid) begin
            m_axis_tdata <= stage2 >> 1; // Final scaling
            m_axis_tvalid <= 1'b1;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end
end

endmodule