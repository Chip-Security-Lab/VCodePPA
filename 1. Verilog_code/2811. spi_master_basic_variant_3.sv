//SystemVerilog
module spi_master_basic #(parameter DATA_WIDTH = 8) (
    input clk, rst_n,
    input start_tx,
    input [DATA_WIDTH-1:0] tx_data,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg busy,
    output reg sclk, cs_n, mosi,
    input miso
);
    reg [DATA_WIDTH-1:0] shift_reg;
    reg [$clog2(DATA_WIDTH):0] bit_counter;
    reg [1:0] state, next_state;

    localparam IDLE     = 2'd0;
    localparam LOAD     = 2'd1;
    localparam TRANSFER = 2'd2;
    localparam DONE     = 2'd3;

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (start_tx)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_counter == 0)
                    next_state = DONE;
                else
                    next_state = TRANSFER;
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output and datapath logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
            busy <= 0;
            cs_n <= 1;
            sclk <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            mosi <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    cs_n <= 1;
                    sclk <= 0;
                    mosi <= 0;
                end
                LOAD: begin
                    busy <= 1;
                    cs_n <= 0;
                    bit_counter <= DATA_WIDTH;
                    shift_reg <= tx_data;
                    sclk <= 0;
                    mosi <= tx_data[DATA_WIDTH-1];
                end
                TRANSFER: begin
                    sclk <= ~sclk;
                    if (sclk) begin
                        shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
                        bit_counter <= bit_counter - 1;
                    end
                    mosi <= shift_reg[DATA_WIDTH-1];
                end
                DONE: begin
                    busy <= 0;
                    cs_n <= 1;
                    rx_data <= shift_reg;
                    sclk <= 0;
                    mosi <= 0;
                end
                default: begin
                    busy <= 0;
                    cs_n <= 1;
                    sclk <= 0;
                    mosi <= 0;
                end
            endcase
        end
    end
endmodule