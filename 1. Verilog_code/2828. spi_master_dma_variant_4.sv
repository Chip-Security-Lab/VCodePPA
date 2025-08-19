//SystemVerilog
module spi_master_dma(
    input               clk,
    input               rst_n,

    // DMA interface
    input  [7:0]        dma_data_in,
    input               dma_valid_in,
    output              dma_ready_out,
    output [7:0]        dma_data_out,
    output              dma_valid_out,
    input               dma_ready_in,

    // Control signals
    input               transfer_start,
    input  [15:0]       transfer_length, // bytes
    output              transfer_busy,
    output              transfer_done,

    // SPI interface
    output              sclk,
    output              cs_n,
    output              mosi,
    input               miso
);

    // FSM states
    localparam IDLE         = 3'd0;
    localparam LOAD         = 3'd1;
    localparam SHIFT_OUT    = 3'd2;
    localparam SHIFT_IN     = 3'd3;
    localparam STORE        = 3'd4;
    localparam FINISH       = 3'd5;

    // Pipeline registers and control (increased to 6 stages)
    reg   [2:0]   state_stage1, state_stage2, state_stage3, state_stage4, state_stage5, state_stage6;
    reg   [7:0]   tx_shift_stage1, tx_shift_stage2, tx_shift_stage3, tx_shift_stage4, tx_shift_stage5, tx_shift_stage6;
    reg   [7:0]   rx_shift_stage1, rx_shift_stage2, rx_shift_stage3, rx_shift_stage4, rx_shift_stage5, rx_shift_stage6;
    reg   [2:0]   bit_count_stage1, bit_count_stage2, bit_count_stage3, bit_count_stage4, bit_count_stage5, bit_count_stage6;
    reg  [15:0]   byte_count_stage1, byte_count_stage2, byte_count_stage3, byte_count_stage4, byte_count_stage5, byte_count_stage6;
    reg           cs_n_stage1, cs_n_stage2, cs_n_stage3, cs_n_stage4, cs_n_stage5, cs_n_stage6;
    reg           sclk_stage1, sclk_stage2, sclk_stage3, sclk_stage4, sclk_stage5, sclk_stage6;
    reg           transfer_busy_stage1, transfer_busy_stage2, transfer_busy_stage3, transfer_busy_stage4, transfer_busy_stage5, transfer_busy_stage6;
    reg           transfer_done_stage1, transfer_done_stage2, transfer_done_stage3, transfer_done_stage4, transfer_done_stage5, transfer_done_stage6;
    reg           dma_ready_out_stage1, dma_ready_out_stage2, dma_ready_out_stage3, dma_ready_out_stage4, dma_ready_out_stage5, dma_ready_out_stage6;
    reg           dma_valid_out_stage1, dma_valid_out_stage2, dma_valid_out_stage3, dma_valid_out_stage4, dma_valid_out_stage5, dma_valid_out_stage6;
    reg   [7:0]   dma_data_out_stage1, dma_data_out_stage2, dma_data_out_stage3, dma_data_out_stage4, dma_data_out_stage5, dma_data_out_stage6;

    // Valid pipeline
    reg           valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5, valid_stage6;
    reg           flush_stage1, flush_stage2, flush_stage3, flush_stage4, flush_stage5, flush_stage6;

    // Internal signals
    wire          load_condition;
    wire          finish_condition;

    // Assign outputs from the last pipeline stage
    assign cs_n           = cs_n_stage6;
    assign sclk           = sclk_stage6;
    assign mosi           = tx_shift_stage6[7];
    assign dma_ready_out  = dma_ready_out_stage6;
    assign dma_data_out   = dma_data_out_stage6;
    assign dma_valid_out  = dma_valid_out_stage6;
    assign transfer_busy  = transfer_busy_stage6;
    assign transfer_done  = transfer_done_stage6;

    // Pipeline flush logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flush_stage1 <= 1'b0;
            flush_stage2 <= 1'b0;
            flush_stage3 <= 1'b0;
            flush_stage4 <= 1'b0;
            flush_stage5 <= 1'b0;
            flush_stage6 <= 1'b0;
        end else begin
            flush_stage1 <= (~rst_n);
            flush_stage2 <= flush_stage1;
            flush_stage3 <= flush_stage2;
            flush_stage4 <= flush_stage3;
            flush_stage5 <= flush_stage4;
            flush_stage6 <= flush_stage5;
        end
    end

    // Pipeline stage 1: FSM state transition, transfer start
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1           <= IDLE;
            tx_shift_stage1        <= 8'h00;
            rx_shift_stage1        <= 8'h00;
            bit_count_stage1       <= 3'd0;
            byte_count_stage1      <= 16'd0;
            cs_n_stage1            <= 1'b1;
            sclk_stage1            <= 1'b0;
            transfer_busy_stage1   <= 1'b0;
            transfer_done_stage1   <= 1'b0;
            dma_ready_out_stage1   <= 1'b0;
            dma_valid_out_stage1   <= 1'b0;
            dma_data_out_stage1    <= 8'h00;
            valid_stage1           <= 1'b0;
        end else begin
            if (flush_stage1) begin
                state_stage1           <= IDLE;
                tx_shift_stage1        <= 8'h00;
                rx_shift_stage1        <= 8'h00;
                bit_count_stage1       <= 3'd0;
                byte_count_stage1      <= 16'd0;
                cs_n_stage1            <= 1'b1;
                sclk_stage1            <= 1'b0;
                transfer_busy_stage1   <= 1'b0;
                transfer_done_stage1   <= 1'b0;
                dma_ready_out_stage1   <= 1'b0;
                dma_valid_out_stage1   <= 1'b0;
                dma_data_out_stage1    <= 8'h00;
                valid_stage1           <= 1'b0;
            end else begin
                case (state_stage1)
                    IDLE: begin
                        if (transfer_start) begin
                            state_stage1           <= LOAD;
                            transfer_busy_stage1   <= 1'b1;
                            transfer_done_stage1   <= 1'b0;
                            byte_count_stage1      <= transfer_length;
                            cs_n_stage1            <= 1'b0;
                            dma_ready_out_stage1   <= 1'b1;
                            valid_stage1           <= 1'b1;
                        end else begin
                            state_stage1           <= IDLE;
                            transfer_busy_stage1   <= 1'b0;
                            transfer_done_stage1   <= 1'b0;
                            cs_n_stage1            <= 1'b1;
                            dma_ready_out_stage1   <= 1'b0;
                            valid_stage1           <= 1'b0;
                        end
                        tx_shift_stage1        <= 8'h00;
                        rx_shift_stage1        <= 8'h00;
                        bit_count_stage1       <= 3'd0;
                        sclk_stage1            <= 1'b0;
                        dma_valid_out_stage1   <= 1'b0;
                        dma_data_out_stage1    <= 8'h00;
                    end
                    LOAD: begin
                        state_stage1           <= LOAD;
                        valid_stage1           <= 1'b1;
                        tx_shift_stage1        <= tx_shift_stage1;
                        rx_shift_stage1        <= rx_shift_stage1;
                        bit_count_stage1       <= bit_count_stage1;
                        cs_n_stage1            <= cs_n_stage1;
                        sclk_stage1            <= sclk_stage1;
                        dma_ready_out_stage1   <= dma_ready_out_stage1;
                        dma_valid_out_stage1   <= dma_valid_out_stage1;
                        dma_data_out_stage1    <= dma_data_out_stage1;
                    end
                    default: begin
                        state_stage1           <= state_stage1;
                        tx_shift_stage1        <= tx_shift_stage1;
                        rx_shift_stage1        <= rx_shift_stage1;
                        bit_count_stage1       <= bit_count_stage1;
                        byte_count_stage1      <= byte_count_stage1;
                        cs_n_stage1            <= cs_n_stage1;
                        sclk_stage1            <= sclk_stage1;
                        transfer_busy_stage1   <= transfer_busy_stage1;
                        transfer_done_stage1   <= transfer_done_stage1;
                        dma_ready_out_stage1   <= dma_ready_out_stage1;
                        dma_valid_out_stage1   <= dma_valid_out_stage1;
                        dma_data_out_stage1    <= dma_data_out_stage1;
                        valid_stage1           <= valid_stage1;
                    end
                endcase
            end
        end
    end

    // Pipeline stage 2: Handle LOAD state and input latching
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2           <= IDLE;
            tx_shift_stage2        <= 8'h00;
            rx_shift_stage2        <= 8'h00;
            bit_count_stage2       <= 3'd0;
            byte_count_stage2      <= 16'd0;
            cs_n_stage2            <= 1'b1;
            sclk_stage2            <= 1'b0;
            transfer_busy_stage2   <= 1'b0;
            transfer_done_stage2   <= 1'b0;
            dma_ready_out_stage2   <= 1'b0;
            dma_valid_out_stage2   <= 1'b0;
            dma_data_out_stage2    <= 8'h00;
            valid_stage2           <= 1'b0;
        end else begin
            if (flush_stage2) begin
                state_stage2           <= IDLE;
                tx_shift_stage2        <= 8'h00;
                rx_shift_stage2        <= 8'h00;
                bit_count_stage2       <= 3'd0;
                byte_count_stage2      <= 16'd0;
                cs_n_stage2            <= 1'b1;
                sclk_stage2            <= 1'b0;
                transfer_busy_stage2   <= 1'b0;
                transfer_done_stage2   <= 1'b0;
                dma_ready_out_stage2   <= 1'b0;
                dma_valid_out_stage2   <= 1'b0;
                dma_data_out_stage2    <= 8'h00;
                valid_stage2           <= 1'b0;
            end else if (valid_stage1) begin
                state_stage2           <= state_stage1;
                tx_shift_stage2        <= tx_shift_stage1;
                rx_shift_stage2        <= rx_shift_stage1;
                bit_count_stage2       <= bit_count_stage1;
                byte_count_stage2      <= byte_count_stage1;
                cs_n_stage2            <= cs_n_stage1;
                sclk_stage2            <= sclk_stage1;
                transfer_busy_stage2   <= transfer_busy_stage1;
                transfer_done_stage2   <= transfer_done_stage1;
                dma_ready_out_stage2   <= dma_ready_out_stage1;
                dma_valid_out_stage2   <= dma_valid_out_stage1;
                dma_data_out_stage2    <= dma_data_out_stage1;
                valid_stage2           <= valid_stage1;

                if (state_stage1 == LOAD && dma_valid_in && dma_ready_out_stage1) begin
                    tx_shift_stage2        <= dma_data_in;
                    bit_count_stage2       <= 3'd7;
                    dma_ready_out_stage2   <= 1'b0;
                    state_stage2           <= SHIFT_OUT;
                end
            end else begin
                valid_stage2           <= 1'b0;
            end
        end
    end

    // Pipeline stage 3: SHIFT_OUT - SPI shift out logic (split into two stages for higher freq)
    reg sclk_toggle_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage3           <= IDLE;
            tx_shift_stage3        <= 8'h00;
            rx_shift_stage3        <= 8'h00;
            bit_count_stage3       <= 3'd0;
            byte_count_stage3      <= 16'd0;
            cs_n_stage3            <= 1'b1;
            sclk_stage3            <= 1'b0;
            transfer_busy_stage3   <= 1'b0;
            transfer_done_stage3   <= 1'b0;
            dma_ready_out_stage3   <= 1'b0;
            dma_valid_out_stage3   <= 1'b0;
            dma_data_out_stage3    <= 8'h00;
            valid_stage3           <= 1'b0;
            sclk_toggle_stage3     <= 1'b0;
        end else begin
            if (flush_stage3) begin
                state_stage3           <= IDLE;
                tx_shift_stage3        <= 8'h00;
                rx_shift_stage3        <= 8'h00;
                bit_count_stage3       <= 3'd0;
                byte_count_stage3      <= 16'd0;
                cs_n_stage3            <= 1'b1;
                sclk_stage3            <= 1'b0;
                transfer_busy_stage3   <= 1'b0;
                transfer_done_stage3   <= 1'b0;
                dma_ready_out_stage3   <= 1'b0;
                dma_valid_out_stage3   <= 1'b0;
                dma_data_out_stage3    <= 8'h00;
                valid_stage3           <= 1'b0;
                sclk_toggle_stage3     <= 1'b0;
            end else if (valid_stage2) begin
                state_stage3           <= state_stage2;
                tx_shift_stage3        <= tx_shift_stage2;
                rx_shift_stage3        <= rx_shift_stage2;
                bit_count_stage3       <= bit_count_stage2;
                byte_count_stage3      <= byte_count_stage2;
                cs_n_stage3            <= cs_n_stage2;
                sclk_stage3            <= sclk_stage2;
                transfer_busy_stage3   <= transfer_busy_stage2;
                transfer_done_stage3   <= transfer_done_stage2;
                dma_ready_out_stage3   <= dma_ready_out_stage2;
                dma_valid_out_stage3   <= dma_valid_out_stage2;
                dma_data_out_stage3    <= dma_data_out_stage2;
                valid_stage3           <= valid_stage2;
                sclk_toggle_stage3     <= 1'b0;

                if (state_stage2 == SHIFT_OUT) begin
                    sclk_toggle_stage3     <= 1'b1;
                    sclk_stage3            <= ~sclk_stage2;
                end
            end else begin
                valid_stage3           <= 1'b0;
            end
        end
    end

    // Pipeline stage 4: SHIFT_OUT (continued) - shift register and bit count update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage4           <= IDLE;
            tx_shift_stage4        <= 8'h00;
            rx_shift_stage4        <= 8'h00;
            bit_count_stage4       <= 3'd0;
            byte_count_stage4      <= 16'd0;
            cs_n_stage4            <= 1'b1;
            sclk_stage4            <= 1'b0;
            transfer_busy_stage4   <= 1'b0;
            transfer_done_stage4   <= 1'b0;
            dma_ready_out_stage4   <= 1'b0;
            dma_valid_out_stage4   <= 1'b0;
            dma_data_out_stage4    <= 8'h00;
            valid_stage4           <= 1'b0;
        end else begin
            if (flush_stage4) begin
                state_stage4           <= IDLE;
                tx_shift_stage4        <= 8'h00;
                rx_shift_stage4        <= 8'h00;
                bit_count_stage4       <= 3'd0;
                byte_count_stage4      <= 16'd0;
                cs_n_stage4            <= 1'b1;
                sclk_stage4            <= 1'b0;
                transfer_busy_stage4   <= 1'b0;
                transfer_done_stage4   <= 1'b0;
                dma_ready_out_stage4   <= 1'b0;
                dma_valid_out_stage4   <= 1'b0;
                dma_data_out_stage4    <= 8'h00;
                valid_stage4           <= 1'b0;
            end else if (valid_stage3) begin
                state_stage4           <= state_stage3;
                tx_shift_stage4        <= tx_shift_stage3;
                rx_shift_stage4        <= rx_shift_stage3;
                bit_count_stage4       <= bit_count_stage3;
                byte_count_stage4      <= byte_count_stage3;
                cs_n_stage4            <= cs_n_stage3;
                sclk_stage4            <= sclk_stage3;
                transfer_busy_stage4   <= transfer_busy_stage3;
                transfer_done_stage4   <= transfer_done_stage3;
                dma_ready_out_stage4   <= dma_ready_out_stage3;
                dma_valid_out_stage4   <= dma_valid_out_stage3;
                dma_data_out_stage4    <= dma_data_out_stage3;
                valid_stage4           <= valid_stage3;

                if (state_stage3 == SHIFT_OUT && sclk_stage3) begin
                    tx_shift_stage4        <= {tx_shift_stage3[6:0], 1'b0};
                    bit_count_stage4       <= bit_count_stage3 - 3'd1;
                    if (bit_count_stage3 == 3'd0) begin
                        state_stage4           <= SHIFT_IN;
                    end
                end
            end else begin
                valid_stage4           <= 1'b0;
            end
        end
    end

    // Pipeline stage 5: SHIFT_IN - sample MISO and store in shift register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage5           <= IDLE;
            tx_shift_stage5        <= 8'h00;
            rx_shift_stage5        <= 8'h00;
            bit_count_stage5       <= 3'd0;
            byte_count_stage5      <= 16'd0;
            cs_n_stage5            <= 1'b1;
            sclk_stage5            <= 1'b0;
            transfer_busy_stage5   <= 1'b0;
            transfer_done_stage5   <= 1'b0;
            dma_ready_out_stage5   <= 1'b0;
            dma_valid_out_stage5   <= 1'b0;
            dma_data_out_stage5    <= 8'h00;
            valid_stage5           <= 1'b0;
        end else begin
            if (flush_stage5) begin
                state_stage5           <= IDLE;
                tx_shift_stage5        <= 8'h00;
                rx_shift_stage5        <= 8'h00;
                bit_count_stage5       <= 3'd0;
                byte_count_stage5      <= 16'd0;
                cs_n_stage5            <= 1'b1;
                sclk_stage5            <= 1'b0;
                transfer_busy_stage5   <= 1'b0;
                transfer_done_stage5   <= 1'b0;
                dma_ready_out_stage5   <= 1'b0;
                dma_valid_out_stage5   <= 1'b0;
                dma_data_out_stage5    <= 8'h00;
                valid_stage5           <= 1'b0;
            end else if (valid_stage4) begin
                state_stage5           <= state_stage4;
                tx_shift_stage5        <= tx_shift_stage4;
                rx_shift_stage5        <= rx_shift_stage4;
                bit_count_stage5       <= bit_count_stage4;
                byte_count_stage5      <= byte_count_stage4;
                cs_n_stage5            <= cs_n_stage4;
                sclk_stage5            <= sclk_stage4;
                transfer_busy_stage5   <= transfer_busy_stage4;
                transfer_done_stage5   <= transfer_done_stage4;
                dma_ready_out_stage5   <= dma_ready_out_stage4;
                dma_valid_out_stage5   <= dma_valid_out_stage4;
                dma_data_out_stage5    <= dma_data_out_stage4;
                valid_stage5           <= valid_stage4;

                if (state_stage4 == SHIFT_IN) begin
                    rx_shift_stage5        <= {rx_shift_stage4[6:0], miso};
                    if (bit_count_stage4 == 3'd0) begin
                        state_stage5           <= STORE;
                    end
                end
            end else begin
                valid_stage5           <= 1'b0;
            end
        end
    end

    // Pipeline stage 6: STORE or FINISH - DMA output and byte count update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage6           <= IDLE;
            tx_shift_stage6        <= 8'h00;
            rx_shift_stage6        <= 8'h00;
            bit_count_stage6       <= 3'd0;
            byte_count_stage6      <= 16'd0;
            cs_n_stage6            <= 1'b1;
            sclk_stage6            <= 1'b0;
            transfer_busy_stage6   <= 1'b0;
            transfer_done_stage6   <= 1'b0;
            dma_ready_out_stage6   <= 1'b0;
            dma_valid_out_stage6   <= 1'b0;
            dma_data_out_stage6    <= 8'h00;
            valid_stage6           <= 1'b0;
        end else begin
            if (flush_stage6) begin
                state_stage6           <= IDLE;
                tx_shift_stage6        <= 8'h00;
                rx_shift_stage6        <= 8'h00;
                bit_count_stage6       <= 3'd0;
                byte_count_stage6      <= 16'd0;
                cs_n_stage6            <= 1'b1;
                sclk_stage6            <= 1'b0;
                transfer_busy_stage6   <= 1'b0;
                transfer_done_stage6   <= 1'b0;
                dma_ready_out_stage6   <= 1'b0;
                dma_valid_out_stage6   <= 1'b0;
                dma_data_out_stage6    <= 8'h00;
                valid_stage6           <= 1'b0;
            end else if (valid_stage5) begin
                state_stage6           <= state_stage5;
                tx_shift_stage6        <= tx_shift_stage5;
                rx_shift_stage6        <= rx_shift_stage5;
                bit_count_stage6       <= bit_count_stage5;
                byte_count_stage6      <= byte_count_stage5;
                cs_n_stage6            <= cs_n_stage5;
                sclk_stage6            <= sclk_stage5;
                transfer_busy_stage6   <= transfer_busy_stage5;
                transfer_done_stage6   <= transfer_done_stage5;
                dma_ready_out_stage6   <= dma_ready_out_stage5;
                dma_valid_out_stage6   <= dma_valid_out_stage5;
                dma_data_out_stage6    <= dma_data_out_stage5;
                valid_stage6           <= valid_stage5;

                if (state_stage5 == STORE) begin
                    dma_valid_out_stage6   <= 1'b1;
                    dma_data_out_stage6    <= rx_shift_stage5;
                    dma_ready_out_stage6   <= 1'b0;
                    if (byte_count_stage5 == 16'd1) begin
                        state_stage6           <= FINISH;
                        cs_n_stage6            <= 1'b1;
                        transfer_busy_stage6   <= 1'b0;
                        transfer_done_stage6   <= 1'b1;
                    end else begin
                        state_stage6           <= LOAD;
                        byte_count_stage6      <= byte_count_stage5 - 16'd1;
                        dma_ready_out_stage6   <= 1'b1;
                        transfer_done_stage6   <= 1'b0;
                    end
                end else if (state_stage5 == FINISH) begin
                    cs_n_stage6              <= 1'b1;
                    transfer_busy_stage6     <= 1'b0;
                    transfer_done_stage6     <= 1'b1;
                    state_stage6             <= IDLE;
                end
            end else begin
                valid_stage6           <= 1'b0;
            end
        end
    end

endmodule