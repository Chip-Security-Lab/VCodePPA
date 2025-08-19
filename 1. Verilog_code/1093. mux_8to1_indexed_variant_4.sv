//SystemVerilog
// Top-level 8-to-1 multiplexer module with AXI-Stream interface
module mux_8to1_axis #(
    parameter integer AXIS_DATA_WIDTH = 8
)(
    input  wire                         axis_aclk,
    input  wire                         axis_aresetn,

    input  wire [AXIS_DATA_WIDTH-1:0]   s_axis_tdata,    // 8 data inputs (packed)
    input  wire [2:0]                   s_axis_tuser,    // 3-bit selector
    input  wire                         s_axis_tvalid,
    output wire                         s_axis_tready,

    output reg  [0:0]                   m_axis_tdata,    // 1-bit output
    output reg                          m_axis_tvalid,
    input  wire                         m_axis_tready,
    output reg                          m_axis_tlast
);

    // AXI-Stream handshake
    reg s_ready_reg;
    assign s_axis_tready = s_ready_reg;

    // Internal signals for staged muxing
    reg [3:0] mux_stage1_out;
    reg [1:0] mux_stage2_out;
    reg       mux_final_out;

    // AXI-Stream handshake pipelined control
    always @(posedge axis_aclk) begin
        if (!axis_aresetn) begin
            m_axis_tvalid <= 1'b0;
            s_ready_reg   <= 1'b1;
            m_axis_tdata  <= 1'b0;
            m_axis_tlast  <= 1'b0;
        end else begin
            // Output handshake
            if (s_axis_tvalid && s_ready_reg && m_axis_tready) begin
                // First stage: four 2-to-1 multiplexers
                mux_stage1_out[0] <= s_axis_tuser[0] ? s_axis_tdata[1] : s_axis_tdata[0];
                mux_stage1_out[1] <= s_axis_tuser[0] ? s_axis_tdata[3] : s_axis_tdata[2];
                mux_stage1_out[2] <= s_axis_tuser[0] ? s_axis_tdata[5] : s_axis_tdata[4];
                mux_stage1_out[3] <= s_axis_tuser[0] ? s_axis_tdata[7] : s_axis_tdata[6];

                // Second stage: two 2-to-1 multiplexers
                mux_stage2_out[0] <= s_axis_tuser[1] ? mux_stage1_out[1] : mux_stage1_out[0];
                mux_stage2_out[1] <= s_axis_tuser[1] ? mux_stage1_out[3] : mux_stage1_out[2];

                // Third stage: one 2-to-1 multiplexer
                mux_final_out <= s_axis_tuser[2] ? mux_stage2_out[1] : mux_stage2_out[0];

                // Assign output
                m_axis_tdata  <= mux_final_out;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= 1'b1; // Single data per beat, TLAST always high
                s_ready_reg   <= 1'b0;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                s_ready_reg   <= 1'b1;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule