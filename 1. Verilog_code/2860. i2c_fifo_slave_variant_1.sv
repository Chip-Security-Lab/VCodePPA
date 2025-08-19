//SystemVerilog
module i2c_fifo_slave #(
    parameter FIFO_DEPTH = 4,
    parameter ADDR = 7'h42
)(
    input wire clk, rstn,
    output wire fifo_full, fifo_empty,
    output reg [7:0] data_out,
    output reg data_valid,
    inout wire sda, scl
);
    reg [7:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    reg [4:0] curr_state, next_state;
    reg [7:0] rx_data;
    reg [3:0] bit_count;

    wire [$clog2(FIFO_DEPTH):0] fifo_count;
    assign fifo_count = wr_ptr - rd_ptr;
    assign fifo_full = (fifo_count == FIFO_DEPTH[$clog2(FIFO_DEPTH):0]);
    assign fifo_empty = (wr_ptr == rd_ptr);

    // One-cold state encoding
    localparam [4:0] STATE_IDLE       = 5'b11110;
    localparam [4:0] STATE_ADDR       = 5'b11101;
    localparam [4:0] STATE_ACK1       = 5'b11011;
    localparam [4:0] STATE_DATA       = 5'b10111;
    localparam [4:0] STATE_ACK2       = 5'b01111;

    reg sda_output, sda_drive;
    assign sda = sda_drive ? sda_output : 1'bz;

    reg start_flag;
    reg scl_last, sda_last;

    always @(posedge clk) begin
        scl_last <= scl;
        sda_last <= sda;
        start_flag <= scl & scl_last & ~sda & sda_last;
    end

    // Optimized FSM transition logic
    always @(*) begin
        next_state = curr_state;
        case (curr_state)
            STATE_IDLE: begin
                if (start_flag)
                    next_state = STATE_ADDR;
            end
            STATE_ADDR: begin
                if (bit_count == 4'd7) begin
                    if (rx_data[7:1] == ADDR)
                        next_state = STATE_ACK1;
                    else
                        next_state = STATE_IDLE;
                end
            end
            STATE_ACK1: begin
                next_state = STATE_DATA;
            end
            STATE_DATA: begin
                if (bit_count == 4'd7)
                    next_state = STATE_ACK2;
            end
            STATE_ACK2: begin
                next_state = STATE_IDLE;
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Optimized FSM and datapath
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            curr_state <= STATE_IDLE;
            data_valid <= 1'b0;
            data_out <= 8'h00;
            sda_drive <= 1'b0;
            sda_output <= 1'b0;
            bit_count <= 4'd0;
            rx_data <= 8'h00;
        end else begin
            curr_state <= next_state;

            case (curr_state)
                STATE_IDLE: begin
                    if (start_flag) begin
                        bit_count <= 4'd0;
                        rx_data <= 8'h00;
                    end
                end

                STATE_ADDR: begin
                    if (bit_count == 4'd7) begin
                        if (rx_data[7:1] == ADDR) begin
                            sda_drive <= 1'b1;
                            sda_output <= 1'b0;
                        end
                    end else if (scl) begin
                        rx_data <= {rx_data[6:0], sda};
                        bit_count <= bit_count + 1'b1;
                    end
                end

                STATE_ACK1: begin
                    bit_count <= 4'd0;
                    sda_drive <= 1'b0;
                end

                STATE_DATA: begin
                    if (bit_count == 4'd7) begin
                        sda_drive <= 1'b1;
                        sda_output <= 1'b0;
                    end else if (scl) begin
                        rx_data <= {rx_data[6:0], sda};
                        bit_count <= bit_count + 1'b1;
                    end
                end

                STATE_ACK2: begin
                    if (!fifo_full) begin
                        fifo_mem[wr_ptr[$clog2(FIFO_DEPTH)-1:0]] <= rx_data;
                        wr_ptr <= wr_ptr + 1'b1;
                    end
                    sda_drive <= 1'b0;
                end

                default: ;
            endcase

            // Optimized FIFO read logic
            if (!fifo_empty && !data_valid) begin
                data_out <= fifo_mem[rd_ptr[$clog2(FIFO_DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1'b1;
                data_valid <= 1'b1;
            end else if (data_valid) begin
                data_valid <= 1'b0;
            end
        end
    end
endmodule