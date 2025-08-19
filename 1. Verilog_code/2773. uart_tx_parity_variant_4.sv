//SystemVerilog
module uart_tx_parity #(
    parameter DWIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire tx_en,
    input wire [DWIDTH-1:0] data_in,
    input wire [1:0] parity_mode, // 00:none, 01:odd, 10:even
    output reg tx_out,
    output reg tx_active
);

    localparam IDLE      = 3'd0;
    localparam START_BIT = 3'd1;
    localparam DATA_BITS = 3'd2;
    localparam PARITY_BIT= 3'd3;
    localparam STOP_BIT  = 3'd4;

    reg [2:0] state;
    reg [3:0] bit_index;
    reg [DWIDTH-1:0] data_reg;
    reg parity_bit;

    // 4-bit borrow subtractor instance wires
    wire [3:0] bit_index_next;
    wire borrow_out;

    borrow_subtractor_4bit u_borrow_subtractor_4bit (
        .a(bit_index),
        .b(4'd1),
        .diff(bit_index_next),
        .borrow_out(borrow_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_out <= 1'b1;
            tx_active <= 1'b0;
            data_reg <= {DWIDTH{1'b0}};
            bit_index <= 4'd0;
            parity_bit <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx_out <= 1'b1;
                    tx_active <= 1'b0;
                    if (tx_en) begin
                        data_reg <= data_in;
                        state <= START_BIT;
                        tx_active <= 1'b1;
                        if (parity_mode == 2'b00) begin
                            parity_bit <= 1'b0;
                        end else if (parity_mode == 2'b01) begin // odd
                            parity_bit <= ~(^data_in);
                        end else if (parity_mode == 2'b10) begin // even
                            parity_bit <= ^data_in;
                        end else begin
                            parity_bit <= 1'b0;
                        end
                    end
                end
                START_BIT: begin
                    tx_out <= 1'b0;
                    state <= DATA_BITS;
                    bit_index <= 4'd0;
                end
                DATA_BITS: begin
                    tx_out <= data_reg[0];
                    data_reg <= {1'b0, data_reg[DWIDTH-1:1]};
                    if (bit_index < DWIDTH-1) begin
                        // bit_index increment using 4-bit borrow subtractor
                        bit_index <= bit_index_next;
                    end else begin
                        if (parity_mode == 2'b00) begin
                            state <= STOP_BIT;
                        end else begin
                            state <= PARITY_BIT;
                        end
                    end
                end
                PARITY_BIT: begin
                    tx_out <= parity_bit;
                    state <= STOP_BIT;
                end
                STOP_BIT: begin
                    tx_out <= 1'b1;
                    state <= IDLE;
                    tx_active <= 1'b0;
                end
                default: begin
                    state <= IDLE;
                    tx_out <= 1'b1;
                    tx_active <= 1'b0;
                end
            endcase
        end
    end

endmodule

module borrow_subtractor_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [3:0] diff,
    output wire borrow_out
);
    wire [3:0] borrow;

    // Bit 0
    assign diff[0] = a[0] ^ b[0];
    assign borrow[0] = (~a[0]) & b[0];

    // Bit 1
    assign diff[1] = a[1] ^ b[1] ^ borrow[0];
    assign borrow[1] = ((~a[1]) & b[1]) | (((~a[1]) | b[1]) & borrow[0]);

    // Bit 2
    assign diff[2] = a[2] ^ b[2] ^ borrow[1];
    assign borrow[2] = ((~a[2]) & b[2]) | (((~a[2]) | b[2]) & borrow[1]);

    // Bit 3
    assign diff[3] = a[3] ^ b[3] ^ borrow[2];
    assign borrow[3] = ((~a[3]) & b[3]) | (((~a[3]) | b[3]) & borrow[2]);

    assign borrow_out = borrow[3];
endmodule