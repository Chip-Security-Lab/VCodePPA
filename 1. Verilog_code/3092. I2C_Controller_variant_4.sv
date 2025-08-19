//SystemVerilog
module I2C_Controller #(
    parameter ADDR_WIDTH = 7
)(
    input clk, rst_n,
    input start,
    input [ADDR_WIDTH-1:0] dev_addr,
    input [7:0] data_tx,
    output reg [7:0] data_rx,
    output reg ack_error,
    inout sda,
    inout scl
);

    localparam IDLE = 3'b000, START = 3'b001, ADDR = 3'b010, 
             ACK1 = 3'b011, DATA = 3'b100, ACK2 = 3'b101, STOP = 3'b110;
    
    reg [2:0] current_state, next_state;
    reg sda_out, scl_out;
    reg [3:0] bit_counter;
    reg [7:0] shift_reg;
    reg rw_bit;
    reg sda_oe;

    // Pipeline registers
    reg [7:0] shift_reg_pipe;
    reg [3:0] bit_counter_pipe;
    reg sda_oe_pipe;
    reg scl_out_pipe;
    reg ack_error_pipe;
    reg rw_bit_pipe;

    assign sda = sda_oe ? 1'b0 : 1'bz;
    assign scl = scl_out ? 1'bz : 1'b0;

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_pipe <= 0;
            bit_counter_pipe <= 0;
            sda_oe_pipe <= 0;
            scl_out_pipe <= 1;
            ack_error_pipe <= 0;
            rw_bit_pipe <= 0;
        end else begin
            shift_reg_pipe <= shift_reg;
            bit_counter_pipe <= bit_counter;
            sda_oe_pipe <= sda_oe;
            scl_out_pipe <= scl_out;
            ack_error_pipe <= ack_error;
            rw_bit_pipe <= rw_bit;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            bit_counter <= 0;
            shift_reg <= 0;
            data_rx <= 0;
            ack_error <= 0;
            rw_bit <= 0;
        end else begin
            current_state <= next_state;
            
            case(current_state)
                IDLE: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                    if (start) begin
                        shift_reg <= {dev_addr, rw_bit};
                    end
                end
                START: begin
                    sda_oe <= 1'b1;
                    scl_out <= 1'b1;
                end
                ADDR: begin
                    if (bit_counter_pipe < 8) begin
                        if (scl_out_pipe == 1'b0) begin
                            sda_oe <= 1'b0;
                            if (shift_reg_pipe[7] == 1'b0) begin
                                sda_oe <= 1'b1;
                            end
                            scl_out <= 1'b1;
                        end else begin
                            scl_out <= 1'b0;
                            shift_reg <= {shift_reg_pipe[6:0], 1'b0};
                            bit_counter <= bit_counter_pipe + 1;
                        end
                    end
                end
                ACK1: begin
                    if (scl_out_pipe == 1'b0) begin
                        sda_oe <= 1'b0;
                        scl_out <= 1'b1;
                    end else begin
                        ack_error <= sda;
                        scl_out <= 1'b0;
                        bit_counter <= 0;
                        if (!rw_bit_pipe) begin
                            shift_reg <= data_tx;
                        end
                    end
                end
                DATA: begin
                    if (bit_counter_pipe < 8) begin
                        if (scl_out_pipe == 1'b0) begin
                            if (rw_bit_pipe) begin
                                sda_oe <= 1'b0;
                            end else begin
                                sda_oe <= 1'b0;
                                if (shift_reg_pipe[7] == 1'b0) begin
                                    sda_oe <= 1'b1;
                                end
                            end
                            scl_out <= 1'b1;
                        end else begin
                            if (rw_bit_pipe) begin
                                shift_reg <= {shift_reg_pipe[6:0], sda};
                            end
                            scl_out <= 1'b0;
                            if (!rw_bit_pipe) begin
                                shift_reg <= {shift_reg_pipe[6:0], 1'b0};
                            end
                            bit_counter <= bit_counter_pipe + 1;
                        end
                    end
                end
                ACK2: begin
                    if (scl_out_pipe == 1'b0) begin
                        if (rw_bit_pipe) begin
                            sda_oe <= 1'b1;
                        end else begin
                            sda_oe <= 1'b0;
                        end
                        scl_out <= 1'b1;
                    end else begin
                        if (!rw_bit_pipe) begin
                            ack_error <= sda;
                        end
                        scl_out <= 1'b0;
                        data_rx <= shift_reg_pipe;
                    end
                end
                STOP: begin
                    if (scl_out_pipe == 1'b0) begin
                        sda_oe <= 1'b1;
                        scl_out <= 1'b1;
                    end else begin
                        sda_oe <= 1'b0;
                    end
                end
                default: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: begin
                if (start) begin
                    next_state = START;
                end
            end
            START: begin
                next_state = ADDR;
            end
            ADDR: begin
                if (bit_counter_pipe == 8) begin
                    next_state = ACK1;
                end
            end
            ACK1: begin
                next_state = DATA;
            end
            DATA: begin
                if (bit_counter_pipe == 8) begin
                    next_state = ACK2;
                end
            end
            ACK2: begin
                next_state = STOP;
            end
            STOP: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule