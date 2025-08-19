//SystemVerilog
module compact_axi_stream_slave (
    input wire clk,
    input wire rst_n,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [7:0] s_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tlast
);

    reg [7:0] rx_data_reg;
    reg rx_data_valid;
    reg rx_data_last;
    reg [7:0] tx_data_reg;
    reg tx_data_valid;
    reg [2:0] bit_count;
    reg tready_reg;
    reg tvalid_reg;
    reg tlast_reg;

    assign s_axis_tready = tready_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tdata  = tx_data_reg;
    assign m_axis_tlast  = tlast_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_reg   <= 8'b0;
            rx_data_valid <= 1'b0;
            rx_data_last  <= 1'b0;
            tx_data_reg   <= 8'b0;
            tx_data_valid <= 1'b0;
            bit_count     <= 3'b000;
            tready_reg    <= 1'b1;
            tvalid_reg    <= 1'b0;
            tlast_reg     <= 1'b0;
        end else begin
            // AXI-Stream slave receive
            if (s_axis_tvalid && s_axis_tready) begin
                rx_data_reg   <= s_axis_tdata;
                rx_data_valid <= 1'b1;
                rx_data_last  <= 1'b1; // Single byte packet for simplicity
                bit_count     <= 3'b000;
            end else begin
                rx_data_valid <= 1'b0;
                rx_data_last  <= 1'b0;
            end

            // Data ready to transmit on master AXI-Stream
            if (rx_data_valid) begin
                tx_data_reg   <= rx_data_reg;
                tx_data_valid <= 1'b1;
                tvalid_reg    <= 1'b1;
                tlast_reg     <= rx_data_last;
            end else if (m_axis_tvalid && m_axis_tready) begin
                tx_data_valid <= 1'b0;
                tvalid_reg    <= 1'b0;
                tlast_reg     <= 1'b0;
            end

            // tready logic (always ready to accept data if not currently transmitting)
            if (tx_data_valid && !m_axis_tready)
                tready_reg <= 1'b0;
            else
                tready_reg <= 1'b1;
        end
    end

endmodule