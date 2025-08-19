//SystemVerilog
module i2c_clock_stretch_master(
    input  wire         clock,
    input  wire         reset,
    input  wire         start_transfer,
    input  wire [6:0]   target_address,
    input  wire         read_notwrite,
    input  wire [7:0]   write_byte,
    output reg  [7:0]   read_byte,
    output reg          transfer_done,
    output reg          error,
    inout  wire         sda,
    inout  wire         scl
);

    // FSM states
    localparam FSM_IDLE        = 4'd0;
    localparam FSM_START       = 4'd1;
    localparam FSM_ADDR        = 4'd2;
    localparam FSM_RW          = 4'd3;
    localparam FSM_WRITE       = 4'd4;
    localparam FSM_READ        = 4'd5;
    localparam FSM_ACK         = 4'd6;
    localparam FSM_STOP        = 4'd7;
    localparam FSM_DONE        = 4'd8;
    localparam FSM_ERROR       = 4'd9;

    // Pipeline stage registers (now 5 stages)
    reg [3:0] fsm_stage1, fsm_stage2, fsm_stage3, fsm_stage4, fsm_stage5;
    reg       fsm_valid_stage1, fsm_valid_stage2, fsm_valid_stage3, fsm_valid_stage4, fsm_valid_stage5;
    reg       fsm_flush_stage1, fsm_flush_stage2, fsm_flush_stage3, fsm_flush_stage4, fsm_flush_stage5;

    reg       scl_enable_stage1, scl_enable_stage2, scl_enable_stage3, scl_enable_stage4, scl_enable_stage5;
    reg       sda_enable_stage1, sda_enable_stage2, sda_enable_stage3, sda_enable_stage4, sda_enable_stage5;
    reg       sda_out_stage1,    sda_out_stage2,    sda_out_stage3,    sda_out_stage4,    sda_out_stage5;
    reg [3:0] bit_index_stage1,  bit_index_stage2,  bit_index_stage3,  bit_index_stage4,  bit_index_stage5;
    reg [7:0] shift_reg_stage1,  shift_reg_stage2,  shift_reg_stage3,  shift_reg_stage4,  shift_reg_stage5;
    reg       rw_stage1,         rw_stage2,         rw_stage3,         rw_stage4,         rw_stage5;
    reg [6:0] addr_stage1,       addr_stage2,       addr_stage3,       addr_stage4,       addr_stage5;
    reg [7:0] write_byte_stage1, write_byte_stage2, write_byte_stage3, write_byte_stage4, write_byte_stage5;
    reg       transfer_done_stage5, error_stage5;

    // Output drivers (from last stage)
    assign scl = scl_enable_stage5 ? 1'b0 : 1'bz;
    assign sda = sda_enable_stage5 ? sda_out_stage5 : 1'bz;

    wire scl_stretched = !scl && !scl_enable_stage5;

    // Pipeline flush logic
    wire pipeline_flush = reset || fsm_flush_stage5;

    // Pipeline stage 1: FSM state, start/idle, basic control
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            fsm_stage1         <= FSM_IDLE;
            fsm_valid_stage1   <= 1'b0;
            scl_enable_stage1  <= 1'b0;
            sda_enable_stage1  <= 1'b0;
            sda_out_stage1     <= 1'b1;
            bit_index_stage1   <= 4'd0;
            shift_reg_stage1   <= 8'd0;
            rw_stage1          <= 1'b0;
            addr_stage1        <= 7'd0;
            write_byte_stage1  <= 8'd0;
            fsm_flush_stage1   <= 1'b0;
        end else begin
            if (scl_stretched && fsm_stage1 != FSM_IDLE) begin
                fsm_stage1         <= fsm_stage1;
                fsm_valid_stage1   <= fsm_valid_stage1;
                scl_enable_stage1  <= scl_enable_stage1;
                sda_enable_stage1  <= sda_enable_stage1;
                sda_out_stage1     <= sda_out_stage1;
                bit_index_stage1   <= bit_index_stage1;
                shift_reg_stage1   <= shift_reg_stage1;
                rw_stage1          <= rw_stage1;
                addr_stage1        <= addr_stage1;
                write_byte_stage1  <= write_byte_stage1;
                fsm_flush_stage1   <= fsm_flush_stage1;
            end else begin
                case (fsm_stage1)
                    FSM_IDLE: begin
                        if (start_transfer) begin
                            fsm_stage1         <= FSM_START;
                            fsm_valid_stage1   <= 1'b1;
                            scl_enable_stage1  <= 1'b1;
                            sda_enable_stage1  <= 1'b1;
                            sda_out_stage1     <= 1'b1;
                            bit_index_stage1   <= 4'd7;
                            shift_reg_stage1   <= {target_address, read_notwrite};
                            rw_stage1          <= read_notwrite;
                            addr_stage1        <= target_address;
                            write_byte_stage1  <= write_byte;
                            fsm_flush_stage1   <= 1'b0;
                        end else begin
                            fsm_stage1         <= FSM_IDLE;
                            fsm_valid_stage1   <= 1'b0;
                            scl_enable_stage1  <= 1'b0;
                            sda_enable_stage1  <= 1'b0;
                            sda_out_stage1     <= 1'b1;
                            bit_index_stage1   <= 4'd0;
                            shift_reg_stage1   <= 8'd0;
                            rw_stage1          <= 1'b0;
                            addr_stage1        <= 7'd0;
                            write_byte_stage1  <= 8'd0;
                            fsm_flush_stage1   <= 1'b0;
                        end
                    end
                    FSM_START: begin
                        fsm_stage1         <= FSM_ADDR;
                        fsm_valid_stage1   <= 1'b1;
                        scl_enable_stage1  <= 1'b1;
                        sda_enable_stage1  <= 1'b1;
                        sda_out_stage1     <= 1'b0;
                        bit_index_stage1   <= 4'd7;
                        shift_reg_stage1   <= {addr_stage1, rw_stage1};
                        rw_stage1          <= rw_stage1;
                        addr_stage1        <= addr_stage1;
                        write_byte_stage1  <= write_byte_stage1;
                        fsm_flush_stage1   <= 1'b0;
                    end
                    default: begin
                        fsm_stage1         <= fsm_stage1;
                        fsm_valid_stage1   <= fsm_valid_stage1;
                        scl_enable_stage1  <= scl_enable_stage1;
                        sda_enable_stage1  <= sda_enable_stage1;
                        sda_out_stage1     <= sda_out_stage1;
                        bit_index_stage1   <= bit_index_stage1;
                        shift_reg_stage1   <= shift_reg_stage1;
                        rw_stage1          <= rw_stage1;
                        addr_stage1        <= addr_stage1;
                        write_byte_stage1  <= write_byte_stage1;
                        fsm_flush_stage1   <= fsm_flush_stage1;
                    end
                endcase
            end
        end
    end

    // Pipeline stage 2: Address/data bit output control and FSM transition
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            fsm_stage2         <= FSM_IDLE;
            fsm_valid_stage2   <= 1'b0;
            scl_enable_stage2  <= 1'b0;
            sda_enable_stage2  <= 1'b0;
            sda_out_stage2     <= 1'b1;
            bit_index_stage2   <= 4'd0;
            shift_reg_stage2   <= 8'd0;
            rw_stage2          <= 1'b0;
            addr_stage2        <= 7'd0;
            write_byte_stage2  <= 8'd0;
            fsm_flush_stage2   <= 1'b0;
        end else if (pipeline_flush) begin
            fsm_stage2         <= FSM_IDLE;
            fsm_valid_stage2   <= 1'b0;
            scl_enable_stage2  <= 1'b0;
            sda_enable_stage2  <= 1'b0;
            sda_out_stage2     <= 1'b1;
            bit_index_stage2   <= 4'd0;
            shift_reg_stage2   <= 8'd0;
            rw_stage2          <= 1'b0;
            addr_stage2        <= 7'd0;
            write_byte_stage2  <= 8'd0;
            fsm_flush_stage2   <= 1'b0;
        end else begin
            fsm_stage2         <= fsm_stage1;
            fsm_valid_stage2   <= fsm_valid_stage1;
            scl_enable_stage2  <= scl_enable_stage1;
            sda_enable_stage2  <= sda_enable_stage1;
            sda_out_stage2     <= sda_out_stage1;
            bit_index_stage2   <= bit_index_stage1;
            shift_reg_stage2   <= shift_reg_stage1;
            rw_stage2          <= rw_stage1;
            addr_stage2        <= addr_stage1;
            write_byte_stage2  <= write_byte_stage1;
            fsm_flush_stage2   <= fsm_flush_stage1;

            if (fsm_valid_stage1) begin
                case (fsm_stage1)
                    FSM_ADDR: begin
                        if (bit_index_stage1 == 4'd0) begin
                            fsm_stage2       <= FSM_ACK;
                            scl_enable_stage2<= 1'b0;
                            sda_enable_stage2<= 1'b0;
                            sda_out_stage2   <= 1'b1;
                            bit_index_stage2 <= 4'd7;
                            shift_reg_stage2 <= write_byte_stage1;
                        end else begin
                            fsm_stage2       <= FSM_ADDR;
                            scl_enable_stage2<= ~scl_enable_stage1;
                            sda_enable_stage2<= 1'b1;
                            sda_out_stage2   <= shift_reg_stage1[bit_index_stage1];
                            bit_index_stage2 <= bit_index_stage1 - 1'b1;
                            shift_reg_stage2 <= shift_reg_stage1;
                        end
                    end
                    FSM_WRITE: begin
                        if (bit_index_stage1 == 4'd0) begin
                            fsm_stage2       <= FSM_STOP;
                            scl_enable_stage2<= 1'b0;
                            sda_enable_stage2<= 1'b0;
                            sda_out_stage2   <= 1'b1;
                            bit_index_stage2 <= 4'd0;
                            shift_reg_stage2 <= shift_reg_stage1;
                        end else begin
                            fsm_stage2       <= FSM_WRITE;
                            scl_enable_stage2<= ~scl_enable_stage1;
                            sda_enable_stage2<= 1'b1;
                            sda_out_stage2   <= shift_reg_stage1[bit_index_stage1];
                            bit_index_stage2 <= bit_index_stage1 - 1'b1;
                            shift_reg_stage2 <= shift_reg_stage1;
                        end
                    end
                    FSM_READ: begin
                        if (bit_index_stage1 == 4'd0) begin
                            fsm_stage2       <= FSM_STOP;
                            scl_enable_stage2<= 1'b0;
                            sda_enable_stage2<= 1'b0;
                            sda_out_stage2   <= 1'b1;
                            bit_index_stage2 <= 4'd0;
                            shift_reg_stage2 <= shift_reg_stage1;
                        end else begin
                            fsm_stage2       <= FSM_READ;
                            scl_enable_stage2<= ~scl_enable_stage1;
                            sda_enable_stage2<= 1'b0;
                            sda_out_stage2   <= 1'b1;
                            bit_index_stage2 <= bit_index_stage1 - 1'b1;
                            shift_reg_stage2 <= shift_reg_stage1;
                        end
                    end
                    FSM_ACK: begin
                        fsm_stage2         <= (rw_stage1) ? FSM_READ : FSM_WRITE;
                        scl_enable_stage2  <= 1'b0;
                        sda_enable_stage2  <= 1'b0;
                        sda_out_stage2     <= 1'b1;
                        bit_index_stage2   <= 4'd7;
                        shift_reg_stage2   <= write_byte_stage1;
                    end
                    FSM_STOP: begin
                        fsm_stage2         <= FSM_DONE;
                        scl_enable_stage2  <= 1'b0;
                        sda_enable_stage2  <= 1'b1;
                        sda_out_stage2     <= 1'b1;
                        bit_index_stage2   <= 4'd0;
                        shift_reg_stage2   <= shift_reg_stage1;
                    end
                    FSM_DONE: begin
                        fsm_stage2         <= FSM_IDLE;
                        scl_enable_stage2  <= 1'b0;
                        sda_enable_stage2  <= 1'b0;
                        sda_out_stage2     <= 1'b1;
                        bit_index_stage2   <= 4'd0;
                        shift_reg_stage2   <= shift_reg_stage1;
                        fsm_flush_stage2   <= 1'b1;
                    end
                    FSM_ERROR: begin
                        fsm_stage2         <= FSM_IDLE;
                        scl_enable_stage2  <= 1'b0;
                        sda_enable_stage2  <= 1'b0;
                        sda_out_stage2     <= 1'b1;
                        bit_index_stage2   <= 4'd0;
                        shift_reg_stage2   <= shift_reg_stage1;
                        fsm_flush_stage2   <= 1'b1;
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    // Pipeline stage 3: Read sample for data, address/data bit shift
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            fsm_stage3         <= FSM_IDLE;
            fsm_valid_stage3   <= 1'b0;
            scl_enable_stage3  <= 1'b0;
            sda_enable_stage3  <= 1'b0;
            sda_out_stage3     <= 1'b1;
            bit_index_stage3   <= 4'd0;
            shift_reg_stage3   <= 8'd0;
            rw_stage3          <= 1'b0;
            addr_stage3        <= 7'd0;
            write_byte_stage3  <= 8'd0;
            fsm_flush_stage3   <= 1'b0;
        end else if (pipeline_flush) begin
            fsm_stage3         <= FSM_IDLE;
            fsm_valid_stage3   <= 1'b0;
            scl_enable_stage3  <= 1'b0;
            sda_enable_stage3  <= 1'b0;
            sda_out_stage3     <= 1'b1;
            bit_index_stage3   <= 4'd0;
            shift_reg_stage3   <= 8'd0;
            rw_stage3          <= 1'b0;
            addr_stage3        <= 7'd0;
            write_byte_stage3  <= 8'd0;
            fsm_flush_stage3   <= 1'b0;
        end else begin
            fsm_stage3         <= fsm_stage2;
            fsm_valid_stage3   <= fsm_valid_stage2;
            scl_enable_stage3  <= scl_enable_stage2;
            sda_enable_stage3  <= sda_enable_stage2;
            sda_out_stage3     <= sda_out_stage2;
            bit_index_stage3   <= bit_index_stage2;
            rw_stage3          <= rw_stage2;
            addr_stage3        <= addr_stage2;
            write_byte_stage3  <= write_byte_stage2;
            fsm_flush_stage3   <= fsm_flush_stage2;
            // Data sampling for read operation
            if (fsm_stage2 == FSM_READ && sda_enable_stage2 == 1'b0 && fsm_valid_stage2) begin
                shift_reg_stage3 <= {shift_reg_stage2[6:0], sda};
            end else begin
                shift_reg_stage3 <= shift_reg_stage2;
            end
        end
    end

    // Pipeline stage 4: Output control, error/ack detect, transfer done
    reg ack_error_stage4;
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            fsm_stage4         <= FSM_IDLE;
            fsm_valid_stage4   <= 1'b0;
            scl_enable_stage4  <= 1'b0;
            sda_enable_stage4  <= 1'b0;
            sda_out_stage4     <= 1'b1;
            bit_index_stage4   <= 4'd0;
            shift_reg_stage4   <= 8'd0;
            rw_stage4          <= 1'b0;
            addr_stage4        <= 7'd0;
            write_byte_stage4  <= 8'd0;
            fsm_flush_stage4   <= 1'b0;
            ack_error_stage4   <= 1'b0;
        end else if (pipeline_flush) begin
            fsm_stage4         <= FSM_IDLE;
            fsm_valid_stage4   <= 1'b0;
            scl_enable_stage4  <= 1'b0;
            sda_enable_stage4  <= 1'b0;
            sda_out_stage4     <= 1'b1;
            bit_index_stage4   <= 4'd0;
            shift_reg_stage4   <= 8'd0;
            rw_stage4          <= 1'b0;
            addr_stage4        <= 7'd0;
            write_byte_stage4  <= 8'd0;
            fsm_flush_stage4   <= 1'b0;
            ack_error_stage4   <= 1'b0;
        end else begin
            fsm_stage4         <= fsm_stage3;
            fsm_valid_stage4   <= fsm_valid_stage3;
            scl_enable_stage4  <= scl_enable_stage3;
            sda_enable_stage4  <= sda_enable_stage3;
            sda_out_stage4     <= sda_out_stage3;
            bit_index_stage4   <= bit_index_stage3;
            shift_reg_stage4   <= shift_reg_stage3;
            rw_stage4          <= rw_stage3;
            addr_stage4        <= addr_stage3;
            write_byte_stage4  <= write_byte_stage3;
            fsm_flush_stage4   <= fsm_flush_stage3;
            // ACK error detection
            if (fsm_stage3 == FSM_ACK && sda == 1'b1 && fsm_valid_stage3) begin
                fsm_stage4       <= FSM_ERROR;
                ack_error_stage4 <= 1'b1;
            end else begin
                ack_error_stage4 <= 1'b0;
            end
        end
    end

    // Pipeline stage 5: Final output and status
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            fsm_stage5            <= FSM_IDLE;
            fsm_valid_stage5      <= 1'b0;
            scl_enable_stage5     <= 1'b0;
            sda_enable_stage5     <= 1'b0;
            sda_out_stage5        <= 1'b1;
            bit_index_stage5      <= 4'd0;
            shift_reg_stage5      <= 8'd0;
            rw_stage5             <= 1'b0;
            addr_stage5           <= 7'd0;
            write_byte_stage5     <= 8'd0;
            transfer_done_stage5  <= 1'b0;
            error_stage5          <= 1'b0;
            fsm_flush_stage5      <= 1'b0;
        end else if (pipeline_flush) begin
            fsm_stage5            <= FSM_IDLE;
            fsm_valid_stage5      <= 1'b0;
            scl_enable_stage5     <= 1'b0;
            sda_enable_stage5     <= 1'b0;
            sda_out_stage5        <= 1'b1;
            bit_index_stage5      <= 4'd0;
            shift_reg_stage5      <= 8'd0;
            rw_stage5             <= 1'b0;
            addr_stage5           <= 7'd0;
            write_byte_stage5     <= 8'd0;
            transfer_done_stage5  <= 1'b0;
            error_stage5          <= 1'b0;
            fsm_flush_stage5      <= 1'b0;
        end else begin
            fsm_stage5            <= fsm_stage4;
            fsm_valid_stage5      <= fsm_valid_stage4;
            scl_enable_stage5     <= scl_enable_stage4;
            sda_enable_stage5     <= sda_enable_stage4;
            sda_out_stage5        <= sda_out_stage4;
            bit_index_stage5      <= bit_index_stage4;
            shift_reg_stage5      <= shift_reg_stage4;
            rw_stage5             <= rw_stage4;
            addr_stage5           <= addr_stage4;
            write_byte_stage5     <= write_byte_stage4;
            fsm_flush_stage5      <= fsm_flush_stage4;
            transfer_done_stage5  <= (fsm_stage4 == FSM_DONE) ? 1'b1 : 1'b0;
            error_stage5          <= (fsm_stage4 == FSM_ERROR || ack_error_stage4) ? 1'b1 : 1'b0;
        end
    end

    // Output logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            read_byte      <= 8'd0;
            transfer_done  <= 1'b0;
            error          <= 1'b0;
        end else begin
            if (transfer_done_stage5) begin
                transfer_done <= 1'b1;
                error         <= 1'b0;
                if (rw_stage5)
                    read_byte <= shift_reg_stage5;
            end else if (error_stage5) begin
                transfer_done <= 1'b0;
                error         <= 1'b1;
            end else begin
                transfer_done <= 1'b0;
                error         <= 1'b0;
            end
        end
    end

endmodule