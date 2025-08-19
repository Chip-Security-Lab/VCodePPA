//SystemVerilog
module i2c_master_basic_valid_ready(
    input         clk,
    input         rst_n,
    input  [7:0]  tx_data,
    input         tx_valid,
    output        tx_ready,
    output reg [7:0] rx_data,
    output        rx_valid,
    input         rx_ready,
    output reg    busy,
    inout         sda,
    inout         scl
);

    //==========================================================================
    // State Machine Definitions
    //==========================================================================
    localparam [2:0] ST_IDLE       = 3'b000;
    localparam [2:0] ST_START      = 3'b001;
    localparam [2:0] ST_BIT_LOAD   = 3'b010;
    localparam [2:0] ST_BIT_SHIFT  = 3'b011;
    localparam [2:0] ST_STOP       = 3'b100;
    // ... (other states as needed)

    //==========================================================================
    // Pipeline Stage 1: State & Control Registers
    //==========================================================================

    reg  [2:0] state_stage1_q, state_stage1_d;
    reg        sda_oen_stage1_q, sda_oen_stage1_d;
    reg  [3:0] bit_cnt_stage1_q, bit_cnt_stage1_d;
    reg  [7:0] tx_shift_reg_stage1_q, tx_shift_reg_stage1_d;

    //==========================================================================
    // Pipeline Stage 2: Output Control Registers (sda/scl)
    //==========================================================================

    reg        sda_out_stage2_q, sda_out_stage2_d;
    reg        scl_out_stage2_q, scl_out_stage2_d;

    //==========================================================================
    // Valid-Ready handshake signals and internal strobes
    //==========================================================================

    reg        tx_handshake;
    reg        rx_handshake;
    reg        tx_ready_reg;
    reg        rx_valid_reg;
    reg  [7:0] rx_data_reg;
    reg        rx_data_pending;

    assign tx_ready = tx_ready_reg;
    assign rx_valid = rx_valid_reg;

    //==========================================================================
    // SDA/SCL I/O Buffer Control
    //==========================================================================

    assign scl = scl_out_stage2_q ? 1'bz : 1'b0;
    assign sda = sda_oen_stage1_q ? 1'bz : sda_out_stage2_q;

    //==========================================================================
    // Combinational Logic: Next-State and Control Signal Calculations
    //==========================================================================

    always @* begin
        // Default assignments
        state_stage1_d      = state_stage1_q;
        sda_oen_stage1_d    = sda_oen_stage1_q;
        bit_cnt_stage1_d    = bit_cnt_stage1_q;
        tx_shift_reg_stage1_d = tx_shift_reg_stage1_q;

        sda_out_stage2_d    = sda_out_stage2_q;
        scl_out_stage2_d    = scl_out_stage2_q;

        tx_handshake        = 1'b0;
        rx_handshake        = 1'b0;

        tx_ready_reg        = 1'b0;

        case (state_stage1_q)
            ST_IDLE: begin
                tx_ready_reg = 1'b1;
                if (tx_valid) begin
                    tx_handshake        = 1'b1;
                    state_stage1_d      = ST_START;
                    sda_oen_stage1_d    = 1'b0; // drive SDA low for START
                    scl_out_stage2_d    = 1'b1; // SCL high
                end
            end

            ST_START: begin
                state_stage1_d      = ST_BIT_LOAD;
                sda_oen_stage1_d    = 1'b0; // keep SDA low
                scl_out_stage2_d    = 1'b1; // SCL high
            end

            ST_BIT_LOAD: begin
                tx_shift_reg_stage1_d = tx_data;
                bit_cnt_stage1_d      = 4'd7;
                state_stage1_d        = ST_BIT_SHIFT;
                sda_oen_stage1_d      = 1'b0;
                scl_out_stage2_d      = 1'b0; // Prepare for data bit transmission
            end

            ST_BIT_SHIFT: begin
                sda_out_stage2_d      = tx_shift_reg_stage1_q[bit_cnt_stage1_q];
                scl_out_stage2_d      = 1'b0;
                if (bit_cnt_stage1_q == 0) begin
                    state_stage1_d    = ST_STOP;
                end else begin
                    bit_cnt_stage1_d  = bit_cnt_stage1_q - 1'b1;
                end
            end

            ST_STOP: begin
                sda_oen_stage1_d    = 1'b1; // Release SDA
                scl_out_stage2_d    = 1'b1; // SCL high
                state_stage1_d      = ST_IDLE;
                // For RX valid generation (if RX operation is implemented)
                // rx_handshake        = 1'b1;
            end

            default: begin
                // Defaults already set
            end
        endcase
    end

    //==========================================================================
    // Pipeline Register Stage 1: State/Control
    //==========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1_q        <= ST_IDLE;
            sda_oen_stage1_q      <= 1'b1;
            bit_cnt_stage1_q      <= 4'd0;
            tx_shift_reg_stage1_q <= 8'd0;
        end else begin
            state_stage1_q        <= state_stage1_d;
            sda_oen_stage1_q      <= sda_oen_stage1_d;
            bit_cnt_stage1_q      <= bit_cnt_stage1_d;
            tx_shift_reg_stage1_q <= tx_shift_reg_stage1_d;
        end
    end

    //==========================================================================
    // Pipeline Register Stage 2: Output Control (sda/scl)
    //==========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_stage2_q <= 1'b1;
            scl_out_stage2_q <= 1'b1;
        end else begin
            sda_out_stage2_q <= sda_out_stage2_d;
            scl_out_stage2_q <= scl_out_stage2_d;
        end
    end

    //==========================================================================
    // Busy Signal Generation (Registered)
    //==========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
        end else begin
            if ((state_stage1_q == ST_IDLE) && tx_handshake)
                busy <= 1'b1;
            else if ((state_stage1_q == ST_IDLE) && !tx_handshake)
                busy <= 1'b0;
            else if (state_stage1_q == ST_STOP)
                busy <= 1'b0;
        end
    end

    //==========================================================================
    // RX Data Capture with Valid-Ready handshake (Placeholder)
    //==========================================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data_reg    <= 8'd0;
            rx_valid_reg   <= 1'b0;
            rx_data_pending <= 1'b0;
        end else begin
            // If you implement RX logic, set rx_data_reg and rx_data_pending when new data is available
            // For now, only handshaking logic is implemented as a placeholder
            if (rx_data_pending && rx_ready) begin
                rx_valid_reg    <= 1'b0;
                rx_data_pending <= 1'b0;
            end else if (rx_data_pending) begin
                rx_valid_reg    <= 1'b1;
            end else begin
                rx_valid_reg    <= 1'b0;
            end
        end
    end

    always @(*) begin
        rx_data = rx_data_reg;
    end

endmodule