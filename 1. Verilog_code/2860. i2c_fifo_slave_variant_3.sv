//SystemVerilog
module i2c_fifo_slave #(
    parameter FIFO_DEPTH = 4,
    parameter ADDR = 7'h42
)(
    input clk, rstn,
    output reg fifo_full, fifo_empty,
    output reg [7:0] data_out,
    output reg data_valid,
    inout sda, scl
);

    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    reg [2:0] current_state, next_state;
    reg [7:0] rx_byte;
    reg [3:0] bit_index;

    // State definitions
    localparam STATE_IDLE       = 3'd0;
    localparam STATE_ADDR       = 3'd1;
    localparam STATE_ACK1       = 3'd2;
    localparam STATE_DATA       = 3'd3;
    localparam STATE_ACK2       = 3'd4;

    // I2C control signals
    reg sda_out_reg, sda_dir_reg;
    assign sda = sda_dir_reg ? sda_out_reg : 1'bz;

    // Forward retiming registers for scl/sda inputs
    reg scl_sync_1, scl_sync_2;
    reg sda_sync_1, sda_sync_2;

    // Start condition detection
    reg start_condition;
    reg scl_prev, sda_prev;

    // Synchronized input scl and sda
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_sync_1 <= 1'b0;
            scl_sync_2 <= 1'b0;
            sda_sync_1 <= 1'b1;
            sda_sync_2 <= 1'b1;
        end else begin
            scl_sync_1 <= scl;
            scl_sync_2 <= scl_sync_1;
            sda_sync_1 <= sda;
            sda_sync_2 <= sda_sync_1;
        end
    end

    // Previous value registers
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            scl_prev <= 1'b0;
            sda_prev <= 1'b1;
        end else begin
            scl_prev <= scl_sync_2;
            sda_prev <= sda_sync_2;
        end
    end

    // Start condition detection
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            start_condition <= 1'b0;
        end else begin
            start_condition <= scl_sync_2 & scl_prev & ~sda_sync_2 & sda_prev;
        end
    end

    // FIFO status logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fifo_full  <= 1'b0;
            fifo_empty <= 1'b1;
        end else begin
            fifo_full  <= ((wr_ptr - rd_ptr) == FIFO_DEPTH[$clog2(FIFO_DEPTH):0]);
            fifo_empty <= (wr_ptr == rd_ptr);
        end
    end

    // Next state logic (optimized comparison chain)
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (start_condition)
                    next_state = STATE_ADDR;
            end
            STATE_ADDR: begin
                if (bit_index == 4'd7) begin
                    next_state = (rx_byte[7:1] == ADDR) ? STATE_ACK1 : STATE_IDLE;
                end
            end
            STATE_ACK1: begin
                next_state = STATE_DATA;
            end
            STATE_DATA: begin
                if (bit_index == 4'd7)
                    next_state = STATE_ACK2;
            end
            STATE_ACK2: begin
                next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Main state machine and datapath
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_ptr      <= {$clog2(FIFO_DEPTH)+1{1'b0}};
            rd_ptr      <= {$clog2(FIFO_DEPTH)+1{1'b0}};
            current_state <= STATE_IDLE;
            data_valid  <= 1'b0;
            data_out    <= 8'h00;
            sda_dir_reg <= 1'b0;
            sda_out_reg <= 1'b0;
            bit_index   <= 4'd0;
            rx_byte     <= 8'h00;
        end else begin
            current_state <= next_state;

            // State transitions and outputs
            case (current_state)
                STATE_IDLE: begin
                    if (start_condition) begin
                        bit_index   <= 4'd0;
                        rx_byte     <= 8'h00;
                        sda_dir_reg <= 1'b0;
                        sda_out_reg <= 1'b0;
                    end
                end
                STATE_ADDR: begin
                    if (scl_sync_2 && bit_index < 4'd7) begin
                        rx_byte   <= {rx_byte[6:0], sda_sync_2};
                        bit_index <= bit_index + 1'b1;
                    end else if (bit_index == 4'd7) begin
                        // Comparison optimized by using equality
                        if (rx_byte[7:1] == ADDR) begin
                            sda_dir_reg <= 1'b1;
                            sda_out_reg <= 1'b0; // ACK
                        end else begin
                            sda_dir_reg <= 1'b0;
                        end
                    end
                end
                STATE_ACK1: begin
                    bit_index   <= 4'd0;
                    sda_dir_reg <= 1'b0;
                end
                STATE_DATA: begin
                    if (scl_sync_2 && bit_index < 4'd7) begin
                        rx_byte   <= {rx_byte[6:0], sda_sync_2};
                        bit_index <= bit_index + 1'b1;
                    end else if (bit_index == 4'd7) begin
                        sda_dir_reg <= 1'b1;
                        sda_out_reg <= 1'b0; // ACK
                    end
                end
                STATE_ACK2: begin
                    sda_dir_reg <= 1'b0;
                    // Store data in FIFO if not full
                    if ((wr_ptr - rd_ptr) != FIFO_DEPTH[$clog2(FIFO_DEPTH):0]) begin
                        fifo[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= rx_byte;
                        wr_ptr <= wr_ptr + 1'b1;
                    end
                end
                default: begin
                    sda_dir_reg <= 1'b0;
                end
            endcase

            // FIFO read logic (optimized)
            if ((wr_ptr != rd_ptr) && !data_valid) begin
                data_out    <= fifo[rd_ptr[$clog2(FIFO_DEPTH)-1:0]];
                rd_ptr      <= rd_ptr + 1'b1;
                data_valid  <= 1'b1;
            end else if (data_valid) begin
                data_valid  <= 1'b0;
            end
        end
    end

endmodule