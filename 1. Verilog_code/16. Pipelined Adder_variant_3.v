module pipelined_adder(
    input clk,
    input s_axis_tvalid,
    output reg s_axis_tready,
    input [15:0] s_axis_tdata,
    input s_axis_tlast,
    
    output reg m_axis_tvalid,
    input m_axis_tready,
    output reg [7:0] m_axis_tdata,
    output reg m_axis_tlast
);
    reg [3:0] a_low, b_low, a_high, b_high;
    reg [3:0] sum_low;
    reg carry;
    
    reg [7:0] a, b;
    reg s_axis_tlast_r, s_axis_tlast_r2;
    reg stage1_valid, stage2_valid, stage3_valid;
    
    // Pipeline registers for breaking critical paths
    reg [3:0] a_high_pipe, b_high_pipe;
    reg carry_pipe;
    
    always @(posedge clk) begin
        if (s_axis_tvalid && s_axis_tready) begin
            a <= s_axis_tdata[15:8];
            b <= s_axis_tdata[7:0];
            s_axis_tlast_r <= s_axis_tlast;
            stage1_valid <= 1'b1;
        end else if (stage1_valid && !stage2_valid) begin
            stage1_valid <= 1'b0;
        end
    end
    
    always @(posedge clk) begin
        // Stage 1: Compute lower 4 bits
        if (stage1_valid) begin
            {carry, sum_low} <= a[3:0] + b[3:0];
            a_high <= a[7:4];
            b_high <= b[7:4];
            stage2_valid <= 1'b1;
        end else if (stage2_valid && !stage3_valid) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // Additional pipeline stage to break critical path
    always @(posedge clk) begin
        // Stage 2: Pipeline the high bits addition preparation
        if (stage2_valid) begin
            a_high_pipe <= a_high;
            b_high_pipe <= b_high;
            carry_pipe <= carry;
            s_axis_tlast_r2 <= s_axis_tlast_r;
            stage3_valid <= 1'b1;
        end else if (stage3_valid && m_axis_tready) begin
            stage3_valid <= 1'b0;
        end
    end
    
    always @(posedge clk) begin
        // Stage 3: Compute upper 4 bits and prepare output
        if (stage3_valid && m_axis_tready) begin
            m_axis_tdata[7:4] <= a_high_pipe + b_high_pipe + carry_pipe;
            m_axis_tdata[3:0] <= sum_low;
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= s_axis_tlast_r2;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end
    
    // Input ready logic
    always @(posedge clk) begin
        if (!s_axis_tready && !stage1_valid && !stage2_valid && !stage3_valid && !m_axis_tvalid)
            s_axis_tready <= 1'b1;
        else if (s_axis_tready && s_axis_tvalid)
            s_axis_tready <= 1'b0;
    end
endmodule