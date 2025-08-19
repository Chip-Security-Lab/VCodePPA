//SystemVerilog
module pipelined_demux_axi_stream (
    input wire clk,                                 // System clock
    input wire rst_n,                               // Active-low reset
    input wire s_axis_tvalid,                       // AXI-Stream TVALID input
    output wire s_axis_tready,                      // AXI-Stream TREADY output
    input wire [3:0] s_axis_tdata,                  // AXI-Stream TDATA input
    input wire s_axis_tlast,                        // AXI-Stream TLAST input
    output reg m_axis_tvalid,                       // AXI-Stream TVALID output
    input wire m_axis_tready,                       // AXI-Stream TREADY input
    output reg [3:0] m_axis_tdata,                  // AXI-Stream TDATA output
    output reg m_axis_tlast                         // AXI-Stream TLAST output
);

    reg [3:0] demux_data_reg;
    reg tvalid_reg;
    reg tlast_reg;

    assign s_axis_tready = m_axis_tready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            demux_data_reg <= 4'b0;
            tvalid_reg <= 1'b0;
            tlast_reg <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            demux_data_reg <= s_axis_tdata;
            tvalid_reg <= 1'b1;
            tlast_reg <= s_axis_tlast;
        end else if (m_axis_tvalid && m_axis_tready) begin
            tvalid_reg <= 1'b0;
            tlast_reg <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 4'b0;
            m_axis_tlast <= 1'b0;
        end else begin
            m_axis_tvalid <= tvalid_reg;
            m_axis_tdata <= demux_data_reg;
            m_axis_tlast <= tlast_reg;
        end
    end

endmodule