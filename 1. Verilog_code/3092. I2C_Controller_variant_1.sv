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

    // Manchester Carry Chain Adder signals
    wire [7:0] carry_chain;
    wire [7:0] sum_out;
    reg [7:0] adder_a, adder_b;
    reg adder_cin;

    // Manchester Carry Chain Adder implementation
    assign carry_chain[0] = (adder_a[0] & adder_b[0]) | ((adder_a[0] ^ adder_b[0]) & adder_cin);
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_chain_gen
            assign carry_chain[i] = (adder_a[i] & adder_b[i]) | ((adder_a[i] ^ adder_b[i]) & carry_chain[i-1]);
        end
    endgenerate
    assign sum_out = {adder_a[7:0] ^ adder_b[7:0] ^ {carry_chain[6:0], adder_cin}};

    assign sda = sda_oe ? 1'b0 : 1'bz;
    assign scl = scl_out ? 1'bz : 1'b0;

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
            adder_a <= 0;
            adder_b <= 0;
            adder_cin <= 0;
        end else begin
            current_state <= next_state;
            
            case(current_state)
                IDLE: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                    if (start) begin
                        adder_a <= {dev_addr, rw_bit};
                        adder_b <= 0;
                        adder_cin <= 0;
                        shift_reg <= sum_out;
                    end
                end
                START: begin
                    sda_oe <= 1'b1;
                    scl_out <= 1'b1;
                end
                ADDR: begin
                    if (bit_counter < 8) begin
                        if (scl_out == 1'b0) begin
                            sda_oe <= ~shift_reg[7];
                            scl_out <= 1'b1;
                        end else begin
                            scl_out <= 1'b0;
                            adder_a <= {shift_reg[6:0], 1'b0};
                            adder_b <= 0;
                            adder_cin <= 0;
                            shift_reg <= sum_out;
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                ACK1: begin
                    if (scl_out == 1'b0) begin
                        sda_oe <= 1'b0;
                        scl_out <= 1'b1;
                    end else begin
                        ack_error <= sda;
                        scl_out <= 1'b0;
                        bit_counter <= 0;
                        if (!rw_bit) begin
                            adder_a <= data_tx;
                            adder_b <= 0;
                            adder_cin <= 0;
                            shift_reg <= sum_out;
                        end
                    end
                end
                DATA: begin
                    if (bit_counter < 8) begin
                        if (scl_out == 1'b0) begin
                            sda_oe <= rw_bit ? 1'b0 : ~shift_reg[7];
                            scl_out <= 1'b1;
                        end else begin
                            if (rw_bit) begin
                                adder_a <= {shift_reg[6:0], sda};
                                adder_b <= 0;
                                adder_cin <= 0;
                                shift_reg <= sum_out;
                            end else begin
                                adder_a <= {shift_reg[6:0], 1'b0};
                                adder_b <= 0;
                                adder_cin <= 0;
                                shift_reg <= sum_out;
                            end
                            scl_out <= 1'b0;
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                ACK2: begin
                    if (scl_out == 1'b0) begin
                        sda_oe <= rw_bit ? 1'b1 : 1'b0;
                        scl_out <= 1'b1;
                    end else begin
                        if (!rw_bit) ack_error <= sda;
                        scl_out <= 1'b0;
                        data_rx <= shift_reg;
                    end
                end
                STOP: begin
                    if (scl_out == 1'b0) begin
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
            IDLE: if (start) next_state = START;
            START: next_state = ADDR;
            ADDR: if (bit_counter == 8) next_state = ACK1;
            ACK1: next_state = DATA;
            DATA: if (bit_counter == 8) next_state = ACK2;
            ACK2: next_state = STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule