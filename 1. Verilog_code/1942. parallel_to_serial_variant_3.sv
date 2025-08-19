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

    // Internal signals for register values
    reg [DATA_WIDTH-1:0] shift_reg_q;
    reg [$clog2(DATA_WIDTH):0] bit_counter_q;

    // Internal signals for combinational logic
    wire [DATA_WIDTH-1:0] shift_reg_d;
    wire [$clog2(DATA_WIDTH):0] bit_counter_d;

    // Combinational logic module instance
    parallel_to_serial_comb #(
        .DATA_WIDTH(DATA_WIDTH)
    ) comb_inst (
        .shift_reg_q      (shift_reg_q),
        .bit_counter_q    (bit_counter_q),
        .parallel_data    (parallel_data),
        .load             (load),
        .reset            (reset),
        .shift_reg_d      (shift_reg_d),
        .bit_counter_d    (bit_counter_d)
    );

    // Sequential logic: registers
    always @(posedge clock) begin
        if (reset) begin
            shift_reg_q   <= {DATA_WIDTH{1'b0}};
            bit_counter_q <= {($clog2(DATA_WIDTH)+1){1'b0}};
        end else begin
            shift_reg_q   <= shift_reg_d;
            bit_counter_q <= bit_counter_d;
        end
    end

    // Output combinational logic
    assign serial_out = shift_reg_q[DATA_WIDTH-1];
    assign tx_done    = (bit_counter_q == DATA_WIDTH);

endmodule

// Combinational logic module
module parallel_to_serial_comb #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0]         shift_reg_q,
    input  wire [$clog2(DATA_WIDTH):0]   bit_counter_q,
    input  wire [DATA_WIDTH-1:0]         parallel_data,
    input  wire                          load,
    input  wire                          reset,
    output reg  [DATA_WIDTH-1:0]         shift_reg_d,
    output reg  [$clog2(DATA_WIDTH):0]   bit_counter_d
);

    typedef enum reg [1:0] {
        CTRL_RESET  = 2'b00,
        CTRL_LOAD   = 2'b01,
        CTRL_SHIFT  = 2'b10,
        CTRL_HOLD   = 2'b11
    } ctrl_state_t;

    reg [1:0] ctrl_state;

    always @(*) begin
        // Default state
        ctrl_state = CTRL_HOLD;
        if (reset)
            ctrl_state = CTRL_RESET;
        else if (load)
            ctrl_state = CTRL_LOAD;
        else if (bit_counter_q < DATA_WIDTH)
            ctrl_state = CTRL_SHIFT;
        else
            ctrl_state = CTRL_HOLD;
    end

    always @(*) begin
        // Default assignment: hold state
        shift_reg_d   = shift_reg_q;
        bit_counter_d = bit_counter_q;
        case (ctrl_state)
            CTRL_RESET: begin
                shift_reg_d   = {DATA_WIDTH{1'b0}};
                bit_counter_d = DATA_WIDTH;
            end
            CTRL_LOAD: begin
                shift_reg_d   = parallel_data;
                bit_counter_d = {($clog2(DATA_WIDTH)+1){1'b0}};
            end
            CTRL_SHIFT: begin
                shift_reg_d   = {shift_reg_q[DATA_WIDTH-2:0], 1'b0};
                bit_counter_d = bit_counter_q + 1'b1;
            end
            default: begin
                // Hold state
                shift_reg_d   = shift_reg_q;
                bit_counter_d = bit_counter_q;
            end
        endcase
    end

endmodule