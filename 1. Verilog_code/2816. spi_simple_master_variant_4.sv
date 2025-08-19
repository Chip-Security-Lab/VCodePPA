//SystemVerilog
module spi_simple_master(
    input wire        clock,
    input wire        reset,
    input wire [7:0]  mosi_data,
    input wire        start,
    output reg [7:0]  miso_data,
    output reg        done,

    // SPI interface
    output reg        sck,
    output reg        mosi,
    input wire        miso,
    output reg        ss
);

    // State encoding
    localparam [1:0] STATE_IDLE      = 2'b00;
    localparam [1:0] STATE_TRANSMIT  = 2'b01;
    localparam [1:0] STATE_FINISH    = 2'b10;

    // State registers
    reg  [1:0]  state_stage1, state_stage2, state_stage3;
    reg  [1:0]  state_next_stage1, state_next_stage2, state_next_stage3;

    // Bit counter pipeline
    reg  [2:0]  bit_cnt_stage1, bit_cnt_stage2, bit_cnt_stage3;
    reg  [2:0]  bit_cnt_next_stage1, bit_cnt_next_stage2, bit_cnt_next_stage3;

    // Shift register pipeline
    reg  [7:0]  shreg_stage1, shreg_stage2, shreg_stage3;
    reg  [7:0]  shreg_next_stage1, shreg_next_stage2, shreg_next_stage3;

    // SCK pipeline
    reg         sck_stage1, sck_stage2, sck_stage3;
    reg         sck_next_stage1, sck_next_stage2, sck_next_stage3;

    // MOSI pipeline
    reg         mosi_stage1, mosi_stage2, mosi_stage3;
    reg         mosi_next_stage1, mosi_next_stage2, mosi_next_stage3;

    // SS pipeline
    reg         ss_stage1, ss_stage2, ss_stage3;
    reg         ss_next_stage1, ss_next_stage2, ss_next_stage3;

    // MISO data pipeline
    reg  [7:0]  miso_data_stage1, miso_data_stage2, miso_data_stage3;
    reg  [7:0]  miso_data_next_stage1, miso_data_next_stage2, miso_data_next_stage3;

    // Done pipeline
    reg         done_stage1, done_stage2, done_stage3;
    reg         done_next_stage1, done_next_stage2, done_next_stage3;

    // Inter-stage latches for MISO sampling
    reg         miso_sample_stage1, miso_sample_stage2, miso_sample_stage3;
    reg         miso_sample_next_stage1, miso_sample_next_stage2, miso_sample_next_stage3;

    // Stage 1: State and input latching
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state_stage1        <= STATE_IDLE;
            bit_cnt_stage1      <= 3'b000;
            shreg_stage1        <= 8'h00;
            sck_stage1          <= 1'b0;
            mosi_stage1         <= 1'b0;
            ss_stage1           <= 1'b1;
            miso_data_stage1    <= 8'h00;
            done_stage1         <= 1'b0;
            miso_sample_stage1  <= 1'b0;
        end else begin
            state_stage1        <= state_next_stage1;
            bit_cnt_stage1      <= bit_cnt_next_stage1;
            shreg_stage1        <= shreg_next_stage1;
            sck_stage1          <= sck_next_stage1;
            mosi_stage1         <= mosi_next_stage1;
            ss_stage1           <= ss_next_stage1;
            miso_data_stage1    <= miso_data_next_stage1;
            done_stage1         <= done_next_stage1;
            miso_sample_stage1  <= miso_sample_next_stage1;
        end
    end

    // Stage 2: Process pipeline
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state_stage2        <= STATE_IDLE;
            bit_cnt_stage2      <= 3'b000;
            shreg_stage2        <= 8'h00;
            sck_stage2          <= 1'b0;
            mosi_stage2         <= 1'b0;
            ss_stage2           <= 1'b1;
            miso_data_stage2    <= 8'h00;
            done_stage2         <= 1'b0;
            miso_sample_stage2  <= 1'b0;
        end else begin
            state_stage2        <= state_stage1;
            bit_cnt_stage2      <= bit_cnt_stage1;
            shreg_stage2        <= shreg_stage1;
            sck_stage2          <= sck_stage1;
            mosi_stage2         <= mosi_stage1;
            ss_stage2           <= ss_stage1;
            miso_data_stage2    <= miso_data_stage1;
            done_stage2         <= done_stage1;
            miso_sample_stage2  <= miso_sample_stage1;
        end
    end

    // Stage 3: Output latching
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state_stage3        <= STATE_IDLE;
            bit_cnt_stage3      <= 3'b000;
            shreg_stage3        <= 8'h00;
            sck_stage3          <= 1'b0;
            mosi_stage3         <= 1'b0;
            ss_stage3           <= 1'b1;
            miso_data_stage3    <= 8'h00;
            done_stage3         <= 1'b0;
            miso_sample_stage3  <= 1'b0;
        end else begin
            state_stage3        <= state_stage2;
            bit_cnt_stage3      <= bit_cnt_stage2;
            shreg_stage3        <= shreg_stage2;
            sck_stage3          <= sck_stage2;
            mosi_stage3         <= mosi_stage2;
            ss_stage3           <= ss_stage2;
            miso_data_stage3    <= miso_data_stage2;
            done_stage3         <= done_stage2;
            miso_sample_stage3  <= miso_sample_stage2;
        end
    end

    // Combinational logic for Stage 1
    always @* begin
        // Defaults
        state_next_stage1        = state_stage1;
        bit_cnt_next_stage1      = bit_cnt_stage1;
        shreg_next_stage1        = shreg_stage1;
        sck_next_stage1          = sck_stage1;
        mosi_next_stage1         = mosi_stage1;
        ss_next_stage1           = ss_stage1;
        miso_data_next_stage1    = miso_data_stage1;
        done_next_stage1         = done_stage1;
        miso_sample_next_stage1  = miso_sample_stage1;

        case (state_stage1)
            STATE_IDLE: begin
                done_next_stage1         = 1'b0;
                miso_data_next_stage1    = miso_data_stage1;
                sck_next_stage1          = 1'b0;
                mosi_next_stage1         = 1'b0;
                ss_next_stage1           = 1'b1;
                miso_sample_next_stage1  = 1'b0;
                if (start) begin
                    state_next_stage1        = STATE_TRANSMIT;
                    shreg_next_stage1        = mosi_data;
                    bit_cnt_next_stage1      = 3'b111;
                    ss_next_stage1           = 1'b0;
                    sck_next_stage1          = 1'b0;
                    mosi_next_stage1         = mosi_data[7];
                    miso_sample_next_stage1  = 1'b0;
                end
            end

            STATE_TRANSMIT: begin
                sck_next_stage1          = sck_stage1;   // Will be updated in stage2
                mosi_next_stage1         = mosi_stage1;  // Will be updated in stage2
                shreg_next_stage1        = shreg_stage1; // Will be updated in stage3
                bit_cnt_next_stage1      = bit_cnt_stage1; // Will be updated in stage3
                done_next_stage1         = 1'b0;
                ss_next_stage1           = 1'b0;
                miso_data_next_stage1    = miso_data_stage1;
                miso_sample_next_stage1  = 1'b0;
            end

            STATE_FINISH: begin
                miso_data_next_stage1    = shreg_stage1;
                done_next_stage1         = 1'b1;
                ss_next_stage1           = 1'b1;
                sck_next_stage1          = 1'b0;
                mosi_next_stage1         = 1'b0;
                state_next_stage1        = STATE_IDLE;
                bit_cnt_next_stage1      = 3'b000;
                shreg_next_stage1        = 8'h00;
                miso_sample_next_stage1  = 1'b0;
            end

            default: begin
                state_next_stage1        = STATE_IDLE;
                bit_cnt_next_stage1      = 3'b000;
                shreg_next_stage1        = 8'h00;
                sck_next_stage1          = 1'b0;
                mosi_next_stage1         = 1'b0;
                ss_next_stage1           = 1'b1;
                miso_data_next_stage1    = 8'h00;
                done_next_stage1         = 1'b0;
                miso_sample_next_stage1  = 1'b0;
            end
        endcase
    end

    // Combinational logic for Stage 2 (toggle SCK, handle MOSI, prepare for MISO sample)
    always @* begin
        state_next_stage2        = state_stage2;
        bit_cnt_next_stage2      = bit_cnt_stage2;
        shreg_next_stage2        = shreg_stage2;
        sck_next_stage2          = sck_stage2;
        mosi_next_stage2         = mosi_stage2;
        ss_next_stage2           = ss_stage2;
        miso_data_next_stage2    = miso_data_stage2;
        done_next_stage2         = done_stage2;
        miso_sample_next_stage2  = miso_sample_stage2;

        if (state_stage2 == STATE_TRANSMIT) begin
            sck_next_stage2 = ~sck_stage2;
            if (!sck_stage2) begin
                // On SCK falling edge, output next bit on MOSI
                mosi_next_stage2        = shreg_stage2[7];
                miso_sample_next_stage2 = 1'b0;
            end else begin
                // On SCK rising edge, sample MISO in next stage
                mosi_next_stage2        = mosi_stage2;
                miso_sample_next_stage2 = 1'b1;
            end
        end else begin
            sck_next_stage2         = sck_stage2;
            mosi_next_stage2        = mosi_stage2;
            miso_sample_next_stage2 = 1'b0;
        end

        // Other signals pass-through
        state_next_stage2        = state_stage2;
        bit_cnt_next_stage2      = bit_cnt_stage2;
        shreg_next_stage2        = shreg_stage2;
        ss_next_stage2           = ss_stage2;
        miso_data_next_stage2    = miso_data_stage2;
        done_next_stage2         = done_stage2;
    end

    // Combinational logic for Stage 3 (MISO sample and shifting, state transition)
    always @* begin
        state_next_stage3        = state_stage3;
        bit_cnt_next_stage3      = bit_cnt_stage3;
        shreg_next_stage3        = shreg_stage3;
        sck_next_stage3          = sck_stage3;
        mosi_next_stage3         = mosi_stage3;
        ss_next_stage3           = ss_stage3;
        miso_data_next_stage3    = miso_data_stage3;
        done_next_stage3         = done_stage3;
        miso_sample_next_stage3  = 1'b0;

        if (state_stage3 == STATE_TRANSMIT) begin
            if (miso_sample_stage3) begin
                // On SCK rising edge: sample MISO, shift, decrement counter
                shreg_next_stage3 = {shreg_stage3[6:0], miso};
                // Optimized comparison using range check for bit counter
                if (|bit_cnt_stage3) begin // equivalent to bit_cnt_stage3 != 0
                    bit_cnt_next_stage3 = bit_cnt_stage3 - 3'b001;
                    state_next_stage3   = STATE_TRANSMIT;
                end else begin
                    bit_cnt_next_stage3 = 3'b000;
                    state_next_stage3   = STATE_FINISH;
                end
            end else begin
                shreg_next_stage3      = shreg_stage3;
                bit_cnt_next_stage3    = bit_cnt_stage3;
                state_next_stage3      = state_stage3;
            end
        end else begin
            shreg_next_stage3      = shreg_stage3;
            bit_cnt_next_stage3    = bit_cnt_stage3;
            state_next_stage3      = state_stage3;
        end

        sck_next_stage3          = sck_stage3;
        mosi_next_stage3         = mosi_stage3;
        ss_next_stage3           = ss_stage3;
        miso_data_next_stage3    = miso_data_stage3;
        done_next_stage3         = done_stage3;
    end

    // Output assignments from output stage
    always @* begin
        sck      = sck_stage3;
        mosi     = mosi_stage3;
        ss       = ss_stage3;
        done     = done_stage3;
        miso_data= miso_data_stage3;
    end

endmodule