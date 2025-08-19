//SystemVerilog
module hex2ascii_axi_stream #(
    parameter DATA_WIDTH = 8
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [3:0]             s_axis_tdata,
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tvalid,
    input  wire                   m_axis_tready,
    output reg                    m_axis_tlast
);

    // Forward retiming: move input register after combinational logic
    wire        handshake_ready;
    wire        output_enable;
    reg  [DATA_WIDTH-1:0] ascii_data_next;
    reg                   output_handshake;

    // Combinational logic for ASCII conversion
    always @(*) begin
        if (s_axis_tdata <= 4'h9)
            ascii_data_next = { {(DATA_WIDTH-8){1'b0}}, s_axis_tdata + 8'h30 }; // 0-9 to ASCII '0'-'9'
        else
            ascii_data_next = { {(DATA_WIDTH-8){1'b0}}, s_axis_tdata + 8'h37 }; // A-F to ASCII 'A'-'F'
    end

    assign handshake_ready = !output_handshake || (m_axis_tvalid && m_axis_tready);
    assign s_axis_tready   = handshake_ready;
    assign output_enable   = s_axis_tvalid && handshake_ready;

    // Output register after combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata      <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid     <= 1'b0;
            m_axis_tlast      <= 1'b0;
            output_handshake  <= 1'b0;
        end else begin
            if (output_enable) begin
                m_axis_tdata     <= ascii_data_next;
                m_axis_tvalid    <= 1'b1;
                m_axis_tlast     <= 1'b1;
                output_handshake <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid    <= 1'b0;
                m_axis_tlast     <= 1'b0;
                output_handshake <= 1'b0;
            end
        end
    end

endmodule