//SystemVerilog
module reset_polarity_converter_axi_stream (
    input  wire        clk,
    input  wire        rst_n_in,
    // AXI-Stream output interface
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [0:0]  m_axis_tdata,
    output wire        m_axis_tlast
);
    reg [1:0]          sync_stages;
    reg                rst_sync_d;
    reg                data_valid_d;
    reg                data_sent_d;
    reg                tdata_reg;
    reg                tvalid_reg;

    // Synchronize and convert polarity as before
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in)
            sync_stages <= 2'b11;
        else
            sync_stages <= {sync_stages[0], 1'b0};
    end

    // Move registers before output logic for retiming
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in) begin
            rst_sync_d   <= 1'b1;
            data_valid_d <= 1'b0;
            data_sent_d  <= 1'b0;
        end else begin
            rst_sync_d <= sync_stages[1];
            // Assert tvalid when new data available and not sent
            if (!data_sent_d) begin
                data_valid_d <= 1'b1;
            end else if (tvalid_reg && m_axis_tready) begin
                data_valid_d <= 1'b0;
            end

            // Mark data as sent after handshake
            if (tvalid_reg && m_axis_tready) begin
                data_sent_d <= 1'b1;
            end else if (!data_valid_d) begin
                data_sent_d <= 1'b0;
            end
        end
    end

    // Register output signals, retimed before output
    always @(posedge clk or negedge rst_n_in) begin
        if (!rst_n_in) begin
            tdata_reg  <= 1'b1;
            tvalid_reg <= 1'b0;
        end else begin
            tdata_reg  <= rst_sync_d;
            tvalid_reg <= data_valid_d;
        end
    end

    assign m_axis_tdata  = tdata_reg;
    assign m_axis_tvalid = tvalid_reg;
    assign m_axis_tlast  = 1'b1; // Single transfer per reset event

endmodule