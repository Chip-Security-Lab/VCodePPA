//SystemVerilog
// Top-level SPI transmit-only controller, hierarchically decomposed

module spi_transmit_only(
    input        clk,
    input        reset,
    input [15:0] tx_data,
    input        tx_start,
    output       tx_busy,
    output       tx_done,
    output       spi_clk,
    output       spi_cs_n,
    output       spi_mosi
);

    // Internal control signals
    wire        ctrl_load;
    wire        ctrl_shift;
    wire        ctrl_done;
    wire        ctrl_spi_clk_toggle;
    wire        ctrl_spi_clk_value;
    wire [1:0]  ctrl_state;
    wire [3:0]  bit_count;
    wire [15:0] shift_reg_out;

    // FSM and overall control logic
    spi_transmit_ctrl u_ctrl (
        .clk               (clk),
        .reset             (reset),
        .tx_start          (tx_start),
        .bit_count         (bit_count),
        .spi_clk_feedback  (ctrl_spi_clk_value),
        .ctrl_load         (ctrl_load),
        .ctrl_shift        (ctrl_shift),
        .ctrl_done         (ctrl_done),
        .ctrl_spi_clk_toggle(ctrl_spi_clk_toggle),
        .ctrl_state        (ctrl_state)
    );

    // Bit counter and shift register logic
    spi_transmit_data u_data (
        .clk                (clk),
        .reset              (reset),
        .load               (ctrl_load),
        .shift              (ctrl_shift),
        .tx_data            (tx_data),
        .bit_count          (bit_count),
        .shift_reg_out      (shift_reg_out)
    );

    // SPI clock generation and latching
    spi_transmit_clk u_clkgen (
        .clk                (clk),
        .reset              (reset),
        .toggle             (ctrl_spi_clk_toggle),
        .ctrl_state         (ctrl_state),
        .spi_clk_out        (spi_clk),
        .spi_clk_feedback   (ctrl_spi_clk_value)
    );

    // SPI CS_n and MOSI signal generation
    spi_transmit_io u_io (
        .ctrl_state         (ctrl_state),
        .shift_reg_out      (shift_reg_out),
        .spi_cs_n           (spi_cs_n),
        .spi_mosi           (spi_mosi)
    );

    // Busy and done outputs
    spi_transmit_status u_status (
        .clk                (clk),
        .reset              (reset),
        .ctrl_state         (ctrl_state),
        .ctrl_done          (ctrl_done),
        .tx_busy            (tx_busy),
        .tx_done            (tx_done)
    );

endmodule

//-----------------------------------------------------------------------------
// FSM & Control Logic: Handles SPI transmit states and control signals
//-----------------------------------------------------------------------------
module spi_transmit_ctrl(
    input        clk,
    input        reset,
    input        tx_start,
    input  [3:0] bit_count,
    input        spi_clk_feedback,
    output reg   ctrl_load,
    output reg   ctrl_shift,
    output reg   ctrl_done,
    output reg   ctrl_spi_clk_toggle,
    output reg [1:0] ctrl_state
);
    localparam IDLE     = 2'b00;
    localparam TRANSMIT = 2'b01;
    localparam FINISH   = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        // Default assignments
        ctrl_load           = 1'b0;
        ctrl_shift          = 1'b0;
        ctrl_done           = 1'b0;
        ctrl_spi_clk_toggle = 1'b0;
        next_state          = state;

        case (state)
            IDLE: begin
                if (tx_start) begin
                    ctrl_load = 1'b1;
                    next_state = TRANSMIT;
                end
            end

            TRANSMIT: begin
                if (!spi_clk_feedback && bit_count == 0) begin
                    ctrl_spi_clk_toggle = 1'b1;
                    next_state = FINISH;
                end else if (!spi_clk_feedback && bit_count != 0) begin
                    ctrl_spi_clk_toggle = 1'b1;
                    ctrl_shift = 1'b1;
                end else if (spi_clk_feedback) begin
                    ctrl_spi_clk_toggle = 1'b1;
                end
            end

            FINISH: begin
                ctrl_done = 1'b1;
                next_state = IDLE;
            end
        endcase
    end

    // Output state for downstream modules
    always @(posedge clk or posedge reset) begin
        if (reset)
            ctrl_state <= IDLE;
        else
            ctrl_state <= next_state;
    end

endmodule

//-----------------------------------------------------------------------------
// Data Logic: Handles bit counter and shift register for MOSI data
//-----------------------------------------------------------------------------
module spi_transmit_data(
    input        clk,
    input        reset,
    input        load,
    input        shift,
    input  [15:0] tx_data,
    output reg [3:0] bit_count,
    output reg [15:0] shift_reg_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            bit_count     <= 4'd0;
            shift_reg_out <= 16'd0;
        end else begin
            if (load) begin
                shift_reg_out <= tx_data;
                bit_count     <= 4'd15;
            end else if (shift) begin
                bit_count     <= bit_count - 1'b1;
                shift_reg_out <= {shift_reg_out[14:0], 1'b0};
            end
        end
    end
endmodule

//-----------------------------------------------------------------------------
// SPI Clock Generator: Generates and toggles SPI clock in TRANSMIT state
//-----------------------------------------------------------------------------
module spi_transmit_clk(
    input        clk,
    input        reset,
    input        toggle,
    input  [1:0] ctrl_state,
    output       spi_clk_out,
    output reg   spi_clk_feedback
);
    localparam TRANSMIT = 2'b01;

    always @(posedge clk or posedge reset) begin
        if (reset)
            spi_clk_feedback <= 1'b0;
        else if (ctrl_state == TRANSMIT && toggle)
            spi_clk_feedback <= ~spi_clk_feedback;
        else if (ctrl_state != TRANSMIT)
            spi_clk_feedback <= 1'b0;
    end

    assign spi_clk_out = (ctrl_state == TRANSMIT) ? spi_clk_feedback : 1'b0;
endmodule

//-----------------------------------------------------------------------------
// Output IO Logic: Generates CS_n and MOSI signals
//-----------------------------------------------------------------------------
module spi_transmit_io(
    input  [1:0]  ctrl_state,
    input  [15:0] shift_reg_out,
    output        spi_cs_n,
    output        spi_mosi
);
    localparam IDLE   = 2'b00;
    localparam FINISH = 2'b10;

    assign spi_mosi = shift_reg_out[15];
    assign spi_cs_n = (ctrl_state == IDLE) || (ctrl_state == FINISH);
endmodule

//-----------------------------------------------------------------------------
// Status Output Logic: Generates tx_busy and tx_done signals
//-----------------------------------------------------------------------------
module spi_transmit_status(
    input        clk,
    input        reset,
    input  [1:0] ctrl_state,
    input        ctrl_done,
    output reg   tx_busy,
    output reg   tx_done
);
    localparam IDLE     = 2'b00;
    localparam TRANSMIT = 2'b01;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            case (ctrl_state)
                IDLE: begin
                    tx_busy <= 1'b0;
                    tx_done <= 1'b0;
                end
                TRANSMIT: begin
                    tx_busy <= 1'b1;
                    tx_done <= 1'b0;
                end
                default: begin // FINISH or others
                    if (ctrl_done) begin
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                    end
                end
            endcase
        end
    end
endmodule