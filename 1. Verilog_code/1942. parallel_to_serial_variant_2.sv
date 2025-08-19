//SystemVerilog
// Top-level module: parallel_to_serial
module parallel_to_serial #(
    parameter DATA_WIDTH = 8
)(
    input wire clock,
    input wire reset,
    input wire load,
    input wire [DATA_WIDTH-1:0] parallel_data,
    output wire serial_out,
    output wire tx_done
);

    // Internal signals
    wire [DATA_WIDTH-1:0] shift_reg_data_out;
    wire [DATA_WIDTH-1:0] shift_reg_data_in;
    wire [DATA_WIDTH-1:0] shift_reg_q;
    wire [COUNTER_WIDTH-1:0] bit_counter_q;
    wire [COUNTER_WIDTH-1:0] bit_counter_next;
    wire counter_enable;
    wire shift_enable;
    wire load_active_pulse;
    wire reset_active_low;

    localparam COUNTER_WIDTH = $clog2(DATA_WIDTH + 1);

    // Reset logic (active low)
    assign reset_active_low = ~reset;

    // Load logic
    assign load_active_pulse = load & reset_active_low;

    // Counter enable logic
    assign counter_enable = (bit_counter_q < DATA_WIDTH) & ~load & reset_active_low;

    // Shift enable logic
    assign shift_enable = (bit_counter_q < DATA_WIDTH) & ~load & reset_active_low;

    // Next value of bit_counter
    wire [COUNTER_WIDTH-1:0] one_complement;
    assign one_complement = { {COUNTER_WIDTH-1{1'b0}}, 1'b1 };
    assign bit_counter_next = bit_counter_q + one_complement;

    // Shift register data input for left shift
    assign shift_reg_data_in = {shift_reg_q[DATA_WIDTH-2:0], 1'b0};

    // Bit counter submodule
    bit_counter #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_bit_counter (
        .clock(clock),
        .reset(reset),
        .load(load),
        .counter_en(counter_enable),
        .counter_next(bit_counter_next),
        .bit_counter_q(bit_counter_q)
    );

    // Shift register submodule
    shift_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_shift_register (
        .clock(clock),
        .reset(reset),
        .load(load),
        .shift_en(shift_enable),
        .parallel_data(parallel_data),
        .shift_data_in(shift_reg_data_in),
        .shift_reg_q(shift_reg_q)
    );

    // Serial output logic submodule
    serial_output #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_serial_output (
        .shift_reg_q(shift_reg_q),
        .serial_out(serial_out)
    );

    // TX done logic submodule
    tx_done_logic #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_tx_done_logic (
        .bit_counter_q(bit_counter_q),
        .tx_done(tx_done)
    );

endmodule

// -----------------------------------------------------------------------------
// Bit Counter Submodule
// -----------------------------------------------------------------------------
module bit_counter #(
    parameter COUNTER_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire clock,
    input  wire reset,
    input  wire load,
    input  wire counter_en,
    input  wire [COUNTER_WIDTH-1:0] counter_next,
    output reg  [COUNTER_WIDTH-1:0] bit_counter_q
);
    // Bit counter with synchronous reset and load
    always @(posedge clock) begin
        if (reset) begin
            bit_counter_q <= {COUNTER_WIDTH{1'b0}};
        end else if (load) begin
            bit_counter_q <= {COUNTER_WIDTH{1'b0}};
        end else if (counter_en) begin
            bit_counter_q <= counter_next;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Shift Register Submodule
// -----------------------------------------------------------------------------
module shift_register #(
    parameter DATA_WIDTH = 8
)(
    input  wire clock,
    input  wire reset,
    input  wire load,
    input  wire shift_en,
    input  wire [DATA_WIDTH-1:0] parallel_data,
    input  wire [DATA_WIDTH-1:0] shift_data_in,
    output reg  [DATA_WIDTH-1:0] shift_reg_q
);
    // Shift register with synchronous reset, load, and left shift
    always @(posedge clock) begin
        if (reset) begin
            shift_reg_q <= {DATA_WIDTH{1'b0}};
        end else if (load) begin
            shift_reg_q <= parallel_data;
        end else if (shift_en) begin
            shift_reg_q <= shift_data_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Serial Output Submodule
// -----------------------------------------------------------------------------
module serial_output #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] shift_reg_q,
    output wire serial_out
);
    // Output the MSB of the shift register as serial output
    assign serial_out = shift_reg_q[DATA_WIDTH-1];
endmodule

// -----------------------------------------------------------------------------
// TX Done Logic Submodule
// -----------------------------------------------------------------------------
module tx_done_logic #(
    parameter COUNTER_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire [COUNTER_WIDTH-1:0] bit_counter_q,
    output wire tx_done
);
    // TX done asserted when bit_counter == DATA_WIDTH
    wire [COUNTER_WIDTH-1:0] data_width_complement;
    wire [COUNTER_WIDTH-1:0] counter_sub_datawidth;
    assign data_width_complement = ~DATA_WIDTH + 1'b1;
    assign counter_sub_datawidth = bit_counter_q + data_width_complement;
    assign tx_done = (counter_sub_datawidth == {COUNTER_WIDTH{1'b0}});
endmodule