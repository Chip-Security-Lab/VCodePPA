//SystemVerilog
// Top-level hierarchical I2C multi-address slave module with AXI-Stream output
module i2c_multi_addr_slave_axi_stream (
    input  wire        clk,
    input  wire        rst,
    input  wire [6:0]  primary_addr,
    input  wire [6:0]  secondary_addr,
    // AXI-Stream Slave Output Interface
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast,
    // I2C Interface
    inout  wire        sda,
    inout  wire        scl
);

    // Internal interconnect wires
    wire        start_detected;
    wire [7:0]  addr_shift_reg;
    wire        addr_matched;
    wire        addr_ack;
    wire        sda_dir_addr, sda_out_addr;
    wire        sda_dir_data, sda_out_data;
    wire [7:0]  data_shift_reg;
    wire        data_valid;
    wire [2:0]  state;
    wire [3:0]  bit_idx_addr, bit_idx_data;

    // AXI-Stream handshake internal regs
    reg  [7:0]  axis_data_reg;
    reg         axis_valid_reg;
    reg         axis_last_reg;

    // SDA direction/output mux: only one submodule can drive SDA at a time
    wire        sda_dir;
    wire        sda_out;

    assign sda_dir = (state == 3'b001) ? sda_dir_addr : sda_dir_data;
    assign sda_out = (state == 3'b001) ? sda_out_addr : sda_out_data;

    assign sda = sda_dir ? sda_out : 1'bz;

    // AXI-Stream output assignments
    assign m_axis_tdata  = axis_data_reg;
    assign m_axis_tvalid = axis_valid_reg;
    assign m_axis_tlast  = axis_last_reg;

    // State machine
    i2c_slave_fsm u_i2c_slave_fsm (
        .clk                (clk),
        .rst                (rst),
        .start_detected     (start_detected),
        .addr_matched       (addr_matched),
        .data_valid         (data_valid),
        .state              (state)
    );

    // Start condition detector
    i2c_start_detector u_i2c_start_detector (
        .clk                (clk),
        .scl                (scl),
        .sda                (sda),
        .start_detected     (start_detected)
    );

    // Address reception and matching
    i2c_address_unit u_i2c_address_unit (
        .clk                (clk),
        .rst                (rst),
        .state              (state),
        .scl                (scl),
        .sda                (sda),
        .primary_addr       (primary_addr),
        .secondary_addr     (secondary_addr),
        .shift_reg          (addr_shift_reg),
        .bit_idx            (bit_idx_addr),
        .addr_matched       (addr_matched),
        .sda_dir            (sda_dir_addr),
        .sda_out            (sda_out_addr)
    );

    // Data reception
    wire [7:0]  rx_data_stream;
    wire        rx_valid_stream;
    wire        data_valid_stream;
    i2c_data_unit u_i2c_data_unit (
        .clk                (clk),
        .rst                (rst),
        .state              (state),
        .scl                (scl),
        .sda                (sda),
        .shift_reg          (data_shift_reg),
        .bit_idx            (bit_idx_data),
        .rx_data            (rx_data_stream),
        .rx_valid           (rx_valid_stream),
        .data_valid         (data_valid_stream),
        .sda_dir            (sda_dir_data),
        .sda_out            (sda_out_data)
    );

    // AXI-Stream handshake and buffering logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            axis_data_reg  <= 8'b0;
            axis_valid_reg <= 1'b0;
            axis_last_reg  <= 1'b0;
        end else begin
            // Default: keep tvalid until tready is asserted
            if (axis_valid_reg && m_axis_tready) begin
                axis_valid_reg <= 1'b0;
                axis_last_reg  <= 1'b0;
            end
            // Capture data when rx_valid_stream asserted and tready is high or tvalid is not asserted
            if (rx_valid_stream && (!axis_valid_reg || (axis_valid_reg && m_axis_tready))) begin
                axis_data_reg  <= rx_data_stream;
                axis_valid_reg <= 1'b1;
                axis_last_reg  <= 1'b1; // For I2C, each byte is treated as a packet (tlast=1)
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// I2C Start Condition Detector
// Detects the I2C start condition (SDA falling while SCL is high)
// -----------------------------------------------------------------------------
module i2c_start_detector (
    input  wire clk,
    input  wire scl,
    input  wire sda,
    output reg  start_detected
);
    reg scl_prev, sda_prev;

    always @(posedge clk) begin
        scl_prev  <= scl;
        sda_prev  <= sda;
        start_detected <= scl && scl_prev && ~sda && sda_prev;
    end
endmodule

// -----------------------------------------------------------------------------
// I2C Address Reception and Matching Unit
// Receives address byte, matches against primary and secondary address,
// and generates ACK if matched
// -----------------------------------------------------------------------------
module i2c_address_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] state,
    input  wire       scl,
    input  wire       sda,
    input  wire [6:0] primary_addr,
    input  wire [6:0] secondary_addr,
    output reg  [7:0] shift_reg,
    output reg  [3:0] bit_idx,
    output reg        addr_matched,
    output reg        sda_dir,
    output reg        sda_out
);
    localparam ADDR_SHIFT = 3'b001;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg    <= 8'h00;
            bit_idx      <= 4'b0000;
            addr_matched <= 1'b0;
            sda_dir      <= 1'b0;
            sda_out      <= 1'b0;
        end else begin
            if (state == ADDR_SHIFT) begin
                if (scl) begin
                    shift_reg <= {shift_reg[6:0], sda};
                    bit_idx   <= bit_idx + 1'b1;
                end
                if (bit_idx == 4'd7) begin
                    addr_matched <= (shift_reg[7:1] == primary_addr) ||
                                    (shift_reg[7:1] == secondary_addr);
                    sda_dir      <= (shift_reg[7:1] == primary_addr) ||
                                    (shift_reg[7:1] == secondary_addr); // ACK if address matched
                    sda_out      <= 1'b0;
                end
            end else begin
                bit_idx      <= 4'b0000;
                sda_dir      <= 1'b0;
                sda_out      <= 1'b0;
            end
            if (state != ADDR_SHIFT) begin
                addr_matched <= 1'b0;
                shift_reg    <= 8'h00;
                bit_idx      <= 4'b0000;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// I2C Data Reception Unit
// Receives data byte after address phase, asserts rx_valid when complete
// -----------------------------------------------------------------------------
module i2c_data_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [2:0] state,
    input  wire       scl,
    input  wire       sda,
    output reg  [7:0] shift_reg,
    output reg  [3:0] bit_idx,
    output reg  [7:0] rx_data,
    output reg        rx_valid,
    output reg        data_valid,
    output reg        sda_dir,
    output reg        sda_out
);
    localparam DATA_SHIFT = 3'b011;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'h00;
            bit_idx   <= 4'b0000;
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
            data_valid<= 1'b0;
            sda_dir   <= 1'b0;
            sda_out   <= 1'b0;
        end else begin
            rx_valid   <= 1'b0;
            data_valid <= 1'b0;
            sda_dir    <= 1'b0;
            sda_out    <= 1'b0;
            if (state == DATA_SHIFT) begin
                if (scl) begin
                    shift_reg <= {shift_reg[6:0], sda};
                    bit_idx   <= bit_idx + 1'b1;
                end
                if (bit_idx == 4'd7) begin
                    rx_data   <= shift_reg;
                    rx_valid  <= 1'b1;
                    data_valid<= 1'b1;
                end
            end else begin
                shift_reg <= 8'h00;
                bit_idx   <= 4'b0000;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// I2C Slave State Machine
// Controls the overall I2C slave operation
// -----------------------------------------------------------------------------
module i2c_slave_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_detected,
    input  wire        addr_matched,
    input  wire        data_valid,
    output reg  [2:0]  state
);
    localparam IDLE        = 3'b000;
    localparam ADDR_SHIFT  = 3'b001;
    localparam ADDR_ACK    = 3'b010;
    localparam DATA_SHIFT  = 3'b011;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE:
                    if (start_detected)
                        state <= ADDR_SHIFT;
                ADDR_SHIFT:
                    if (addr_matched)
                        state <= ADDR_ACK;
                    else
                        state <= IDLE;
                ADDR_ACK:
                    state <= DATA_SHIFT;
                DATA_SHIFT:
                    if (data_valid)
                        state <= IDLE;
                default:
                    state <= IDLE;
            endcase
        end
    end
endmodule