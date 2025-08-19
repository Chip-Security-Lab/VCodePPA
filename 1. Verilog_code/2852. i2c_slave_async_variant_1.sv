//SystemVerilog
module i2c_slave_async_axi_stream #(
    parameter ADDR_WIDTH = 7,
    parameter DATA_WIDTH = 8
)(
    input wire                       clk,
    input wire                       rst_n,
    input wire [ADDR_WIDTH-1:0]      device_addr,
    inout wire                       sda,
    inout wire                       scl,

    // AXI-Stream Slave Out (Master to downstream logic)
    output reg  [DATA_WIDTH-1:0]     m_axis_tdata,
    output reg                       m_axis_tvalid,
    input  wire                      m_axis_tready,
    output reg                       m_axis_tlast
);

    // Internal signals
    reg [ADDR_WIDTH-1:0] addr_buffer;
    reg [DATA_WIDTH-1:0] data_buffer;
    reg [3:0]            bit_count;
    reg                  addr_match, receiving;
    reg                  scl_prev, sda_prev;
    wire                 scl_wire, sda_wire;

    assign scl_wire = scl;
    assign sda_wire = sda;

    // Detect SCL/SDA edges
    wire scl_falling = (scl_prev && !scl_wire);
    wire scl_rising  = (!scl_prev && scl_wire);

    // Detect START/STOP condition
    wire start_condition = (sda_prev && !sda_wire && scl_wire);
    wire stop_condition  = (!sda_prev && sda_wire && scl_wire);

    // Synchronize SCL/SDA for edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
        end else begin
            scl_prev <= scl_wire;
            sda_prev <= sda_wire;
        end
    end

    // 4-bit Borrow Lookahead Subtractor module
    function [4:0] bls4_subtract;
        input [3:0] minuend;
        input [3:0] subtrahend;
        input       bin;
        reg   [3:0] p, g;
        reg   [4:0] borrow;
        reg   [3:0] diff;
        integer i;
        begin
            // Propagate and generate
            for (i = 0; i < 4; i = i + 1) begin
                p[i] = minuend[i] ^ subtrahend[i];
                g[i] = (~minuend[i]) & subtrahend[i];
            end
            borrow[0] = bin;
            borrow[1] = g[0] | (p[0] & borrow[0]);
            borrow[2] = g[1] | (p[1] & borrow[1]);
            borrow[3] = g[2] | (p[2] & borrow[2]);
            borrow[4] = g[3] | (p[3] & borrow[3]);
            for (i = 0; i < 4; i = i + 1) begin
                diff[i] = p[i] ^ borrow[i];
            end
            bls4_subtract = {borrow[4], diff};
        end
    endfunction

    // Address compare using 4-bit Borrow Lookahead Subtractor
    function addr_bls_equal;
        input [ADDR_WIDTH-1:0] addr_a;
        input [ADDR_WIDTH-1:0] addr_b;
        reg [4:0] bls_out0, bls_out1;
        reg [ADDR_WIDTH-1:0] diff;
        begin
            if (ADDR_WIDTH <= 4) begin
                bls_out0 = bls4_subtract(addr_a[3:0], addr_b[3:0], 1'b0);
                diff = bls_out0[3:0];
                addr_bls_equal = (diff == 0);
            end else begin
                bls_out0 = bls4_subtract(addr_a[3:0], addr_b[3:0], 1'b0);
                bls_out1 = bls4_subtract(addr_a[ADDR_WIDTH-1:4], addr_b[ADDR_WIDTH-1:4], bls_out0[4]);
                diff = {bls_out1[3:0], bls_out0[3:0]};
                addr_bls_equal = (diff == 0);
            end
        end
    endfunction

    // I2C slave FSM for address and data reception
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_buffer      <= {ADDR_WIDTH{1'b0}};
            data_buffer      <= {DATA_WIDTH{1'b0}};
            bit_count        <= 4'd0;
            addr_match       <= 1'b0;
            receiving        <= 1'b0;
            m_axis_tdata     <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid    <= 1'b0;
            m_axis_tlast     <= 1'b0;
        end else begin
            // START condition detected
            if (start_condition) begin
                bit_count     <= 4'd0;
                addr_match    <= 1'b0;
                receiving     <= 1'b1;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
            // STOP condition detected
            else if (stop_condition) begin
                receiving     <= 1'b0;
                addr_match    <= 1'b0;
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
            // Data reception on SCL rising edge
            else if (receiving && scl_rising) begin
                if (!addr_match) begin
                    // Address phase
                    addr_buffer[ADDR_WIDTH-1-bit_count] <= sda_wire;
                    bit_count <= bit_count + 4'd1;
                    if (bit_count == (ADDR_WIDTH-1)) begin
                        // Address compare using borrow lookahead subtractor
                        if (addr_bls_equal({addr_buffer[ADDR_WIDTH-2:0], sda_wire}, device_addr)) begin
                            addr_match <= 1'b1;
                        end else begin
                            addr_match <= 1'b0;
                            receiving  <= 1'b0;
                        end
                        bit_count <= 4'd0;
                    end
                end else begin
                    // Data phase
                    data_buffer[DATA_WIDTH-1-bit_count] <= sda_wire;
                    bit_count <= bit_count + 4'd1;
                    if (bit_count == (DATA_WIDTH-1)) begin
                        // Data byte received, assert TVALID
                        m_axis_tdata  <= {data_buffer[DATA_WIDTH-2:0], sda_wire};
                        m_axis_tvalid <= 1'b1;
                        m_axis_tlast  <= 1'b1;
                        bit_count     <= 4'd0;
                    end else begin
                        m_axis_tvalid <= 1'b0;
                        m_axis_tlast  <= 1'b0;
                    end
                end
            end
            // AXI-Stream handshake
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end
        end
    end

endmodule