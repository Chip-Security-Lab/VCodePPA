//SystemVerilog
//IEEE 1364-2005 Verilog
module i2c_burst_master(
    input  wire        clk,
    input  wire        rstn,
    input  wire        start,
    input  wire [6:0]  dev_addr,
    input  wire [7:0]  mem_addr,
    input  wire [7:0]  wdata[0:3],
    input  wire [1:0]  byte_count,
    output reg  [7:0]  rdata[0:3],
    output reg         busy,
    output reg         done,
    inout  wire        scl,
    inout  wire        sda
);

    // State encoding
    localparam IDLE         = 4'h0;
    localparam START_1      = 4'h1;
    localparam START_2      = 4'h2;
    localparam DEVADDR_1    = 4'h3;
    localparam DEVADDR_2    = 4'h4;
    localparam MEMADDR_1    = 4'h5;
    localparam MEMADDR_2    = 4'h6;
    localparam WRITE_1      = 4'h7;
    localparam WRITE_2      = 4'h8;
    localparam READ_1       = 4'h9;
    localparam READ_2       = 4'ha;
    localparam ACK_1        = 4'hb;
    localparam ACK_2        = 4'hc;
    localparam STOP_1       = 4'hd;
    localparam STOP_2       = 4'he;
    localparam DONE         = 4'hf;

    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3;
    reg flush_stage1, flush_stage2, flush_stage3;

    // Pipeline stage registers
    reg [3:0] state_stage1, state_stage2, state_stage3;
    reg [3:0] next_state_stage1, next_state_stage2, next_state_stage3;

    reg [7:0] tx_shift_stage1, tx_shift_stage2, tx_shift_stage3;
    reg [7:0] rx_shift_stage1, rx_shift_stage2, rx_shift_stage3;
    reg [2:0] bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
    reg [1:0] byte_idx_stage1, byte_idx_stage2, byte_idx_stage3;
    reg [1:0] trans_count_stage1, trans_count_stage2, trans_count_stage3;

    reg scl_oe_stage1, scl_oe_stage2, scl_oe_stage3;
    reg sda_oe_stage1, sda_oe_stage2, sda_oe_stage3;

    reg sda_in_stage1, sda_in_stage2, sda_in_stage3;
    reg scl_in_stage1, scl_in_stage2, scl_in_stage3;

    reg start_flag_stage1, start_flag_stage2, start_flag_stage3;

    // I/O buffer assignments
    assign scl = scl_oe_stage3 ? 1'b0 : 1'bz;
    assign sda = sda_oe_stage3 ? tx_shift_stage3[7] : 1'bz;

    // Input sampling for bidirectional signals
    always @(posedge clk) begin
        scl_in_stage1 <= scl;
        sda_in_stage1 <= sda;
        scl_in_stage2 <= scl_in_stage1;
        sda_in_stage2 <= sda_in_stage1;
        scl_in_stage3 <= scl_in_stage2;
        sda_in_stage3 <= sda_in_stage2;
    end

    //==============================================================================
    // Pipeline Valid and Flush Control
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            flush_stage1 <= 1'b0;
            flush_stage2 <= 1'b0;
            flush_stage3 <= 1'b0;
        end else begin
            valid_stage1 <= (state_stage1 != IDLE);
            valid_stage2 <= valid_stage1 & ~flush_stage1;
            valid_stage3 <= valid_stage2 & ~flush_stage2;
            flush_stage1 <= (state_stage1 == DONE) | (state_stage1 == IDLE);
            flush_stage2 <= flush_stage1;
            flush_stage3 <= flush_stage2;
        end
    end

    //==============================================================================
    // State Register: Sequential logic for state transitions (Stage1)
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            state_stage1 <= IDLE;
        else
            state_stage1 <= next_state_stage1;
    end

    // Next State Logic for stage1
    always @(*) begin
        case(state_stage1)
            IDLE:       next_state_stage1 = start ? START_1 : IDLE;
            START_1:    next_state_stage1 = START_2;
            START_2:    next_state_stage1 = DEVADDR_1;
            DEVADDR_1:  next_state_stage1 = DEVADDR_2;
            DEVADDR_2:  next_state_stage1 = (bit_cnt_stage1 == 3'd7) ? ACK_1 : DEVADDR_1;
            ACK_1:      next_state_stage1 = ACK_2;
            ACK_2:      next_state_stage1 = (byte_idx_stage1 < byte_count) ? MEMADDR_1 : STOP_1;
            MEMADDR_1:  next_state_stage1 = MEMADDR_2;
            MEMADDR_2:  next_state_stage1 = (bit_cnt_stage1 == 3'd7) ? WRITE_1 : MEMADDR_1;
            WRITE_1:    next_state_stage1 = WRITE_2;
            WRITE_2:    next_state_stage1 = (bit_cnt_stage1 == 3'd7) ? ACK_1 : WRITE_1;
            READ_1:     next_state_stage1 = READ_2;
            READ_2:     next_state_stage1 = (bit_cnt_stage1 == 3'd7) ? ACK_1 : READ_1;
            STOP_1:     next_state_stage1 = STOP_2;
            STOP_2:     next_state_stage1 = DONE;
            DONE:       next_state_stage1 = IDLE;
            default:    next_state_stage1 = IDLE;
        endcase
    end

    // Pipeline Stage1: Prepare control signals and counters
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_oe_stage1     <= 1'b0;
            sda_oe_stage1     <= 1'b0;
            tx_shift_stage1   <= 8'h00;
            bit_cnt_stage1    <= 3'd0;
            byte_idx_stage1   <= 2'd0;
            trans_count_stage1<= 2'd0;
            start_flag_stage1 <= 1'b0;
            state_stage1      <= IDLE;
        end else begin
            case(state_stage1)
                IDLE: begin
                    scl_oe_stage1     <= 1'b0;
                    sda_oe_stage1     <= 1'b0;
                    tx_shift_stage1   <= 8'h00;
                    bit_cnt_stage1    <= 3'd0;
                    byte_idx_stage1   <= 2'd0;
                    trans_count_stage1<= 2'd0;
                    start_flag_stage1 <= 1'b0;
                end
                START_1: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b1;
                    tx_shift_stage1   <= {dev_addr, 1'b0};
                    bit_cnt_stage1    <= 3'd0;
                    start_flag_stage1 <= 1'b1;
                end
                DEVADDR_1, DEVADDR_2: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b1;
                    if (bit_cnt_stage1 < 3'd7)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    else
                        bit_cnt_stage1 <= 3'd0;
                end
                MEMADDR_1, MEMADDR_2: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b1;
                    if (bit_cnt_stage1 < 3'd7)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    else
                        bit_cnt_stage1 <= 3'd0;
                end
                WRITE_1, WRITE_2: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b1;
                    if (bit_cnt_stage1 < 3'd7)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    else
                        bit_cnt_stage1 <= 3'd0;
                end
                READ_1, READ_2: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b1;
                    if (bit_cnt_stage1 < 3'd7)
                        bit_cnt_stage1 <= bit_cnt_stage1 + 1'b1;
                    else
                        bit_cnt_stage1 <= 3'd0;
                end
                ACK_1, ACK_2: begin
                    scl_oe_stage1     <= 1'b1;
                    sda_oe_stage1     <= 1'b0;
                    if (state_stage1 == ACK_2 && byte_idx_stage1 < byte_count)
                        byte_idx_stage1 <= byte_idx_stage1 + 1'b1;
                end
                STOP_1, STOP_2, DONE: begin
                    scl_oe_stage1     <= 1'b0;
                    sda_oe_stage1     <= 1'b0;
                end
                default: begin
                    scl_oe_stage1     <= scl_oe_stage1;
                    sda_oe_stage1     <= sda_oe_stage1;
                    tx_shift_stage1   <= tx_shift_stage1;
                    bit_cnt_stage1    <= bit_cnt_stage1;
                    byte_idx_stage1   <= byte_idx_stage1;
                    trans_count_stage1<= trans_count_stage1;
                    start_flag_stage1 <= start_flag_stage1;
                end
            endcase
        end
    end

    //==============================================================================
    // Pipeline Stage2: Latch and operate on data/control signals (Stage2)
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_oe_stage2      <= 1'b0;
            sda_oe_stage2      <= 1'b0;
            tx_shift_stage2    <= 8'h00;
            bit_cnt_stage2     <= 3'd0;
            byte_idx_stage2    <= 2'd0;
            trans_count_stage2 <= 2'd0;
            start_flag_stage2  <= 1'b0;
            state_stage2       <= IDLE;
        end else begin
            if(flush_stage1) begin
                scl_oe_stage2      <= 1'b0;
                sda_oe_stage2      <= 1'b0;
                tx_shift_stage2    <= 8'h00;
                bit_cnt_stage2     <= 3'd0;
                byte_idx_stage2    <= 2'd0;
                trans_count_stage2 <= 2'd0;
                start_flag_stage2  <= 1'b0;
                state_stage2       <= IDLE;
            end else begin
                scl_oe_stage2      <= scl_oe_stage1;
                sda_oe_stage2      <= sda_oe_stage1;
                tx_shift_stage2    <= tx_shift_stage1;
                bit_cnt_stage2     <= bit_cnt_stage1;
                byte_idx_stage2    <= byte_idx_stage1;
                trans_count_stage2 <= trans_count_stage1;
                start_flag_stage2  <= start_flag_stage1;
                state_stage2       <= state_stage1;
            end
        end
    end

    //==============================================================================
    // Pipeline Stage3: Output stage (Stage3)
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_oe_stage3      <= 1'b0;
            sda_oe_stage3      <= 1'b0;
            tx_shift_stage3    <= 8'h00;
            bit_cnt_stage3     <= 3'd0;
            byte_idx_stage3    <= 2'd0;
            trans_count_stage3 <= 2'd0;
            start_flag_stage3  <= 1'b0;
            state_stage3       <= IDLE;
        end else begin
            if(flush_stage2) begin
                scl_oe_stage3      <= 1'b0;
                sda_oe_stage3      <= 1'b0;
                tx_shift_stage3    <= 8'h00;
                bit_cnt_stage3     <= 3'd0;
                byte_idx_stage3    <= 2'd0;
                trans_count_stage3 <= 2'd0;
                start_flag_stage3  <= 1'b0;
                state_stage3       <= IDLE;
            end else begin
                scl_oe_stage3      <= scl_oe_stage2;
                sda_oe_stage3      <= sda_oe_stage2;
                tx_shift_stage3    <= tx_shift_stage2;
                bit_cnt_stage3     <= bit_cnt_stage2;
                byte_idx_stage3    <= byte_idx_stage2;
                trans_count_stage3 <= trans_count_stage2;
                start_flag_stage3  <= start_flag_stage2;
                state_stage3       <= state_stage2;
            end
        end
    end

    //==============================================================================
    // Write Data Shift Register Pipeline
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            tx_shift_stage1 <= 8'h00;
        end else begin
            case(state_stage1)
                MEMADDR_1: begin
                    if (bit_cnt_stage1 == 3'd0)
                        tx_shift_stage1 <= mem_addr;
                    else
                        tx_shift_stage1 <= {tx_shift_stage1[6:0], 1'b0};
                end
                WRITE_1: begin
                    if (bit_cnt_stage1 == 3'd0)
                        tx_shift_stage1 <= wdata[byte_idx_stage1];
                    else
                        tx_shift_stage1 <= {tx_shift_stage1[6:0], 1'b0};
                end
                default: begin
                    tx_shift_stage1 <= tx_shift_stage1;
                end
            endcase
        end
    end

    //==============================================================================
    // Read Data Register Pipeline
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rx_shift_stage1 <= 8'h00;
            rx_shift_stage2 <= 8'h00;
            rx_shift_stage3 <= 8'h00;
            rdata[0] <= 8'h00;
            rdata[1] <= 8'h00;
            rdata[2] <= 8'h00;
            rdata[3] <= 8'h00;
        end else begin
            // Stage1: Sample incoming data
            if (state_stage1 == READ_1) begin
                rx_shift_stage1 <= {rx_shift_stage1[6:0], sda_in_stage3};
            end else begin
                rx_shift_stage1 <= rx_shift_stage1;
            end

            // Stage2: Pass to next pipeline
            rx_shift_stage2 <= rx_shift_stage1;

            // Stage3: Capture and output result
            rx_shift_stage3 <= rx_shift_stage2;
            if (state_stage3 == READ_1 && bit_cnt_stage3 == 3'd7) begin
                rdata[byte_idx_stage3] <= {rx_shift_stage3[6:0], sda_in_stage3};
            end
        end
    end

    //==============================================================================
    // Busy and Done Signals: Status outputs
    //==============================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            case(state_stage3)
                IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;
                end
                START_1, START_2, DEVADDR_1, DEVADDR_2, MEMADDR_1, MEMADDR_2,
                WRITE_1, WRITE_2, READ_1, READ_2, ACK_1, ACK_2, STOP_1, STOP_2: begin
                    busy <= 1'b1;
                    done <= 1'b0;
                end
                DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
                default: begin
                    busy <= busy;
                    done <= done;
                end
            endcase
        end
    end

endmodule