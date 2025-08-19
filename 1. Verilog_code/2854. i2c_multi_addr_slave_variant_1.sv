//SystemVerilog
// Top-level module: Hierarchical I2C multi-address slave

module i2c_multi_addr_slave (
    input  wire        clk,
    input  wire        rst,
    input  wire [6:0]  primary_addr,
    input  wire [6:0]  secondary_addr,
    output wire [7:0]  rx_data,
    output wire        rx_valid,
    inout  wire        sda,
    inout  wire        scl
);

    // Internal signals
    wire        start_detected;
    wire [7:0]  addr_shift_reg;
    wire [7:0]  data_shift_reg;
    wire [3:0]  bit_index;
    wire        addr_match;
    wire        sda_dir_ctrl;
    wire        sda_out_ctrl;
    wire        rx_valid_int;
    wire [7:0]  rx_data_int;

    // SDA direction and output signals
    wire        sda_internal;
    assign sda = sda_dir_ctrl ? sda_out_ctrl : 1'bz;
    assign sda_internal = sda;

    // Start Condition Detector
    i2c_start_detector u_start_detector (
        .clk             (clk),
        .rst             (rst),
        .scl             (scl),
        .sda             (sda_internal),
        .start_detected  (start_detected)
    );

    // Shift Register and Bit Counter
    i2c_shift_register u_shift_register (
        .clk             (clk),
        .rst             (rst),
        .sda             (sda_internal),
        .scl             (scl),
        .start_detected  (start_detected),
        .state           (fsm_state),
        .shift_reg_addr  (addr_shift_reg),
        .shift_reg_data  (data_shift_reg),
        .bit_idx         (bit_index)
    );

    // Address Comparator
    i2c_addr_compare u_addr_compare (
        .received_addr   (addr_shift_reg[7:1]),
        .primary_addr    (primary_addr),
        .secondary_addr  (secondary_addr),
        .addr_match      (addr_match)
    );

    // Main FSM
    wire [2:0] fsm_state;
    i2c_slave_fsm u_slave_fsm (
        .clk             (clk),
        .rst             (rst),
        .start_detected  (start_detected),
        .scl             (scl),
        .sda             (sda_internal),
        .addr_shift_reg  (addr_shift_reg),
        .data_shift_reg  (data_shift_reg),
        .bit_idx         (bit_index),
        .addr_match      (addr_match),
        .fsm_state       (fsm_state),
        .sda_dir         (sda_dir_ctrl),
        .sda_out         (sda_out_ctrl),
        .rx_data         (rx_data_int),
        .rx_valid        (rx_valid_int)
    );

    // Output assignments
    assign rx_data  = rx_data_int;
    assign rx_valid = rx_valid_int;

endmodule

// -----------------------------------------------------------------------------
// Start Condition Detector
// Detects I2C START condition on SDA/SCL lines
// -----------------------------------------------------------------------------
module i2c_start_detector (
    input  wire clk,
    input  wire rst,
    input  wire scl,
    input  wire sda,
    output reg  start_detected
);
    reg scl_prev, sda_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_prev        <= 1'b1;
            sda_prev        <= 1'b1;
            start_detected  <= 1'b0;
        end else begin
            scl_prev        <= scl;
            sda_prev        <= sda;
            start_detected  <= scl & scl_prev & ~sda & sda_prev;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Shift Register and Bit Counter
// Handles both address and data byte shifting
// -----------------------------------------------------------------------------
module i2c_shift_register (
    input  wire        clk,
    input  wire        rst,
    input  wire        sda,
    input  wire        scl,
    input  wire        start_detected,
    input  wire [2:0]  state,
    output reg  [7:0]  shift_reg_addr,
    output reg  [7:0]  shift_reg_data,
    output reg  [3:0]  bit_idx
);
    localparam STATE_IDLE    = 3'b000;
    localparam STATE_ADDR    = 3'b001;
    localparam STATE_ACK     = 3'b010;
    localparam STATE_DATA    = 3'b011;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg_addr <= 8'h00;
            shift_reg_data <= 8'h00;
            bit_idx        <= 4'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (start_detected) begin
                        shift_reg_addr <= 8'h00;
                        shift_reg_data <= shift_reg_data;
                        bit_idx        <= 4'd0;
                    end
                end
                STATE_ADDR: begin
                    if (scl) begin
                        shift_reg_addr <= {shift_reg_addr[6:0], sda};
                        bit_idx        <= bit_idx + 1'b1;
                    end
                end
                STATE_ACK: begin
                    // Keep values
                    shift_reg_addr <= shift_reg_addr;
                    shift_reg_data <= shift_reg_data;
                    bit_idx        <= 4'd0;
                end
                STATE_DATA: begin
                    if (scl) begin
                        shift_reg_data <= {shift_reg_data[6:0], sda};
                        bit_idx        <= bit_idx + 1'b1;
                    end
                end
                default: begin
                    // Hold
                end
            endcase
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Address Comparator
// Compares received address with primary and secondary addresses
// -----------------------------------------------------------------------------
module i2c_addr_compare (
    input  wire [6:0] received_addr,
    input  wire [6:0] primary_addr,
    input  wire [6:0] secondary_addr,
    output wire       addr_match
);
    assign addr_match = (received_addr == primary_addr) | (received_addr == secondary_addr);
endmodule

// -----------------------------------------------------------------------------
// I2C Slave FSM
// Controls the protocol state transitions, SDA direction, and output generation
// -----------------------------------------------------------------------------
module i2c_slave_fsm (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_detected,
    input  wire        scl,
    input  wire        sda,
    input  wire [7:0]  addr_shift_reg,
    input  wire [7:0]  data_shift_reg,
    input  wire [3:0]  bit_idx,
    input  wire        addr_match,
    output reg  [2:0]  fsm_state,
    output reg         sda_dir,
    output reg         sda_out,
    output reg  [7:0]  rx_data,
    output reg         rx_valid
);

    localparam STATE_IDLE    = 3'b000;
    localparam STATE_ADDR    = 3'b001;
    localparam STATE_ACK     = 3'b010;
    localparam STATE_DATA    = 3'b011;

    reg [2:0]  next_state;
    reg        sda_dir_next, sda_out_next;
    reg  [7:0] rx_data_next;
    reg        rx_valid_next;

    always @* begin
        // Defaults
        next_state      = fsm_state;
        sda_dir_next    = sda_dir;
        sda_out_next    = sda_out;
        rx_data_next    = rx_data;
        rx_valid_next   = 1'b0;

        case (fsm_state)
            STATE_IDLE: begin // Wait for START
                if (start_detected) begin
                    next_state      = STATE_ADDR;
                    sda_dir_next    = 1'b0;
                    sda_out_next    = 1'b0;
                end
            end

            STATE_ADDR: begin // Receive address byte
                if (bit_idx == 4'd7) begin
                    if (addr_match) begin
                        next_state      = STATE_ACK;
                        sda_dir_next    = 1'b1; // Drive SDA for ACK
                        sda_out_next    = 1'b0; // ACK bit low
                    end else begin
                        next_state      = STATE_IDLE;
                        sda_dir_next    = 1'b0;
                        sda_out_next    = 1'b0;
                    end
                end
            end

            STATE_ACK: begin // ACK phase
                next_state      = STATE_DATA;
                sda_dir_next    = 1'b0; // Release SDA
                sda_out_next    = 1'b0;
            end

            STATE_DATA: begin // Receive data byte
                if (bit_idx == 4'd7) begin
                    rx_data_next    = data_shift_reg;
                    rx_valid_next   = 1'b1;
                    next_state      = STATE_IDLE;
                end
            end

            default: begin
                next_state      = STATE_IDLE;
                sda_dir_next    = 1'b0;
                sda_out_next    = 1'b0;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fsm_state   <= STATE_IDLE;
            sda_dir     <= 1'b0;
            sda_out     <= 1'b0;
            rx_data     <= 8'h00;
            rx_valid    <= 1'b0;
        end else begin
            fsm_state   <= next_state;
            sda_dir     <= sda_dir_next;
            sda_out     <= sda_out_next;
            rx_data     <= rx_data_next;
            rx_valid    <= rx_valid_next;
        end
    end

endmodule