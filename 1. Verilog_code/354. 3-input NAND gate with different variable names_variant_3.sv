//SystemVerilog
// Top level module - nand3 implementation with AXI-Stream interface
module nand3_2 (
    // AXI-Stream slave interface (input)
    input  wire        s_axis_aclk,
    input  wire        s_axis_aresetn,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [2:0]  s_axis_tdata,  // X, Y, Z are packed in 3 bits
    input  wire        s_axis_tlast,  // Optional, indicates end of packet
    
    // AXI-Stream master interface (output)
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [0:0]  m_axis_tdata,  // Single bit output
    output wire        m_axis_tlast
);
    // Internal signals and registers
    reg X_reg, Y_reg, Z_reg;
    reg and_stage1_reg, and_result_reg;
    
    // Control signals
    reg s1_valid, s2_valid, s3_valid;
    reg s1_last, s2_last, s3_last;
    
    // Flow control - always ready to accept new data when downstream is ready
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    
    // Input stage - synchronized with handshaking
    always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
        if (!s_axis_aresetn) begin
            X_reg <= 1'b0;
            Y_reg <= 1'b0;
            Z_reg <= 1'b0;
            s1_valid <= 1'b0;
            s1_last <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            // Capture data when handshake occurs
            X_reg <= s_axis_tdata[2];
            Y_reg <= s_axis_tdata[1];
            Z_reg <= s_axis_tdata[0];
            s1_valid <= 1'b1;
            s1_last <= s_axis_tlast;
        end else if (s2_valid && (m_axis_tready || !s3_valid)) begin
            // Pipeline bubble when data is consumed but not replaced
            s1_valid <= 1'b0;
        end
    end
    
    // Stage 1: Compute partial AND result with flow control
    always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
        if (!s_axis_aresetn) begin
            and_stage1_reg <= 1'b0;
            s2_valid <= 1'b0;
            s2_last <= 1'b0;
        end else if (s1_valid && (m_axis_tready || !s3_valid)) begin
            and_stage1_reg <= X_reg & Y_reg;
            s2_valid <= s1_valid;
            s2_last <= s1_last;
        end else if (s3_valid && m_axis_tready) begin
            // Pipeline bubble when data is consumed but not replaced
            s2_valid <= 1'b0;
        end
    end
    
    // Stage 2: Complete AND operation with flow control
    always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
        if (!s_axis_aresetn) begin
            and_result_reg <= 1'b0;
            s3_valid <= 1'b0;
            s3_last <= 1'b0;
        end else if (s2_valid && (m_axis_tready || !s3_valid)) begin
            and_result_reg <= and_stage1_reg & Z_reg;
            s3_valid <= s2_valid;
            s3_last <= s2_last;
        end else if (s3_valid && m_axis_tready) begin
            // Clear valid when data is consumed
            s3_valid <= 1'b0;
        end
    end
    
    // AXI-Stream output assignments
    assign m_axis_tvalid = s3_valid;
    assign m_axis_tdata = ~and_result_reg;  // NAND result
    assign m_axis_tlast = s3_last;
    
endmodule