//SystemVerilog
// Top-level I2C Master with Structured, Pipelined Data Path and Modular Control (Subtractor replaced by borrow subtractor)

module i2c_master_basic(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  tx_data,
    input  wire        start_trans,
    output reg  [7:0]  rx_data,
    output reg         busy,
    inout  wire        sda,
    inout  wire        scl
);

    // State encoding for FSM
    localparam [2:0] IDLE        = 3'b000,
                     START       = 3'b001,
                     LOAD        = 3'b010,
                     TRANSFER    = 3'b011,
                     RECEIVE     = 3'b100,
                     STOP        = 3'b101,
                     COMPLETE    = 3'b110;

    // Pipeline stage registers for each stage
    reg  [2:0] fsm_stage0, fsm_stage1, fsm_stage2;
    reg        start_stage0, start_stage1, start_stage2;
    reg  [7:0] tx_data_stage0, tx_data_stage1, tx_data_stage2;
    reg  [3:0] bit_cnt_stage0, bit_cnt_stage1, bit_cnt_stage2;
    reg        sda_drive_stage0, sda_drive_stage1, sda_drive_stage2;
    reg        scl_drive_stage0, scl_drive_stage1, scl_drive_stage2;
    reg        sda_oen_stage0, sda_oen_stage1, sda_oen_stage2;
    reg  [7:0] rx_data_stage0, rx_data_stage1, rx_data_stage2;

    // Output pipeline register for busy
    reg        busy_stage1, busy_stage2;

    // Internal signals for borrow subtractor
    wire [3:0] bit_cnt_stage0_next;
    wire       bit_cnt_borrow_out;

    // SCL/SDA tri-state control
    assign scl = scl_drive_stage2 ? 1'bz : 1'b0;
    assign sda = sda_oen_stage2 ? 1'bz : sda_drive_stage2;

    // Stage 0: FSM and Data Path Control (Pipeline Stage 1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_stage0         <= IDLE;
            start_stage0       <= 1'b0;
            tx_data_stage0     <= 8'b0;
            bit_cnt_stage0     <= 4'd0;
            sda_drive_stage0   <= 1'b1;
            scl_drive_stage0   <= 1'b1;
            sda_oen_stage0     <= 1'b1;
            rx_data_stage0     <= 8'b0;
            busy_stage1        <= 1'b0;
        end else begin
            // Latch input signals
            start_stage0     <= start_trans;
            tx_data_stage0   <= tx_data;

            case (fsm_stage0)
                IDLE: begin
                    busy_stage1      <= 1'b0;
                    sda_oen_stage0   <= 1'b1;
                    scl_drive_stage0 <= 1'b1;
                    sda_drive_stage0 <= 1'b1;
                    bit_cnt_stage0   <= 4'd7;
                    rx_data_stage0   <= 8'b0;
                    if (start_trans) begin
                        fsm_stage0   <= START;
                        busy_stage1  <= 1'b1;
                    end
                end

                START: begin
                    // Generate START condition
                    sda_oen_stage0   <= 1'b0;
                    sda_drive_stage0 <= 1'b0;
                    scl_drive_stage0 <= 1'b1;
                    fsm_stage0       <= LOAD;
                end

                LOAD: begin
                    // Prepare to transmit address/data
                    bit_cnt_stage0   <= 4'd7;
                    sda_oen_stage0   <= 1'b0;
                    sda_drive_stage0 <= tx_data_stage0[7];
                    scl_drive_stage0 <= 1'b0;
                    fsm_stage0       <= TRANSFER;
                end

                TRANSFER: begin
                    // Transmit address/data byte (bit-wise)
                    if (bit_cnt_stage0 > 0) begin
                        sda_drive_stage0 <= tx_data_stage0[bit_cnt_stage0-1];
                        bit_cnt_stage0   <= bit_cnt_stage0_next;
                    end else begin
                        sda_oen_stage0   <= 1'b1; // Release SDA for ACK
                        fsm_stage0       <= RECEIVE;
                    end
                end

                RECEIVE: begin
                    // Receive ACK/NACK or data
                    sda_oen_stage0     <= 1'b1;
                    rx_data_stage0[0]  <= sda;
                    fsm_stage0         <= STOP;
                end

                STOP: begin
                    // Generate STOP condition
                    sda_oen_stage0   <= 1'b0;
                    sda_drive_stage0 <= 1'b0;
                    scl_drive_stage0 <= 1'b1;
                    fsm_stage0       <= COMPLETE;
                end

                COMPLETE: begin
                    sda_drive_stage0 <= 1'b1;
                    sda_oen_stage0   <= 1'b1;
                    busy_stage1      <= 1'b0;
                    fsm_stage0       <= IDLE;
                end

                default: fsm_stage0 <= IDLE;
            endcase
        end
    end

    // 4-bit borrow subtractor: bit_cnt_stage0 - 1
    borrow_subtractor_4bit u_borrow_subtractor_4bit (
        .minuend    (bit_cnt_stage0),
        .subtrahend (4'd1),
        .diff       (bit_cnt_stage0_next),
        .borrow_out (bit_cnt_borrow_out)
    );

    // Stage 1: Pipeline Register (Pipeline Stage 2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_stage1         <= IDLE;
            start_stage1       <= 1'b0;
            tx_data_stage1     <= 8'b0;
            bit_cnt_stage1     <= 4'd0;
            sda_drive_stage1   <= 1'b1;
            scl_drive_stage1   <= 1'b1;
            sda_oen_stage1     <= 1'b1;
            rx_data_stage1     <= 8'b0;
            busy_stage2        <= 1'b0;
        end else begin
            fsm_stage1         <= fsm_stage0;
            start_stage1       <= start_stage0;
            tx_data_stage1     <= tx_data_stage0;
            bit_cnt_stage1     <= bit_cnt_stage0;
            sda_drive_stage1   <= sda_drive_stage0;
            scl_drive_stage1   <= scl_drive_stage0;
            sda_oen_stage1     <= sda_oen_stage0;
            rx_data_stage1     <= rx_data_stage0;
            busy_stage2        <= busy_stage1;
        end
    end

    // Stage 2: Pipeline Register (Pipeline Stage 3)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_stage2         <= IDLE;
            start_stage2       <= 1'b0;
            tx_data_stage2     <= 8'b0;
            bit_cnt_stage2     <= 4'd0;
            sda_drive_stage2   <= 1'b1;
            scl_drive_stage2   <= 1'b1;
            sda_oen_stage2     <= 1'b1;
            rx_data_stage2     <= 8'b0;
            busy               <= 1'b0;
        end else begin
            fsm_stage2         <= fsm_stage1;
            start_stage2       <= start_stage1;
            tx_data_stage2     <= tx_data_stage1;
            bit_cnt_stage2     <= bit_cnt_stage1;
            sda_drive_stage2   <= sda_drive_stage1;
            scl_drive_stage2   <= scl_drive_stage1;
            sda_oen_stage2     <= sda_oen_stage1;
            rx_data_stage2     <= rx_data_stage1;
            busy               <= busy_stage2;
        end
    end

    // Output register for rx_data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_data <= 8'b0;
        else if (fsm_stage2 == COMPLETE)
            rx_data <= rx_data_stage2;
    end

endmodule

// 4-bit Borrow Subtractor (minuend - subtrahend) with borrow_out, IEEE 1364-2005 Verilog
module borrow_subtractor_4bit (
    input  wire [3:0] minuend,
    input  wire [3:0] subtrahend,
    output wire [3:0] diff,
    output wire       borrow_out
);
    wire [3:0] borrow;

    // Bit 0
    assign diff[0]    = minuend[0] ^ subtrahend[0];
    assign borrow[0]  = (~minuend[0]) & subtrahend[0];

    // Bit 1
    assign diff[1]    = minuend[1] ^ subtrahend[1] ^ borrow[0];
    assign borrow[1]  = ((~minuend[1]) & subtrahend[1]) | ((~minuend[1]) & borrow[0]) | (subtrahend[1] & borrow[0]);

    // Bit 2
    assign diff[2]    = minuend[2] ^ subtrahend[2] ^ borrow[1];
    assign borrow[2]  = ((~minuend[2]) & subtrahend[2]) | ((~minuend[2]) & borrow[1]) | (subtrahend[2] & borrow[1]);

    // Bit 3
    assign diff[3]    = minuend[3] ^ subtrahend[3] ^ borrow[2];
    assign borrow[3]  = ((~minuend[3]) & subtrahend[3]) | ((~minuend[3]) & borrow[2]) | (subtrahend[3] & borrow[2]);

    assign borrow_out = borrow[3];
endmodule