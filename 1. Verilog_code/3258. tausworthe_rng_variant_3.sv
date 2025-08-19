//SystemVerilog
module tausworthe_rng_axi_stream (
    input  wire        aclk,
    input  wire        aresetn,
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);
    reg [31:0] s1_reg, s2_reg, s3_reg;
    wire [31:0] b1_wire, b2_wire, b3_wire;
    reg         tvalid_reg;
    reg [31:0]  tdata_reg;

    assign b1_wire = ((s1_reg << 13) ^ s1_reg) >> 19;
    assign b2_wire = ((s2_reg << 2) ^ s2_reg) >> 25;
    assign b3_wire = ((s3_reg << 3) ^ s3_reg) >> 11;

    // AXI-Stream signals
    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = 1'b0; // Not used, always zero for continuous stream

    always @(posedge aclk) begin
        if (!aresetn) begin
            s1_reg     <= 32'h1;
            s2_reg     <= 32'h2;
            s3_reg     <= 32'h4;
            tdata_reg  <= 32'd0;
            tvalid_reg <= 1'b0;
        end else begin
            if (m_axis_tready || !tvalid_reg) begin
                s1_reg    <= (s1_reg & 32'hFFFFFFFE) ^ b1_wire;
                s2_reg    <= (s2_reg & 32'hFFFFFFF8) ^ b2_wire;
                s3_reg    <= (s3_reg & 32'hFFFFFFF0) ^ b3_wire;
                tdata_reg <= (s1_reg ^ s2_reg ^ s3_reg);
                tvalid_reg <= 1'b1;
            end else begin
                tvalid_reg <= tvalid_reg;
                tdata_reg  <= tdata_reg;
            end
        end
    end

endmodule