//SystemVerilog
module spi_master_basic #(parameter DATA_WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire start_tx,
    input wire [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output reg sclk,
    output reg cs_n,
    output reg mosi,
    input wire miso
);

    // State encoding
    localparam [1:0] IDLE = 2'b00, LOAD = 2'b01, TRANSFER = 2'b10, DONE = 2'b11;

    reg [1:0] curr_state_stage1, curr_state_stage2, curr_state_stage3;
    reg [1:0] next_state_stage1, next_state_stage2, next_state_stage3;

    reg [DATA_WIDTH-1:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg [DATA_WIDTH-1:0] shift_reg_next_stage1, shift_reg_next_stage2, shift_reg_next_stage3;

    reg [$clog2(DATA_WIDTH):0] bit_counter_stage1, bit_counter_stage2, bit_counter_stage3;
    reg [$clog2(DATA_WIDTH):0] bit_counter_next_stage1, bit_counter_next_stage2, bit_counter_next_stage3;

    reg busy_stage1, busy_stage2, busy_stage3;
    reg busy_next_stage1, busy_next_stage2, busy_next_stage3;

    reg cs_n_stage1, cs_n_stage2, cs_n_stage3;
    reg cs_n_next_stage1, cs_n_next_stage2, cs_n_next_stage3;

    reg sclk_stage1, sclk_stage2, sclk_stage3;
    reg sclk_next_stage1, sclk_next_stage2, sclk_next_stage3;

    reg mosi_stage1, mosi_stage2, mosi_stage3;
    reg mosi_next_stage1, mosi_next_stage2, mosi_next_stage3;

    reg [DATA_WIDTH-1:0] rx_data_stage1, rx_data_stage2, rx_data_stage3;
    reg [DATA_WIDTH-1:0] rx_data_next_stage1, rx_data_next_stage2, rx_data_next_stage3;

    reg valid_stage1, valid_stage2, valid_stage3;
    reg valid_next_stage1, valid_next_stage2, valid_next_stage3;

    // Pipeline flush logic
    wire flush_pipeline;
    assign flush_pipeline = !rst_n;

    // --- Stage 1: State & Input Latching ---
    always @* begin
        // State transition
        case (curr_state_stage1)
            IDLE:      next_state_stage1 = start_tx ? LOAD : IDLE;
            LOAD:      next_state_stage1 = TRANSFER;
            TRANSFER:  next_state_stage1 = (bit_counter_stage1 == 0) ? DONE : TRANSFER;
            DONE:      next_state_stage1 = IDLE;
            default:   next_state_stage1 = IDLE;
        endcase

        // Control/data logic for next stage
        busy_next_stage1      = busy_stage1;
        cs_n_next_stage1      = cs_n_stage1;
        sclk_next_stage1      = sclk_stage1;
        shift_reg_next_stage1 = shift_reg_stage1;
        bit_counter_next_stage1 = bit_counter_stage1;
        mosi_next_stage1      = mosi_stage1;
        rx_data_next_stage1   = rx_data_stage1;
        valid_next_stage1     = valid_stage1;

        case (curr_state_stage1)
            IDLE: begin
                busy_next_stage1      = 1'b0;
                cs_n_next_stage1      = 1'b1;
                sclk_next_stage1      = 1'b0;
                shift_reg_next_stage1 = {DATA_WIDTH{1'b0}};
                bit_counter_next_stage1 = {($clog2(DATA_WIDTH)+1){1'b0}};
                mosi_next_stage1      = 1'b0;
                rx_data_next_stage1   = {DATA_WIDTH{1'b0}};
                valid_next_stage1     = 1'b0;
            end
            LOAD: begin
                busy_next_stage1      = 1'b1;
                cs_n_next_stage1      = 1'b0;
                bit_counter_next_stage1 = DATA_WIDTH[($clog2(DATA_WIDTH)):0];
                shift_reg_next_stage1 = tx_data;
                sclk_next_stage1      = 1'b0;
                mosi_next_stage1      = tx_data[DATA_WIDTH-1];
                rx_data_next_stage1   = {DATA_WIDTH{1'b0}};
                valid_next_stage1     = 1'b1;
            end
            TRANSFER: begin
                sclk_next_stage1      = ~sclk_stage1;
                // Latch mosi at sclk falling edge, shift at rising edge
                if (~sclk_stage1) begin
                    mosi_next_stage1 = shift_reg_stage1[DATA_WIDTH-1];
                end else begin
                    shift_reg_next_stage1 = {shift_reg_stage1[DATA_WIDTH-2:0], miso};
                    bit_counter_next_stage1 = bit_counter_stage1 ? (bit_counter_stage1 - 1'b1) : bit_counter_stage1;
                    mosi_next_stage1 = mosi_stage1;
                end
                busy_next_stage1 = 1'b1;
                cs_n_next_stage1 = 1'b0;
                valid_next_stage1 = valid_stage1;
            end
            DONE: begin
                busy_next_stage1      = 1'b0;
                cs_n_next_stage1      = 1'b1;
                rx_data_next_stage1   = shift_reg_stage1;
                sclk_next_stage1      = 1'b0;
                mosi_next_stage1      = 1'b0;
                valid_next_stage1     = 1'b1;
            end
        endcase
    end

    // --- Stage 2: Pipeline Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state_stage2     <= IDLE;
            shift_reg_stage2      <= {DATA_WIDTH{1'b0}};
            bit_counter_stage2    <= {($clog2(DATA_WIDTH)+1){1'b0}};
            busy_stage2           <= 1'b0;
            cs_n_stage2           <= 1'b1;
            sclk_stage2           <= 1'b0;
            mosi_stage2           <= 1'b0;
            rx_data_stage2        <= {DATA_WIDTH{1'b0}};
            valid_stage2          <= 1'b0;
        end else begin
            curr_state_stage2     <= next_state_stage1;
            shift_reg_stage2      <= shift_reg_next_stage1;
            bit_counter_stage2    <= bit_counter_next_stage1;
            busy_stage2           <= busy_next_stage1;
            cs_n_stage2           <= cs_n_next_stage1;
            sclk_stage2           <= sclk_next_stage1;
            mosi_stage2           <= mosi_next_stage1;
            rx_data_stage2        <= rx_data_next_stage1;
            valid_stage2          <= valid_next_stage1;
        end
    end

    // --- Stage 3: Pipeline Register ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state_stage3     <= IDLE;
            shift_reg_stage3      <= {DATA_WIDTH{1'b0}};
            bit_counter_stage3    <= {($clog2(DATA_WIDTH)+1){1'b0}};
            busy_stage3           <= 1'b0;
            cs_n_stage3           <= 1'b1;
            sclk_stage3           <= 1'b0;
            mosi_stage3           <= 1'b0;
            rx_data_stage3        <= {DATA_WIDTH{1'b0}};
            valid_stage3          <= 1'b0;
        end else begin
            curr_state_stage3     <= curr_state_stage2;
            shift_reg_stage3      <= shift_reg_stage2;
            bit_counter_stage3    <= bit_counter_stage2;
            busy_stage3           <= busy_stage2;
            cs_n_stage3           <= cs_n_stage2;
            sclk_stage3           <= sclk_stage2;
            mosi_stage3           <= mosi_stage2;
            rx_data_stage3        <= rx_data_stage2;
            valid_stage3          <= valid_stage2;
        end
    end

    // --- Stage 1 Registers ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            curr_state_stage1    <= IDLE;
            shift_reg_stage1     <= {DATA_WIDTH{1'b0}};
            bit_counter_stage1   <= {($clog2(DATA_WIDTH)+1){1'b0}};
            busy_stage1          <= 1'b0;
            cs_n_stage1          <= 1'b1;
            sclk_stage1          <= 1'b0;
            mosi_stage1          <= 1'b0;
            rx_data_stage1       <= {DATA_WIDTH{1'b0}};
            valid_stage1         <= 1'b0;
        end else begin
            curr_state_stage1    <= next_state_stage1;
            shift_reg_stage1     <= shift_reg_next_stage1;
            bit_counter_stage1   <= bit_counter_next_stage1;
            busy_stage1          <= busy_next_stage1;
            cs_n_stage1          <= cs_n_next_stage1;
            sclk_stage1          <= sclk_next_stage1;
            mosi_stage1          <= mosi_next_stage1;
            rx_data_stage1       <= rx_data_next_stage1;
            valid_stage1         <= valid_next_stage1;
        end
    end

    // --- Output Assignments with Output Pipeline Register ---
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