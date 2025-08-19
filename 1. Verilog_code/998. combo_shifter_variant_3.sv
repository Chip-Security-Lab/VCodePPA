//SystemVerilog
module combo_shifter_axi_stream #(
    parameter DATA_WIDTH = 16
)(
    input  wire                   aclk,
    input  wire                   aresetn,
    // AXI-Stream Slave Interface
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire [3:0]             s_axis_tuser_shift_val,
    input  wire [1:0]             s_axis_tuser_op_mode, // 00:LSL, 01:LSR, 10:ASR, 11:ROR
    input  wire                   s_axis_tvalid,
    output wire                   s_axis_tready,
    // AXI-Stream Master Interface
    output reg  [DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                    m_axis_tvalid,
    input  wire                   m_axis_tready,
    output reg                    m_axis_tlast
);

    // Internal registers to hold input data
    reg [DATA_WIDTH-1:0]  data_reg_int;
    reg [3:0]             shift_val_reg_int;
    reg [1:0]             op_mode_reg_int;
    reg                   data_valid_reg_int;

    // Buffered registers for high fanout signals
    reg [DATA_WIDTH-1:0]  data_reg_buf1;
    reg [DATA_WIDTH-1:0]  data_reg_buf2;
    reg [3:0]             shift_val_reg_buf1;
    reg [3:0]             shift_val_reg_buf2;
    reg                   data_valid_reg_buf1;
    reg                   data_valid_reg_buf2;

    // AXI handshake for input
    assign s_axis_tready = ~data_valid_reg_int;

    // Register input signals
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_reg_int       <= {DATA_WIDTH{1'b0}};
            shift_val_reg_int  <= 4'b0;
            op_mode_reg_int    <= 2'b0;
            data_valid_reg_int <= 1'b0;
        end else begin
            if (s_axis_tvalid && s_axis_tready) begin
                data_reg_int       <= s_axis_tdata;
                shift_val_reg_int  <= s_axis_tuser_shift_val;
                op_mode_reg_int    <= s_axis_tuser_op_mode;
                data_valid_reg_int <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                data_valid_reg_int <= 1'b0;
            end
        end
    end

    // Buffering high fanout data_reg and shift_val_reg, data_valid_reg
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_reg_buf1       <= {DATA_WIDTH{1'b0}};
            data_reg_buf2       <= {DATA_WIDTH{1'b0}};
            shift_val_reg_buf1  <= 4'b0;
            shift_val_reg_buf2  <= 4'b0;
            data_valid_reg_buf1 <= 1'b0;
            data_valid_reg_buf2 <= 1'b0;
        end else begin
            data_reg_buf1       <= data_reg_int;
            data_reg_buf2       <= data_reg_buf1;
            shift_val_reg_buf1  <= shift_val_reg_int;
            shift_val_reg_buf2  <= shift_val_reg_buf1;
            data_valid_reg_buf1 <= data_valid_reg_int;
            data_valid_reg_buf2 <= data_valid_reg_buf1;
        end
    end

    // Buffer for op_mode_reg (not high fanout, but for timing consistency)
    reg [1:0] op_mode_reg_buf;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            op_mode_reg_buf <= 2'b0;
        end else begin
            op_mode_reg_buf <= op_mode_reg_int;
        end
    end

    // Combinational logic for shifting operation
    reg [DATA_WIDTH-1:0] result_comb_int;
    always @(*) begin
        case (op_mode_reg_buf)
            2'b00: result_comb_int = data_reg_buf2 << shift_val_reg_buf2;
            2'b01: result_comb_int = data_reg_buf2 >> shift_val_reg_buf2;
            2'b10: result_comb_int = $signed(data_reg_buf2) >>> shift_val_reg_buf2;
            2'b11: result_comb_int = (data_reg_buf2 >> shift_val_reg_buf2) | (data_reg_buf2 << (DATA_WIDTH-shift_val_reg_buf2));
            default: result_comb_int = {DATA_WIDTH{1'b0}};
        endcase
    end

    // Buffering high fanout result_comb signal (multi-stage if needed)
    reg [DATA_WIDTH-1:0] result_comb_buf1;
    reg [DATA_WIDTH-1:0] result_comb_buf2;
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            result_comb_buf1 <= {DATA_WIDTH{1'b0}};
            result_comb_buf2 <= {DATA_WIDTH{1'b0}};
        end else begin
            result_comb_buf1 <= result_comb_int;
            result_comb_buf2 <= result_comb_buf1;
        end
    end

    // Buffering high fanout m_axis_tlast signal
    reg m_axis_tlast_buf1;
    reg m_axis_tlast_buf2;

    // Output AXI-Stream logic with buffered signals
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tdata      <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid     <= 1'b0;
            m_axis_tlast      <= 1'b0;
            m_axis_tlast_buf1 <= 1'b0;
            m_axis_tlast_buf2 <= 1'b0;
        end else begin
            if (data_valid_reg_buf2 && ~m_axis_tvalid) begin
                m_axis_tdata      <= result_comb_buf2;
                m_axis_tvalid     <= 1'b1;
                m_axis_tlast_buf1 <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid     <= 1'b0;
                m_axis_tlast_buf1 <= 1'b0;
            end

            // Buffer m_axis_tlast for high fanout
            m_axis_tlast_buf2 <= m_axis_tlast_buf1;
            m_axis_tlast      <= m_axis_tlast_buf2;
        end
    end

endmodule