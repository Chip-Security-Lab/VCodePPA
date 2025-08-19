//SystemVerilog
module SPI_Master_CPHA #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV = 4
)(
    input clk, rst_n,
    input start,
    input [DATA_WIDTH-1:0] tx_data,
    output [DATA_WIDTH-1:0] rx_data,
    output reg busy, done,
    output sclk, mosi,
    input miso,
    output reg cs
);

reg [1:0] cpol_cpha; // [CPOL, CPHA]
reg [3:0] clk_cnt;
reg [DATA_WIDTH-1:0] shift_reg;
reg [2:0] state;
reg sclk_int;
reg [$clog2(DATA_WIDTH):0] bit_cnt;

wire [3:0] sub_a, sub_b;
wire [3:0] sub_diff;
wire sub_borrow;

reg [DATA_WIDTH-1:0] rx_data_reg;
reg [3:0] sub_diff_reg;

localparam IDLE = 0, PRE_SCLK = 1, SHIFT = 2, POST_SCLK = 3;

// Retimed rx_data register: move register before the combination logic
assign rx_data = {rx_data_reg[DATA_WIDTH-1:4], sub_diff_reg};

assign sub_a = shift_reg[3:0];
assign sub_b = rx_data_reg[3:0];

FourBit_Borrow_Subtractor u_borrow_subtractor (
    .minuend(sub_a),
    .subtrahend(sub_b),
    .diff(sub_diff),
    .borrow_out(sub_borrow)
);

//-----------------------------------------------------------------------------
// State Register: Handles FSM state transitions
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        case (state)
            IDLE: begin
                if (start)
                    state <= PRE_SCLK;
            end
            PRE_SCLK: begin
                if (clk_cnt == CLK_DIV/2)
                    state <= SHIFT;
            end
            SHIFT: begin
                if ((clk_cnt == CLK_DIV/2) && (bit_cnt == DATA_WIDTH) && (!sclk_int))
                    state <= POST_SCLK;
            end
            POST_SCLK: begin
                state <= IDLE;
            end
        endcase
    end
end

//-----------------------------------------------------------------------------
// Busy/Done Control: Handles busy and done flags
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        busy <= 1'b0;
        done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                if (start) begin
                    busy <= 1'b1;
                    done <= 1'b0;
                end else begin
                    busy <= 1'b0;
                    done <= 1'b0;
                end
            end
            PRE_SCLK, SHIFT: begin
                busy <= 1'b1;
                done <= 1'b0;
            end
            POST_SCLK: begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        endcase
    end
end

//-----------------------------------------------------------------------------
// Chip Select Control: Handles CS signal
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cs <= 1'b1;
    end else begin
        case (state)
            IDLE: begin
                if (start)
                    cs <= 1'b0;
                else
                    cs <= 1'b1;
            end
            PRE_SCLK, SHIFT: begin
                cs <= 1'b0;
            end
            POST_SCLK: begin
                cs <= 1'b1;
            end
        endcase
    end
end

//-----------------------------------------------------------------------------
// SCLK Generation: Handles the internal SCLK signal
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sclk_int <= 1'b0;
    end else begin
        if ((state == PRE_SCLK || state == SHIFT) && (clk_cnt == CLK_DIV/2)) begin
            sclk_int <= ~sclk_int;
        end
        if (state == IDLE)
            sclk_int <= 1'b0;
    end
end

//-----------------------------------------------------------------------------
// Clock Counter: Handles clk_cnt
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 4'b0;
    end else begin
        if (state == IDLE && start)
            clk_cnt <= 4'b0;
        else if ((state == PRE_SCLK || state == SHIFT)) begin
            if (clk_cnt == CLK_DIV/2)
                clk_cnt <= 4'b0;
            else
                clk_cnt <= clk_cnt + 1'b1;
        end else begin
            clk_cnt <= 4'b0;
        end
    end
end

//-----------------------------------------------------------------------------
// Bit Counter: Handles bit_cnt
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bit_cnt <= {($clog2(DATA_WIDTH)+1){1'b0}};
    end else begin
        if (state == IDLE && start)
            bit_cnt <= {($clog2(DATA_WIDTH)+1){1'b0}};
        else if ((state == SHIFT) && (clk_cnt == CLK_DIV/2) && (!sclk_int) && (bit_cnt < DATA_WIDTH))
            bit_cnt <= bit_cnt + 1'b1;
        else if (state == POST_SCLK)
            bit_cnt <= {($clog2(DATA_WIDTH)+1){1'b0}};
    end
end

//-----------------------------------------------------------------------------
// Shift Register: Handles shift_reg for transmit and receive
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        if (state == IDLE && start)
            shift_reg <= tx_data;
        else if ((state == SHIFT) && (clk_cnt == CLK_DIV/2) && (!sclk_int) && (bit_cnt < DATA_WIDTH))
            shift_reg <= {shift_reg[DATA_WIDTH-2:0], miso};
    end
end

//-----------------------------------------------------------------------------
// RX Data Register: Captures upper bits of received data
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        if (state == IDLE && start)
            rx_data_reg <= {DATA_WIDTH{1'b0}};
        else if ((state == SHIFT) && (clk_cnt == CLK_DIV/2) && (bit_cnt == DATA_WIDTH) && (!sclk_int))
            rx_data_reg[DATA_WIDTH-1:4] <= rx_data_reg[DATA_WIDTH-1:4];
        // Upper bits remain unchanged, logic preserved for future expansion
    end
end

//-----------------------------------------------------------------------------
// Subtraction Result Register: Captures sub_diff for output
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sub_diff_reg <= 4'b0;
    end else begin
        if (state == IDLE && start)
            sub_diff_reg <= 4'b0;
        else if ((state == SHIFT) && (clk_cnt == CLK_DIV/2) && (bit_cnt == DATA_WIDTH) && (!sclk_int))
            sub_diff_reg <= sub_diff;
    end
end

//-----------------------------------------------------------------------------
// CPOL/CPHA Register: Default Initialization
//-----------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cpol_cpha <= 2'b00;
    end
end

assign mosi = shift_reg[DATA_WIDTH-1];
assign sclk = (cpol_cpha[0] & (state == SHIFT)) ? sclk_int : cpol_cpha[1];

endmodule

module FourBit_Borrow_Subtractor(
    input  [3:0] minuend,
    input  [3:0] subtrahend,
    output [3:0] diff,
    output borrow_out
);
    wire [3:0] borrow;

    assign diff[0] = minuend[0] ^ subtrahend[0];
    assign borrow[0] = (~minuend[0]) & subtrahend[0];

    assign diff[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
    assign borrow[1] = ((~minuend[1]) & subtrahend[1]) | (((~minuend[1]) | subtrahend[1]) & borrow[0]);

    assign diff[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
    assign borrow[2] = ((~minuend[2]) & subtrahend[2]) | (((~minuend[2]) | subtrahend[2]) & borrow[1]);

    assign diff[3] = minuend[3] ^ subtrahend[3] ^ borrow[2];
    assign borrow[3] = ((~minuend[3]) & subtrahend[3]) | (((~minuend[3]) | subtrahend[3]) & borrow[2]);

    assign borrow_out = borrow[3];
endmodule