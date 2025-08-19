//SystemVerilog
module reset_interrupt_generator_axi_stream(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [5:0]   reset_sources,      // Active high
    input  wire [5:0]   interrupt_mask,     // 1=generate interrupt
    input  wire         interrupt_ack,
    output wire [5:0]   m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tlast
);

    reg  [5:0]  prev_sources;
    reg  [5:0]  pending_sources;
    wire [5:0]  new_resets;
    reg         tvalid_reg;
    reg  [5:0]  tdata_reg;
    reg         tlast_reg;
    reg  [5:0]  pending_sources_next;

    assign new_resets     = (reset_sources & ~prev_sources) & interrupt_mask;

    // AXI-Stream outputs
    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = tlast_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sources      <= 6'h00;
            pending_sources   <= 6'h00;
            tvalid_reg        <= 1'b0;
            tdata_reg         <= 6'h00;
            tlast_reg         <= 1'b0;
        end else begin
            prev_sources <= reset_sources;

            // Update pending_sources
            if (interrupt_ack && (pending_sources | new_resets) != 6'h00) begin
                pending_sources <= 6'h00;
            end else begin
                pending_sources <= pending_sources | new_resets;
            end

            // AXI-Stream TVALID/TREADY handshake
            if (tvalid_reg && m_axis_tready) begin
                tvalid_reg <= 1'b0;
            end

            // Generate a transfer if there is a pending interrupt
            if ((pending_sources | new_resets) != 6'h00 && (!tvalid_reg || (tvalid_reg && m_axis_tready))) begin
                tdata_reg   <= pending_sources | new_resets;
                tvalid_reg  <= 1'b1;
                tlast_reg   <= 1'b1; // Single transfer, set TLAST high
            end else if (!tvalid_reg) begin
                tdata_reg   <= 6'h00;
                tlast_reg   <= 1'b0;
            end
        end
    end

endmodule