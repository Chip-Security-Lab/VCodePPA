//SystemVerilog
module demux_axi_stream (
    input  wire         clk,             // Clock signal
    input  wire         rst_n,           // Active-low async reset
    input  wire         s_axis_tvalid,   // AXI-Stream TVALID (input valid)
    output wire         s_axis_tready,   // AXI-Stream TREADY (input ready)
    input  wire         s_axis_tdata,    // AXI-Stream TDATA (input data, 1 bit)
    input  wire [2:0]   s_axis_tdest,    // AXI-Stream TDEST (channel selection)
    output reg          m_axis_tvalid,   // AXI-Stream TVALID (output valid)
    input  wire         m_axis_tready,   // AXI-Stream TREADY (output ready)
    output reg  [7:0]   m_axis_tdata,    // AXI-Stream TDATA (output data, 8 bits, one-hot)
    output reg  [2:0]   m_axis_tdest,    // AXI-Stream TDEST (output channel)
    output reg          m_axis_tlast     // AXI-Stream TLAST (optional, set for single transfer)
);

// Internal pipeline registers
reg         tvalid_stage1;
reg         tdata_stage1;
reg  [2:0]  tdest_stage1;
reg  [7:0]  one_hot_stage1;

reg         tvalid_stage2;
reg  [7:0]  tdata_stage2;
reg  [2:0]  tdest_stage2;
reg         tlast_stage2;

// AXI-Stream input handshake
assign s_axis_tready = !tvalid_stage1 || (tvalid_stage2 && m_axis_tready);

// Stage 1: Input capture and one-hot encoding
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tvalid_stage1   <= 1'b0;
        tdata_stage1    <= 1'b0;
        tdest_stage1    <= 3'b000;
        one_hot_stage1  <= 8'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
        tvalid_stage1   <= 1'b1;
        tdata_stage1    <= s_axis_tdata;
        tdest_stage1    <= s_axis_tdest;
        one_hot_stage1  <= 8'b1 << s_axis_tdest;
    end else if (tvalid_stage2 && m_axis_tready) begin
        tvalid_stage1   <= 1'b0;
    end
end

// Stage 2: Output preparation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tvalid_stage2   <= 1'b0;
        tdata_stage2    <= 8'b0;
        tdest_stage2    <= 3'b000;
        tlast_stage2    <= 1'b0;
    end else if (tvalid_stage1 && (!tvalid_stage2 || (tvalid_stage2 && m_axis_tready))) begin
        tvalid_stage2   <= tvalid_stage1;
        tdata_stage2    <= tdata_stage1 ? one_hot_stage1 : 8'b0;
        tdest_stage2    <= tdest_stage1;
        tlast_stage2    <= 1'b1;
    end else if (tvalid_stage2 && m_axis_tready) begin
        tvalid_stage2   <= 1'b0;
        tlast_stage2    <= 1'b0;
    end
end

// AXI-Stream output assignments
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        m_axis_tvalid   <= 1'b0;
        m_axis_tdata    <= 8'b0;
        m_axis_tdest    <= 3'b000;
        m_axis_tlast    <= 1'b0;
    end else begin
        m_axis_tvalid   <= tvalid_stage2;
        m_axis_tdata    <= tdata_stage2;
        m_axis_tdest    <= tdest_stage2;
        m_axis_tlast    <= tlast_stage2;
    end
end

endmodule