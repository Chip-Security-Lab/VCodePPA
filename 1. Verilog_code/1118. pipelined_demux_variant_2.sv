//SystemVerilog
module pipelined_demux_axi_stream #(
    parameter DATA_WIDTH = 4
)(
    input  wire                  aclk,          // AXI-Stream clock
    input  wire                  aresetn,       // Active-low synchronous reset

    // AXI-Stream Slave Interface (Input)
    input  wire                  s_axis_tvalid, // Input TVALID
    output wire                  s_axis_tready, // Input TREADY
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,  // Input TDATA (4 bits)
    input  wire [1:0]            s_axis_tdest,  // Input TDEST (2 bits for address)

    // AXI-Stream Master Interface (Output)
    output wire                  m_axis_tvalid, // Output TVALID
    input  wire                  m_axis_tready, // Output TREADY
    output wire [DATA_WIDTH-1:0] m_axis_tdata,  // Output TDATA (4 bits, one-hot demux)
    output wire [1:0]            m_axis_tdest   // Output TDEST (address)
);

    // Internal pipeline registers for buffering high-fanout signals
    reg                  data_valid_pipe_reg;
    reg [DATA_WIDTH-1:0] data_pipe_reg;
    reg [1:0]            addr_pipe_reg;

    // First-stage buffering for high-fanout signals
    reg                  data_valid_buf1;
    reg [DATA_WIDTH-1:0] data_pipe_buf1;
    reg [1:0]            addr_pipe_buf1;

    // Second-stage buffering for high-fanout signals
    reg                  data_valid_buf2;
    reg [DATA_WIDTH-1:0] data_pipe_buf2;
    reg [1:0]            addr_pipe_buf2;

    // Output buffers for high-fanout signals
    reg                  m_axis_tvalid_buf;
    reg [DATA_WIDTH-1:0] m_axis_tdata_buf;
    reg [1:0]            m_axis_tdest_buf;

    // Assign outputs from output buffers
    assign m_axis_tvalid = m_axis_tvalid_buf;
    assign m_axis_tdata  = m_axis_tdata_buf;
    assign m_axis_tdest  = m_axis_tdest_buf;

    // AXI-Stream handshake for input (buffered)
    assign s_axis_tready = !data_valid_pipe_reg || (m_axis_tready && m_axis_tvalid_buf);

    // First pipeline stage: capture input
    always @(posedge aclk) begin
        if (!aresetn) begin
            data_valid_pipe_reg <= 1'b0;
            data_pipe_reg       <= {DATA_WIDTH{1'b0}};
            addr_pipe_reg       <= 2'b00;
        end else if (s_axis_tready && s_axis_tvalid) begin
            data_valid_pipe_reg <= 1'b1;
            data_pipe_reg       <= s_axis_tdata;
            addr_pipe_reg       <= s_axis_tdest;
        end else if (m_axis_tvalid_buf && m_axis_tready) begin
            data_valid_pipe_reg <= 1'b0;
        end
    end

    // Second pipeline stage: buffer high-fanout signals
    always @(posedge aclk) begin
        if (!aresetn) begin
            data_valid_buf1 <= 1'b0;
            data_pipe_buf1  <= {DATA_WIDTH{1'b0}};
            addr_pipe_buf1  <= 2'b00;
        end else begin
            data_valid_buf1 <= data_valid_pipe_reg;
            data_pipe_buf1  <= data_pipe_reg;
            addr_pipe_buf1  <= addr_pipe_reg;
        end
    end

    // Third pipeline stage: further buffer high-fanout signals
    always @(posedge aclk) begin
        if (!aresetn) begin
            data_valid_buf2 <= 1'b0;
            data_pipe_buf2  <= {DATA_WIDTH{1'b0}};
            addr_pipe_buf2  <= 2'b00;
        end else begin
            data_valid_buf2 <= data_valid_buf1;
            data_pipe_buf2  <= data_pipe_buf1;
            addr_pipe_buf2  <= addr_pipe_buf1;
        end
    end

    // Output stage: drive output buffers with balanced fanout
    always @(posedge aclk) begin
        if (!aresetn) begin
            m_axis_tvalid_buf <= 1'b0;
            m_axis_tdata_buf  <= {DATA_WIDTH{1'b0}};
            m_axis_tdest_buf  <= 2'b00;
        end else begin
            if (data_valid_buf2 && (!m_axis_tvalid_buf || (m_axis_tvalid_buf && m_axis_tready))) begin
                m_axis_tvalid_buf <= 1'b1;
                m_axis_tdata_buf  <= {DATA_WIDTH{1'b0}};
                m_axis_tdata_buf[addr_pipe_buf2] <= data_pipe_buf2[addr_pipe_buf2];
                m_axis_tdest_buf  <= addr_pipe_buf2;
            end else if (m_axis_tvalid_buf && m_axis_tready) begin
                m_axis_tvalid_buf <= 1'b0;
            end
        end
    end

endmodule