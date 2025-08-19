//SystemVerilog
module spi_burst_master #(
    parameter DATA_WIDTH = 8,
    parameter BURST_SIZE = 4
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] tx_data [BURST_SIZE-1:0],
    input burst_start,
    output reg [DATA_WIDTH-1:0] rx_data [BURST_SIZE-1:0],
    output reg burst_done,

    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    // Stage1 combinational signals
    reg [DATA_WIDTH-1:0] shift_reg_stage1_cmb, shift_reg_stage1_q;
    reg [$clog2(DATA_WIDTH)-1:0] bit_count_stage1_cmb, bit_count_stage1_q;
    reg [$clog2(BURST_SIZE)-1:0] burst_count_stage1_cmb, burst_count_stage1_q;
    reg busy_stage1_cmb, busy_stage1_q;
    reg sclk_int_stage1_cmb, sclk_int_stage1_q;
    reg [DATA_WIDTH-1:0] rx_shift_reg_stage1_cmb, rx_shift_reg_stage1_q;
    reg [DATA_WIDTH-1:0] rx_data_next_cmb [BURST_SIZE-1:0];
    reg [DATA_WIDTH-1:0] rx_data_next_q [BURST_SIZE-1:0];
    reg burst_done_stage1_cmb, burst_done_stage1_q;

    // Stage2 registers
    reg [DATA_WIDTH-1:0] shift_reg_stage2;
    reg [$clog2(DATA_WIDTH)-1:0] bit_count_stage2;
    reg [$clog2(BURST_SIZE)-1:0] burst_count_stage2;
    reg busy_stage2;
    reg sclk_int_stage2;
    reg [DATA_WIDTH-1:0] rx_shift_reg_stage2;
    reg burst_done_stage2;

    // Output assignments
    assign sclk = busy_stage2 ? sclk_int_stage2 : 1'b0;
    assign cs_n = ~busy_stage2;
    assign mosi = shift_reg_stage2[DATA_WIDTH-1];

    integer i;

    // Stage 1 Combinational Logic
    always @* begin
        // Default: keep previous values
        busy_stage1_cmb        = busy_stage1_q;
        burst_done_stage1_cmb  = 1'b0;
        bit_count_stage1_cmb   = bit_count_stage1_q;
        burst_count_stage1_cmb = burst_count_stage1_q;
        sclk_int_stage1_cmb    = sclk_int_stage1_q;
        shift_reg_stage1_cmb   = shift_reg_stage1_q;
        rx_shift_reg_stage1_cmb= rx_shift_reg_stage1_q;
        for (i = 0; i < BURST_SIZE; i = i + 1)
            rx_data_next_cmb[i] = rx_data_next_q[i];

        if (!rst_n) begin
            busy_stage1_cmb        = 1'b0;
            burst_done_stage1_cmb  = 1'b0;
            bit_count_stage1_cmb   = {$clog2(DATA_WIDTH){1'b0}};
            burst_count_stage1_cmb = {$clog2(BURST_SIZE){1'b0}};
            sclk_int_stage1_cmb    = 1'b0;
            shift_reg_stage1_cmb   = {DATA_WIDTH{1'b0}};
            rx_shift_reg_stage1_cmb= {DATA_WIDTH{1'b0}};
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data_next_cmb[i] = {DATA_WIDTH{1'b0}};
        end else begin
            case ({burst_start && !busy_stage1_q, busy_stage1_q})
                2'b10: begin // burst_start asserted and not busy
                    busy_stage1_cmb        = 1'b1;
                    burst_count_stage1_cmb = {$clog2(BURST_SIZE){1'b0}};
                    bit_count_stage1_cmb   = DATA_WIDTH-1;
                    shift_reg_stage1_cmb   = tx_data[0];
                    burst_done_stage1_cmb  = 1'b0;
                    sclk_int_stage1_cmb    = 1'b0;
                    rx_shift_reg_stage1_cmb= {DATA_WIDTH{1'b0}};
                end
                2'b01: begin // busy
                    sclk_int_stage1_cmb = ~sclk_int_stage1_q;
                    case (sclk_int_stage1_q)
                        1'b0: begin // Rising edge
                            shift_reg_stage1_cmb = {shift_reg_stage1_q[DATA_WIDTH-2:0], 1'b0};
                            bit_count_stage1_cmb = bit_count_stage1_q - 1;
                            if (bit_count_stage1_q == 0) begin
                                if (burst_count_stage1_q == BURST_SIZE-1) begin
                                    busy_stage1_cmb       = 1'b0;
                                    burst_done_stage1_cmb = 1'b1;
                                end else begin
                                    burst_count_stage1_cmb = burst_count_stage1_q + 1;
                                    bit_count_stage1_cmb   = DATA_WIDTH-1;
                                    shift_reg_stage1_cmb   = tx_data[burst_count_stage1_q+1];
                                end
                            end
                        end
                        1'b1: begin // Falling edge
                            rx_shift_reg_stage1_cmb = rx_shift_reg_stage1_q;
                            if (bit_count_stage1_q != DATA_WIDTH-1) begin
                                rx_shift_reg_stage1_cmb[bit_count_stage1_q] = miso;
                            end
                        end
                        default: ; // No action
                    endcase
                end
                default: begin
                    burst_done_stage1_cmb = 1'b0;
                end
            endcase
            // Update rx_data_next on transfer complete
            if (busy_stage1_q && sclk_int_stage1_q && (bit_count_stage1_q == 0)) begin
                rx_data_next_cmb[burst_count_stage1_q] = rx_shift_reg_stage1_q;
            end
        end
    end

    // Stage 1 Registers (moved after combinational logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_stage1_q        <= 1'b0;
            burst_done_stage1_q  <= 1'b0;
            bit_count_stage1_q   <= {$clog2(DATA_WIDTH){1'b0}};
            burst_count_stage1_q <= {$clog2(BURST_SIZE){1'b0}};
            sclk_int_stage1_q    <= 1'b0;
            shift_reg_stage1_q   <= {DATA_WIDTH{1'b0}};
            rx_shift_reg_stage1_q<= {DATA_WIDTH{1'b0}};
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data_next_q[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            busy_stage1_q        <= busy_stage1_cmb;
            burst_done_stage1_q  <= burst_done_stage1_cmb;
            bit_count_stage1_q   <= bit_count_stage1_cmb;
            burst_count_stage1_q <= burst_count_stage1_cmb;
            sclk_int_stage1_q    <= sclk_int_stage1_cmb;
            shift_reg_stage1_q   <= shift_reg_stage1_cmb;
            rx_shift_reg_stage1_q<= rx_shift_reg_stage1_cmb;
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data_next_q[i] <= rx_data_next_cmb[i];
        end
    end

    // Stage 2: Output register stage for timing cut
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_stage2        <= 1'b0;
            burst_done_stage2  <= 1'b0;
            bit_count_stage2   <= {$clog2(DATA_WIDTH){1'b0}};
            burst_count_stage2 <= {$clog2(BURST_SIZE){1'b0}};
            sclk_int_stage2    <= 1'b0;
            shift_reg_stage2   <= {DATA_WIDTH{1'b0}};
            rx_shift_reg_stage2<= {DATA_WIDTH{1'b0}};
            burst_done         <= 1'b0;
            for (i = 0; i < BURST_SIZE; i = i + 1) begin
                rx_data[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            busy_stage2        <= busy_stage1_q;
            burst_done_stage2  <= burst_done_stage1_q;
            bit_count_stage2   <= bit_count_stage1_q;
            burst_count_stage2 <= burst_count_stage1_q;
            sclk_int_stage2    <= sclk_int_stage1_q;
            shift_reg_stage2   <= shift_reg_stage1_q;
            rx_shift_reg_stage2<= rx_shift_reg_stage1_q;
            burst_done         <= burst_done_stage2;
            for (i = 0; i < BURST_SIZE; i = i + 1) begin
                rx_data[i] <= rx_data_next_q[i];
            end
        end
    end

endmodule