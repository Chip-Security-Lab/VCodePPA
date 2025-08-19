//SystemVerilog
module spi_master_basic #(
    parameter DATA_WIDTH = 8
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   start_tx,
    input  wire [DATA_WIDTH-1:0]  tx_data,
    output reg  [DATA_WIDTH-1:0]  rx_data,
    output reg                    busy,
    output reg                    sclk,
    output reg                    cs_n,
    output reg                    mosi,
    input  wire                   miso
);

    // Stage registers and pipeline signals
    reg [DATA_WIDTH-1:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg [DATA_WIDTH-1:0] rx_data_stage3;
    reg [$clog2(DATA_WIDTH):0] bit_counter_stage1, bit_counter_stage2, bit_counter_stage3;
    reg busy_stage1, busy_stage2, busy_stage3;
    reg cs_n_stage1, cs_n_stage2, cs_n_stage3;
    reg sclk_stage1, sclk_stage2, sclk_stage3;
    reg mosi_stage1, mosi_stage2, mosi_stage3;
    reg miso_sampled_stage1, miso_sampled_stage2;

    // FSM and control pipeline
    typedef enum reg [1:0] {
        IDLE    = 2'b00,
        LOAD    = 2'b01,
        TRANS   = 2'b10,
        DONE    = 2'b11
    } state_t;
    reg [1:0] state_stage1, state_stage2, state_stage3;

    // 2-bit Subtractor using two's complement
    function [1:0] twos_complement_sub_2bit;
        input [1:0] minuend;
        input [1:0] subtrahend;
        reg [1:0] subtrahend_neg;
        reg [2:0] result_full;
        begin
            subtrahend_neg = ~subtrahend + 2'b01;
            result_full = {1'b0, minuend} + {1'b0, subtrahend_neg};
            twos_complement_sub_2bit = result_full[1:0];
        end
    endfunction

    // Sampling miso for pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            miso_sampled_stage1 <= 1'b0;
            miso_sampled_stage2 <= 1'b0;
        end else begin
            miso_sampled_stage1 <= miso;
            miso_sampled_stage2 <= miso_sampled_stage1;
        end
    end

    // Stage 1: FSM, load, and start
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1        <= IDLE;
            shift_reg_stage1    <= {DATA_WIDTH{1'b0}};
            bit_counter_stage1  <= 0;
            busy_stage1         <= 1'b0;
            cs_n_stage1         <= 1'b1;
            sclk_stage1         <= 1'b0;
            mosi_stage1         <= 1'b0;
        end else begin
            case (state_stage1)
                IDLE: begin
                    busy_stage1     <= 1'b0;
                    cs_n_stage1     <= 1'b1;
                    sclk_stage1     <= 1'b0;
                    if (start_tx) begin
                        state_stage1        <= LOAD;
                        shift_reg_stage1    <= tx_data;
                        bit_counter_stage1  <= DATA_WIDTH;
                    end
                end
                LOAD: begin
                    busy_stage1     <= 1'b1;
                    cs_n_stage1     <= 1'b0;
                    sclk_stage1     <= 1'b0;
                    state_stage1    <= TRANS;
                end
                TRANS: begin
                    busy_stage1     <= 1'b1;
                    cs_n_stage1     <= 1'b0;
                    sclk_stage1     <= ~sclk_stage1;
                    if (~sclk_stage1) begin
                        mosi_stage1 <= shift_reg_stage1[DATA_WIDTH-1];
                    end
                    if (sclk_stage1) begin
                        // Use two's complement subtraction for 2-bit operation
                        if (DATA_WIDTH == 2) begin
                            bit_counter_stage1 <= { {($clog2(DATA_WIDTH)-1){1'b0}}, 
                                twos_complement_sub_2bit(bit_counter_stage1[1:0], 2'b01)};
                        end else begin
                            bit_counter_stage1 <= bit_counter_stage1 - 1;
                        end
                        shift_reg_stage1 <= {shift_reg_stage1[DATA_WIDTH-2:0], miso_sampled_stage2};
                        if (bit_counter_stage1 == 1) begin
                            state_stage1 <= DONE;
                        end
                    end
                end
                DONE: begin
                    busy_stage1     <= 1'b0;
                    cs_n_stage1     <= 1'b1;
                    sclk_stage1     <= 1'b0;
                    state_stage1    <= IDLE;
                end
            endcase
        end
    end

    // Stage 2: Pipeline all control and data signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2        <= IDLE;
            shift_reg_stage2    <= {DATA_WIDTH{1'b0}};
            bit_counter_stage2  <= 0;
            busy_stage2         <= 1'b0;
            cs_n_stage2         <= 1'b1;
            sclk_stage2         <= 1'b0;
            mosi_stage2         <= 1'b0;
        end else begin
            state_stage2        <= state_stage1;
            shift_reg_stage2    <= shift_reg_stage1;
            bit_counter_stage2  <= bit_counter_stage1;
            busy_stage2         <= busy_stage1;
            cs_n_stage2         <= cs_n_stage1;
            sclk_stage2         <= sclk_stage1;
            mosi_stage2         <= mosi_stage1;
        end
    end

    // Stage 3: Output pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3        <= IDLE;
            shift_reg_stage3    <= {DATA_WIDTH{1'b0}};
            bit_counter_stage3  <= 0;
            busy_stage3         <= 1'b0;
            cs_n_stage3         <= 1'b1;
            sclk_stage3         <= 1'b0;
            mosi_stage3         <= 1'b0;
            rx_data_stage3      <= {DATA_WIDTH{1'b0}};
        end else begin
            state_stage3        <= state_stage2;
            shift_reg_stage3    <= shift_reg_stage2;
            bit_counter_stage3  <= bit_counter_stage2;
            busy_stage3         <= busy_stage2;
            cs_n_stage3         <= cs_n_stage2;
            sclk_stage3         <= sclk_stage2;
            mosi_stage3         <= mosi_stage2;
            if (state_stage2 == DONE) begin
                rx_data_stage3  <= shift_reg_stage2;
            end
        end
    end

    // Output assignments
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
            busy    <= 1'b0;
            cs_n    <= 1'b1;
            sclk    <= 1'b0;
            mosi    <= 1'b0;
        end else begin
            rx_data <= rx_data_stage3;
            busy    <= busy_stage3;
            cs_n    <= cs_n_stage3;
            sclk    <= sclk_stage3;
            mosi    <= mosi_stage3;
        end
    end

endmodule