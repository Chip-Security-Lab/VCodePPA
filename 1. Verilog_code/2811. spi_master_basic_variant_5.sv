//SystemVerilog
// Hierarchical SPI Master module with modularized structure

module spi_master_basic #(
    parameter DATA_WIDTH = 8
)(
    input                   clk,
    input                   rst_n,
    input                   start_tx,
    input  [DATA_WIDTH-1:0] tx_data,
    output [DATA_WIDTH-1:0] rx_data,
    output                  busy,
    output                  sclk,
    output                  cs_n,
    output                  mosi,
    input                   miso
);

    // Internal signals
    wire                    ctrl_load_shift;
    wire                    ctrl_shift_enable;
    wire [DATA_WIDTH-1:0]   shiftreg_data_out;
    wire [$clog2(DATA_WIDTH):0] shiftreg_bit_cnt;
    wire                    ctrl_shift_done;
    wire                    ctrl_busy;
    wire                    ctrl_cs_n;
    wire                    ctrl_sclk;
    wire                    shiftreg_mosi;

    // Submodule: SPI Transaction Controller
    spi_ctrl_fsm #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_ctrl_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start_tx(start_tx),
        .bit_counter(shiftreg_bit_cnt),
        .shift_done(ctrl_shift_done),
        .busy(ctrl_busy),
        .cs_n(ctrl_cs_n),
        .sclk(ctrl_sclk),
        .load_shift(ctrl_load_shift),
        .shift_enable(ctrl_shift_enable)
    );

    // Submodule: SPI Shift Register
    spi_shift_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_shift_register (
        .clk(clk),
        .rst_n(rst_n),
        .load(ctrl_load_shift),
        .shift_enable(ctrl_shift_enable),
        .tx_data(tx_data),
        .miso(miso),
        .mosi(shiftreg_mosi),
        .shift_reg_out(shiftreg_data_out),
        .bit_counter(shiftreg_bit_cnt),
        .shift_done(ctrl_shift_done)
    );

    // Submodule: RX Data Latch
    spi_rx_latch #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_rx_latch (
        .clk(clk),
        .rst_n(rst_n),
        .busy(ctrl_busy),
        .shift_done(ctrl_shift_done),
        .shift_reg_in(shiftreg_data_out),
        .rx_data(rx_data)
    );

    // Output assignments
    assign busy = ctrl_busy;
    assign cs_n = ctrl_cs_n;
    assign sclk = ctrl_sclk;
    assign mosi = shiftreg_mosi;

endmodule

//-----------------------------------------------------------------------------
// Submodule: SPI Transaction Controller FSM
// Controls the SPI transaction process and generates control signals
//-----------------------------------------------------------------------------
module spi_ctrl_fsm #(
    parameter DATA_WIDTH = 8
)(
    input                        clk,
    input                        rst_n,
    input                        start_tx,
    input  [$clog2(DATA_WIDTH):0] bit_counter,
    input                        shift_done,
    output reg                   busy,
    output reg                   cs_n,
    output reg                   sclk,
    output reg                   load_shift,
    output reg                   shift_enable
);

    localparam [1:0] ST_IDLE  = 2'b00,
                     ST_LOAD  = 2'b01,
                     ST_SHIFT = 2'b10,
                     ST_DONE  = 2'b11;

    reg [1:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= ST_IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            ST_IDLE:  if (start_tx) next_state = ST_LOAD;
            ST_LOAD:  next_state = ST_SHIFT;
            ST_SHIFT: if (bit_counter == 0) next_state = ST_DONE;
            ST_DONE:  next_state = ST_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy         <= 1'b0;
            cs_n         <= 1'b1;
            sclk         <= 1'b0;
            load_shift   <= 1'b0;
            shift_enable <= 1'b0;
        end else begin
            load_shift   <= 1'b0;
            shift_enable <= 1'b0;
            case (state)
                ST_IDLE: begin
                    busy   <= 1'b0;
                    cs_n   <= 1'b1;
                    sclk   <= 1'b0;
                end
                ST_LOAD: begin
                    busy       <= 1'b1;
                    cs_n       <= 1'b0;
                    sclk       <= 1'b0;
                    load_shift <= 1'b1;
                end
                ST_SHIFT: begin
                    busy         <= 1'b1;
                    cs_n         <= 1'b0;
                    sclk         <= ~sclk;
                    shift_enable <= 1'b1;
                end
                ST_DONE: begin
                    busy   <= 1'b0;
                    cs_n   <= 1'b1;
                    sclk   <= 1'b0;
                end
            endcase
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Submodule: SPI Shift Register
// Handles serial shifting, parallel-to-serial conversion, and bit counting
//-----------------------------------------------------------------------------
module spi_shift_register #(
    parameter DATA_WIDTH = 8
)(
    input                         clk,
    input                         rst_n,
    input                         load,
    input                         shift_enable,
    input      [DATA_WIDTH-1:0]   tx_data,
    input                         miso,
    output reg                    mosi,
    output reg [DATA_WIDTH-1:0]   shift_reg_out,
    output reg [$clog2(DATA_WIDTH):0] bit_counter,
    output reg                    shift_done
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_out <= {DATA_WIDTH{1'b0}};
            mosi          <= 1'b0;
            bit_counter   <= {($clog2(DATA_WIDTH)+1){1'b0}};
            shift_done    <= 1'b0;
        end else begin
            if (load) begin
                shift_reg_out <= tx_data;
                mosi          <= tx_data[DATA_WIDTH-1];
                bit_counter   <= DATA_WIDTH;
                shift_done    <= 1'b0;
            end else if (shift_enable && bit_counter > 0) begin
                shift_reg_out <= {shift_reg_out[DATA_WIDTH-2:0], miso};
                mosi          <= shift_reg_out[DATA_WIDTH-2];
                bit_counter   <= bit_counter - 1'b1;
                shift_done    <= (bit_counter == 1);
            end else if (bit_counter == 0) begin
                shift_done    <= 1'b0;
            end
        end
    end

endmodule

//-----------------------------------------------------------------------------
// Submodule: RX Data Latch
// Latches received data into output register at the end of a transfer
//-----------------------------------------------------------------------------
module spi_rx_latch #(
    parameter DATA_WIDTH = 8
)(
    input                        clk,
    input                        rst_n,
    input                        busy,
    input                        shift_done,
    input      [DATA_WIDTH-1:0]  shift_reg_in,
    output reg [DATA_WIDTH-1:0]  rx_data
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= {DATA_WIDTH{1'b0}};
        end else if (!busy && shift_done) begin
            rx_data <= shift_reg_in;
        end
    end

endmodule