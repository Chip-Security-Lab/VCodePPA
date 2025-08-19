//SystemVerilog
// SystemVerilog
module ArrayOR_axi_stream (
    input wire aclk,
    input wire aresetn,

    // AXI Stream Input
    input wire [7:0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire s_axis_tlast,

    // AXI Stream Output
    output wire [7:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire m_axis_tlast
);

    // Internal signals
    logic [7:0]  processed_data;
    logic        data_valid;
    logic        last_data;

    // AXI Stream Handshake for Input
    assign s_axis_tready = m_axis_tready || ~m_axis_tvalid; // Ready when output can accept data

    // Data processing and registration
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            processed_data <= 8'h00;
            data_valid     <= 1'b0;
            last_data      <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                // Split the 8-bit input into two 4-bit values
                logic [3:0] row_in = s_axis_tdata[7:4];
                logic [3:0] col_in = s_axis_tdata[3:0];

                // Perform the OR operation
                processed_data <= {row_in, col_in} | 8'hAA;
                data_valid     <= 1'b1;
                last_data      <= s_axis_tlast;
            end else if (m_axis_tvalid && m_axis_tready) begin
                // Data has been consumed by the output
                data_valid <= 1'b0;
            end
        end
    end

    // AXI Stream Handshake for Output
    assign m_axis_tvalid = data_valid;
    assign m_axis_tdata  = processed_data;
    assign m_axis_tlast  = last_data;

endmodule