//SystemVerilog
module spi_simple_master(
    input wire clock,
    input wire reset,
    input wire [7:0] mosi_data,
    input wire start,
    output reg [7:0] miso_data,
    output reg done,
    
    // SPI interface
    output reg sck,
    output reg mosi,
    input wire miso,
    output reg ss
);

    localparam IDLE     = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam FINISH   = 2'b10;

    reg [1:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg [7:0] miso_data_next;
    reg done_next;
    reg ss_next;
    reg sck_next;
    reg mosi_next;

    //=========================================================
    // Next-State/Signal Logic
    //=========================================================
    reg [1:0] next_state;
    reg [2:0] next_bit_count;
    reg [7:0] next_shift_reg;

    always @* begin
        // Default assignments
        next_state      = state;
        next_bit_count  = bit_count;
        next_shift_reg  = shift_reg;
        miso_data_next  = miso_data;
        done_next       = 1'b0;
        ss_next         = ss;
        sck_next        = sck;
        mosi_next       = mosi;

        case (state)
            IDLE: begin
                done_next      = 1'b0;
                sck_next       = 1'b0;
                mosi_next      = 1'b0;
                ss_next        = 1'b1;
                if (start) begin
                    next_state     = TRANSMIT;
                    next_shift_reg = mosi_data;
                    ss_next        = 1'b0;
                    next_bit_count = 3'b111;
                    sck_next       = 1'b0;
                    mosi_next      = mosi_data[7];
                end
            end
            TRANSMIT: begin
                ss_next = 1'b0;
                done_next = 1'b0;

                // Toggle SCK
                sck_next = ~sck;

                if (~sck) begin
                    // Output MOSI on falling edge
                    mosi_next = shift_reg[7];
                    next_bit_count = bit_count;
                    next_shift_reg = shift_reg;
                end else begin
                    // On rising edge, sample MISO and shift
                    next_shift_reg = {shift_reg[6:0], miso};
                    if (bit_count != 0) begin
                        next_bit_count = bit_count - 1;
                        next_state     = TRANSMIT;
                    end else begin
                        next_bit_count = bit_count;
                        next_state     = FINISH;
                    end
                    mosi_next = shift_reg[7];
                end
            end
            FINISH: begin
                // Latch received data and signal done
                miso_data_next  = shift_reg;
                done_next       = 1'b1;
                ss_next         = 1'b1;
                sck_next        = 1'b0;
                mosi_next       = 1'b0;
                next_state      = IDLE;
            end
            default: begin
                next_state      = IDLE;
                next_bit_count  = 3'b000;
                next_shift_reg  = 8'h00;
                miso_data_next  = 8'h00;
                done_next       = 1'b0;
                ss_next         = 1'b1;
                sck_next        = 1'b0;
                mosi_next       = 1'b0;
            end
        endcase
    end

    //=========================================================
    // Optimized State/Output Registering (Forward Register Retiming)
    //=========================================================

    // Combine state, bit_count, and shift_reg into one always block after logic
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            bit_count  <= 3'b000;
            shift_reg  <= 8'h00;
        end else begin
            state      <= next_state;
            bit_count  <= next_bit_count;
            shift_reg  <= next_shift_reg;
        end
    end

    // miso_data Register (no change)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            miso_data  <= 8'h00;
        end else begin
            miso_data  <= miso_data_next;
        end
    end

    // done Register (no change)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            done       <= 1'b0;
        end else begin
            done       <= done_next;
        end
    end

    // ss, sck, mosi Registers now registered after logic (retimed)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ss         <= 1'b1;
            sck        <= 1'b0;
            mosi       <= 1'b0;
        end else begin
            ss         <= ss_next;
            sck        <= sck_next;
            mosi       <= mosi_next;
        end
    end

endmodule