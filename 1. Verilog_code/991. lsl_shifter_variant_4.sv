//SystemVerilog
module lsl_shifter_axi_stream (
    input  wire         clk,
    input  wire         rst_n,
    // AXI-Stream slave (input) interface
    input  wire [7:0]   s_axis_tdata,
    input  wire [2:0]   s_axis_tshift_amt,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,
    // AXI-Stream master (output) interface
    output reg  [7:0]   m_axis_tdata,
    output reg          m_axis_tvalid,
    input  wire         m_axis_tready
);

    reg [7:0]   shifted_data_reg;
    reg         data_valid_reg;
    reg         load_data_reg;

    // Input handshake
    assign s_axis_tready = !data_valid_reg || (m_axis_tvalid && m_axis_tready);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shifted_data_reg <= 8'b0;
            data_valid_reg   <= 1'b0;
            load_data_reg    <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                shifted_data_reg <= s_axis_tdata << s_axis_tshift_amt;
                data_valid_reg   <= 1'b1;
                load_data_reg    <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                data_valid_reg   <= 1'b0;
                load_data_reg    <= 1'b0;
            end else begin
                load_data_reg    <= 1'b0;
            end
        end
    end

    // Output handshake and data logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata  <= 8'b0;
            m_axis_tvalid <= 1'b0;
        end else if (data_valid_reg && (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready))) begin
            m_axis_tdata  <= shifted_data_reg;
            m_axis_tvalid <= 1'b1;
        end else if (m_axis_tvalid && m_axis_tready) begin
            m_axis_tvalid <= 1'b0;
        end
    end

endmodule