//SystemVerilog
module quad_spi_controller #(
    parameter ADDR_WIDTH = 24
)(
    input                   clk,
    input                   reset_n,
    input                   start,
    input                   write_en,
    input       [7:0]       cmd,
    input       [ADDR_WIDTH-1:0] addr,
    input       [7:0]       write_data,
    output reg  [7:0]       read_data,
    output reg              busy,
    output reg              done,

    // Quad SPI interface
    output reg              spi_clk,
    output reg              spi_cs_n,
    inout       [3:0]       spi_io
);

    localparam IDLE    = 3'd0,
               CMD     = 3'd1,
               ADDR    = 3'd2,
               DATA_W  = 3'd3,
               DATA_R  = 3'd4,
               END     = 3'd5;

    // FSM state and control signals
    reg [2:0]  state_stage1;
    reg [2:0]  state_stage2, state_stage3, state_stage4, state_stage5;
    reg        busy_stage1, busy_stage2, busy_stage3, busy_stage4, busy_stage5;
    reg        done_stage1, done_stage2, done_stage3, done_stage4, done_stage5;
    reg        start_stage1, start_stage2, start_stage3, start_stage4, start_stage5;
    reg        write_en_stage1, write_en_stage2, write_en_stage3, write_en_stage4, write_en_stage5;
    reg [7:0]  cmd_stage1, cmd_stage2, cmd_stage3, cmd_stage4, cmd_stage5;
    reg [ADDR_WIDTH-1:0] addr_stage1, addr_stage2, addr_stage3, addr_stage4, addr_stage5;
    reg [7:0]  write_data_stage1, write_data_stage2, write_data_stage3, write_data_stage4, write_data_stage5;
    reg        valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    reg        flush_pipeline;

    // Bit count and data out
    reg [4:0]  bit_count_stage2, bit_count_stage3, bit_count_stage4, bit_count_stage5;
    reg [7:0]  data_out_stage2, data_out_stage3, data_out_stage4, data_out_stage5;

    // IO control
    reg [3:0]  io_out_stage3, io_out_stage4, io_out_stage5;
    reg [3:0]  io_oe_stage3, io_oe_stage4, io_oe_stage5;

    // SPI interface
    reg        spi_cs_n_stage4, spi_cs_n_stage5;
    reg        spi_clk_stage4, spi_clk_stage5;

    // Read data
    reg [7:0]  read_data_stage5;

    // Tri-state outputs
    wire [3:0] spi_io_oe;
    wire [3:0] spi_io_out;

    assign spi_io[0] = spi_io_oe[0] ? spi_io_out[0] : 1'bz;
    assign spi_io[1] = spi_io_oe[1] ? spi_io_out[1] : 1'bz;
    assign spi_io[2] = spi_io_oe[2] ? spi_io_out[2] : 1'bz;
    assign spi_io[3] = spi_io_oe[3] ? spi_io_out[3] : 1'bz;

    assign spi_io_oe  = io_oe_stage5;
    assign spi_io_out = io_out_stage5;

    // FSM: Next state and control logic
    reg [2:0] fsm_next_state;
    reg       fsm_busy;
    reg       fsm_done;
    reg       fsm_flush_pipeline;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_stage1    <= IDLE;
        end else begin
            state_stage1    <= fsm_next_state;
        end
    end

    always @(*) begin
        fsm_next_state = state_stage1;
        fsm_busy       = busy_stage1;
        fsm_done       = done_stage1;
        fsm_flush_pipeline = 1'b0;
        case (state_stage1)
            IDLE: begin
                if (start) begin
                    fsm_next_state = CMD;
                    fsm_busy       = 1'b1;
                    fsm_done       = 1'b0;
                end
            end
            CMD: begin
                fsm_next_state = ADDR;
            end
            ADDR: begin
                fsm_next_state = write_en_stage1 ? DATA_W : DATA_R;
            end
            DATA_W: begin
                fsm_next_state = END;
            end
            DATA_R: begin
                fsm_next_state = END;
            end
            END: begin
                fsm_next_state = IDLE;
                fsm_busy       = 1'b0;
                fsm_done       = 1'b1;
                fsm_flush_pipeline = 1'b1;
            end
            default: begin
                fsm_next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy_stage1         <= 1'b0;
        end else begin
            busy_stage1         <= fsm_busy;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            done_stage1         <= 1'b0;
        end else begin
            done_stage1         <= fsm_done;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            flush_pipeline      <= 1'b0;
        end else begin
            flush_pipeline      <= fsm_flush_pipeline;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            start_stage1        <= 1'b0;
            write_en_stage1     <= 1'b0;
            cmd_stage1          <= 8'd0;
            addr_stage1         <= {ADDR_WIDTH{1'b0}};
            write_data_stage1   <= 8'd0;
            valid_stage1        <= 1'b0;
        end else begin
            start_stage1        <= start;
            write_en_stage1     <= write_en;
            cmd_stage1          <= cmd;
            addr_stage1         <= addr;
            write_data_stage1   <= write_data;
            valid_stage1        <= 1'b1;
        end
    end

    // Pipeline Register Stage 1 -> Stage 2
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n || flush_pipeline) begin
            state_stage2        <= IDLE;
            busy_stage2         <= 1'b0;
            done_stage2         <= 1'b0;
            start_stage2        <= 1'b0;
            write_en_stage2     <= 1'b0;
            cmd_stage2          <= 8'd0;
            addr_stage2         <= {ADDR_WIDTH{1'b0}};
            write_data_stage2   <= 8'd0;
            valid_stage2        <= 1'b0;
            bit_count_stage2    <= 5'd0;
            data_out_stage2     <= 8'd0;
        end else if (valid_stage1) begin
            state_stage2        <= state_stage1;
            busy_stage2         <= busy_stage1;
            done_stage2         <= done_stage1;
            start_stage2        <= start_stage1;
            write_en_stage2     <= write_en_stage1;
            cmd_stage2          <= cmd_stage1;
            addr_stage2         <= addr_stage1;
            write_data_stage2   <= write_data_stage1;
            valid_stage2        <= valid_stage1;

            case (state_stage1)
                IDLE: begin
                    bit_count_stage2    <= 5'd7;
                    data_out_stage2     <= cmd_stage1;
                end
                CMD: begin
                    bit_count_stage2    <= 5'd7;
                    data_out_stage2     <= cmd_stage1;
                end
                ADDR: begin
                    bit_count_stage2    <= ADDR_WIDTH-1;
                    data_out_stage2     <= 8'd0;
                end
                DATA_W: begin
                    bit_count_stage2    <= 5'd7;
                    data_out_stage2     <= write_data_stage1;
                end
                DATA_R: begin
                    bit_count_stage2    <= 5'd7;
                    data_out_stage2     <= 8'd0;
                end
                END: begin
                    bit_count_stage2    <= 5'd0;
                    data_out_stage2     <= 8'd0;
                end
                default: begin
                    bit_count_stage2    <= 5'd0;
                    data_out_stage2     <= 8'd0;
                end
            endcase
        end
    end

    // Pipeline Register Stage 2 -> Stage 3
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n || flush_pipeline) begin
            state_stage3        <= IDLE;
            busy_stage3         <= 1'b0;
            done_stage3         <= 1'b0;
            start_stage3        <= 1'b0;
            write_en_stage3     <= 1'b0;
            cmd_stage3          <= 8'd0;
            addr_stage3         <= {ADDR_WIDTH{1'b0}};
            write_data_stage3   <= 8'd0;
            valid_stage3        <= 1'b0;
            bit_count_stage3    <= 5'd0;
            data_out_stage3     <= 8'd0;
            io_out_stage3       <= 4'b0000;
            io_oe_stage3        <= 4'b0000;
        end else if (valid_stage2) begin
            state_stage3        <= state_stage2;
            busy_stage3         <= busy_stage2;
            done_stage3         <= done_stage2;
            start_stage3        <= start_stage2;
            write_en_stage3     <= write_en_stage2;
            cmd_stage3          <= cmd_stage2;
            addr_stage3         <= addr_stage2;
            write_data_stage3   <= write_data_stage2;
            valid_stage3        <= valid_stage2;
            bit_count_stage3    <= bit_count_stage2;
            data_out_stage3     <= data_out_stage2;

            case (state_stage2)
                IDLE: begin
                    io_oe_stage3    <= 4'b0000;
                    io_out_stage3   <= 4'b0000;
                end
                CMD: begin
                    io_oe_stage3    <= 4'b0001;
                    io_out_stage3[0]<= data_out_stage2[bit_count_stage2];
                    io_out_stage3[3:1]<=3'b000;
                end
                ADDR: begin
                    io_oe_stage3    <= 4'b0001;
                    io_out_stage3[0]<= addr_stage2[bit_count_stage2];
                    io_out_stage3[3:1]<=3'b000;
                end
                DATA_W: begin
                    io_oe_stage3    <= 4'b0001;
                    io_out_stage3[0]<= write_data_stage2[bit_count_stage2];
                    io_out_stage3[3:1]<=3'b000;
                end
                DATA_R: begin
                    io_oe_stage3    <= 4'b0000;
                    io_out_stage3   <= 4'b0000;
                end
                END: begin
                    io_oe_stage3    <= 4'b0000;
                    io_out_stage3   <= 4'b0000;
                end
                default: begin
                    io_oe_stage3    <= 4'b0000;
                    io_out_stage3   <= 4'b0000;
                end
            endcase
        end
    end

    // Pipeline Register Stage 3 -> Stage 4
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n || flush_pipeline) begin
            state_stage4        <= IDLE;
            busy_stage4         <= 1'b0;
            done_stage4         <= 1'b0;
            start_stage4        <= 1'b0;
            write_en_stage4     <= 1'b0;
            cmd_stage4          <= 8'd0;
            addr_stage4         <= {ADDR_WIDTH{1'b0}};
            write_data_stage4   <= 8'd0;
            valid_stage4        <= 1'b0;
            bit_count_stage4    <= 5'd0;
            data_out_stage4     <= 8'd0;
            io_out_stage4       <= 4'b0000;
            io_oe_stage4        <= 4'b0000;
            spi_cs_n_stage4     <= 1'b1;
            spi_clk_stage4      <= 1'b0;
        end else if (valid_stage3) begin
            state_stage4        <= state_stage3;
            busy_stage4         <= busy_stage3;
            done_stage4         <= done_stage3;
            start_stage4        <= start_stage3;
            write_en_stage4     <= write_en_stage3;
            cmd_stage4          <= cmd_stage3;
            addr_stage4         <= addr_stage3;
            write_data_stage4   <= write_data_stage3;
            valid_stage4        <= valid_stage3;
            bit_count_stage4    <= bit_count_stage3;
            data_out_stage4     <= data_out_stage3;
            io_out_stage4       <= io_out_stage3;
            io_oe_stage4        <= io_oe_stage3;

            case (state_stage3)
                IDLE: begin
                    spi_cs_n_stage4 <= 1'b1;
                    spi_clk_stage4  <= 1'b0;
                end
                CMD, ADDR, DATA_W, DATA_R: begin
                    spi_cs_n_stage4 <= 1'b0;
                    spi_clk_stage4  <= ~spi_clk_stage4;
                end
                END: begin
                    spi_cs_n_stage4 <= 1'b1;
                    spi_clk_stage4  <= 1'b0;
                end
                default: begin
                    spi_cs_n_stage4 <= 1'b1;
                    spi_clk_stage4  <= 1'b0;
                end
            endcase
        end
    end

    // Pipeline Register Stage 4 -> Stage 5
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n || flush_pipeline) begin
            state_stage5        <= IDLE;
            busy_stage5         <= 1'b0;
            done_stage5         <= 1'b0;
            start_stage5        <= 1'b0;
            write_en_stage5     <= 1'b0;
            cmd_stage5          <= 8'd0;
            addr_stage5         <= {ADDR_WIDTH{1'b0}};
            write_data_stage5   <= 8'd0;
            valid_stage5        <= 1'b0;
            bit_count_stage5    <= 5'd0;
            data_out_stage5     <= 8'd0;
            io_out_stage5       <= 4'b0000;
            io_oe_stage5        <= 4'b0000;
            spi_cs_n_stage5     <= 1'b1;
            spi_clk_stage5      <= 1'b0;
            read_data_stage5    <= 8'd0;
        end else if (valid_stage4) begin
            state_stage5        <= state_stage4;
            busy_stage5         <= busy_stage4;
            done_stage5         <= done_stage4;
            start_stage5        <= start_stage4;
            write_en_stage5     <= write_en_stage4;
            cmd_stage5          <= cmd_stage4;
            addr_stage5         <= addr_stage4;
            write_data_stage5   <= write_data_stage4;
            valid_stage5        <= valid_stage4;
            bit_count_stage5    <= bit_count_stage4;
            io_out_stage5       <= io_out_stage4;
            io_oe_stage5        <= io_oe_stage4;
            spi_cs_n_stage5     <= spi_cs_n_stage4;
            spi_clk_stage5      <= spi_clk_stage4;

            if(state_stage4 == DATA_R) begin
                data_out_stage5 <= {data_out_stage4[6:0], spi_io[1]};
                if(bit_count_stage4 == 0) begin
                    read_data_stage5 <= {data_out_stage4[6:0], spi_io[1]};
                end
            end else begin
                data_out_stage5 <= data_out_stage4;
            end
        end
    end

    // Output assignments: spi_cs_n
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_cs_n    <= 1'b1;
        end else begin
            spi_cs_n    <= spi_cs_n_stage5;
        end
    end

    // Output assignments: spi_clk
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_clk     <= 1'b0;
        end else begin
            spi_clk     <= spi_clk_stage5;
        end
    end

    // Output assignments: busy
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy        <= 1'b0;
        end else begin
            busy        <= busy_stage5;
        end
    end

    // Output assignments: done
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            done        <= 1'b0;
        end else begin
            done        <= done_stage5;
        end
    end

    // Output assignments: read_data
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            read_data   <= 8'd0;
        end else begin
            if(state_stage5 == DATA_R && bit_count_stage5 == 0)
                read_data <= read_data_stage5;
            else if(state_stage5 == END)
                read_data <= read_data_stage5;
        end
    end

endmodule