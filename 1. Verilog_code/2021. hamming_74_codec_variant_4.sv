//SystemVerilog
module hamming_74_codec_axi_stream #(
    parameter DATA_WIDTH = 4,
    parameter CODE_WIDTH = 7
)(
    input  wire                  clk,
    input  wire                  rst_n,
    // AXI-Stream Slave (Input) Interface
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,
    // AXI-Stream Master (Output) Interface
    output reg  [CODE_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast,   // Optional, set high when outputting a code word
    output reg                   error_flag      // Error flag output
);

    reg is_processing;
    reg [DATA_WIDTH-1:0] data_latched;

    // AXI-Stream handshake
    assign s_axis_tready = ~is_processing;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tdata   <= {CODE_WIDTH{1'b0}};
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;
            error_flag     <= 1'b0;
            is_processing  <= 1'b0;
            data_latched   <= {DATA_WIDTH{1'b0}};
        end else begin
            // Input handshake: capture input when ready and valid
            if (~is_processing & s_axis_tvalid & s_axis_tready) begin
                data_latched <= s_axis_tdata;
                is_processing <= 1'b1;
            end

            // Output handshake: drive output when processing is set and downstream is ready or not busy
            if (is_processing & (~m_axis_tvalid | (m_axis_tvalid & m_axis_tready))) begin
                // m_axis_tdata[6:4] <= data_latched[3:1];
                m_axis_tdata[6] <= data_latched[3];
                m_axis_tdata[5] <= data_latched[2];
                m_axis_tdata[4] <= data_latched[1];

                // m_axis_tdata[3] <= ^{data_latched[3:1], data_latched[0]};
                // ^{a, b, c, d} = a ^ b ^ c ^ d
                // Simplify using associativity and commutativity:
                // m_axis_tdata[3] <= data_latched[3] ^ data_latched[2] ^ data_latched[1] ^ data_latched[0];
                m_axis_tdata[3] <= data_latched[3] ^ data_latched[2] ^ data_latched[1] ^ data_latched[0];

                // m_axis_tdata[2] <= ^{data_latched[3], data_latched[1], data_latched[0]};
                // ^{a, b, c} = a ^ b ^ c
                m_axis_tdata[2] <= data_latched[3] ^ data_latched[1] ^ data_latched[0];

                // m_axis_tdata[1] <= ^{data_latched[3:2], data_latched[0]};
                // ^{a, b, c} = a ^ b ^ c
                m_axis_tdata[1] <= data_latched[3] ^ data_latched[2] ^ data_latched[0];

                // m_axis_tdata[0] <= ^{data_latched};
                // ^{a, b, c, d} = a ^ b ^ c ^ d
                m_axis_tdata[0] <= data_latched[3] ^ data_latched[2] ^ data_latched[1] ^ data_latched[0];

                m_axis_tvalid    <= 1'b1;
                m_axis_tlast     <= 1'b1;
                error_flag       <= 1'b0;
                is_processing    <= 1'b0;
            end else if (m_axis_tvalid & m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule