//SystemVerilog
module Booth_Multiplier #(
    parameter WIDTH = 5
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] multiplicand,
    input [WIDTH-1:0] multiplier,
    output reg [2*WIDTH-1:0] product
);

    reg [WIDTH:0] A;
    reg [WIDTH:0] Q;
    reg Q_1;
    reg [WIDTH-1:0] M;
    reg [3:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A <= 0;
            Q <= 0;
            Q_1 <= 0;
            M <= 0;
            count <= 0;
            product <= 0;
        end else begin
            if (count < WIDTH) begin
                case ({Q[0], Q_1})
                    2'b00, 2'b11: begin
                        {A, Q, Q_1} <= {A[WIDTH], A, Q};
                    end
                    2'b01: begin
                        {A, Q, Q_1} <= {A[WIDTH], A + M, Q};
                    end
                    2'b10: begin
                        {A, Q, Q_1} <= {A[WIDTH], A - M, Q};
                    end
                endcase
                count <= count + 1;
            end else begin
                product <= {A, Q};
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            M <= 0;
        end else if (count == 0) begin
            M <= multiplicand;
            Q <= multiplier;
            A <= 0;
            Q_1 <= 0;
        end
    end

endmodule

module SPI_Master #(
    parameter DATA_WIDTH = 8,
    parameter CPOL = 0,
    parameter CPHA = 0
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output sclk,
    output reg cs,
    output mosi,
    input miso
);

    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg current_state, next_state;
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [4:0] bit_counter;
    reg sclk_int;
    reg mosi_reg;
    wire [9:0] booth_product;

    Booth_Multiplier #(.WIDTH(5)) booth_inst (
        .clk(clk),
        .rst_n(rst_n),
        .multiplicand(bit_counter[4:0]),
        .multiplier(5'd2),
        .product(booth_product)
    );

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // Busy signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            busy <= 0;
        else
            busy <= (current_state != IDLE);
    end

    // Chip select control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cs <= 1'b1;
        else if (current_state == IDLE && start)
            cs <= 1'b0;
        else if (current_state == ACTIVE && bit_counter >= booth_product[4:0])
            cs <= 1'b1;
    end

    // Shift register and bit counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            bit_counter <= 0;
        end else begin
            case(current_state)
                IDLE: begin
                    if (start) begin
                        shift_reg <= tx_data;
                        bit_counter <= 0;
                    end
                end
                ACTIVE: begin
                    if (bit_counter < booth_product[4:0]) begin
                        if ((CPHA == 0 && sclk_int == 1'b0) || (CPHA == 1 && sclk_int == 1'b1)) begin
                            shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
            endcase
        end
    end

    // MOSI control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mosi_reg <= 1'b0;
        else if (current_state == ACTIVE && bit_counter < booth_product[4:0]) begin
            if ((CPHA == 0 && sclk_int == 1'b1) || (CPHA == 1 && sclk_int == 1'b0))
                mosi_reg <= shift_reg[DATA_WIDTH-1];
        end
    end

    // SCLK generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sclk_int <= CPOL;
        else if (current_state == ACTIVE && bit_counter < booth_product[4:0])
            sclk_int <= ~sclk_int;
        else if (current_state == IDLE)
            sclk_int <= CPOL;
    end

    // Receive data register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            rx_data <= 0;
        else if (current_state == ACTIVE && bit_counter >= booth_product[4:0])
            rx_data <= shift_reg;
    end

    // State transition logic
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (start) next_state = ACTIVE;
            ACTIVE: if (bit_counter >= booth_product[4:0]) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    assign sclk = (current_state == ACTIVE) ? sclk_int : CPOL;
    assign mosi = mosi_reg;

endmodule