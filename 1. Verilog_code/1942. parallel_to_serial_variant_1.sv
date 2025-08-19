//SystemVerilog
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
    reg [DATA_WIDTH-1:0] shift_register;
    reg [$clog2(DATA_WIDTH)-1:0] bit_counter;
    reg [$clog2(DATA_WIDTH+2)-1:0] current_state;

    localparam STATE_IDLE      = 0;
    localparam STATE_LOAD      = 1;
    localparam STATE_SHIFT     = 2;
    localparam STATE_DONE      = 3;

    // Subtractor signals using conditional inversion (conditional inverting adder-subtractor)
    wire [DATA_WIDTH-1:0] one_vector;
    wire [DATA_WIDTH-1:0] inverted_bit_counter;
    wire carry_in;
    wire [DATA_WIDTH-1:0] bit_counter_next;
    wire carry_out;

    assign one_vector = { {(DATA_WIDTH-1){1'b0}}, 1'b1 };
    assign carry_in = 1'b1;

    // Conditional inversion subtractor: bit_counter_next = bit_counter - 1
    assign inverted_bit_counter = ~bit_counter;
    assign {carry_out, bit_counter_next} = {1'b0, inverted_bit_counter} + one_vector + carry_in;

    // State Machine for control
    always @(posedge clock) begin
        if (reset) begin
            current_state <= STATE_IDLE;
        end else begin
            case (current_state)
                STATE_IDLE: begin
                    if (load)
                        current_state <= STATE_LOAD;
                    else
                        current_state <= STATE_IDLE;
                end
                STATE_LOAD: begin
                    current_state <= STATE_SHIFT;
                end
                STATE_SHIFT: begin
                    if (bit_counter != {($clog2(DATA_WIDTH)){1'b0}})
                        current_state <= STATE_SHIFT;
                    else
                        current_state <= STATE_DONE;
                end
                STATE_DONE: begin
                    if (load)
                        current_state <= STATE_LOAD;
                    else
                        current_state <= STATE_IDLE;
                end
                default: current_state <= STATE_IDLE;
            endcase
        end
    end

    // Shift register and bit counter logic
    always @(posedge clock) begin
        case (current_state)
            STATE_IDLE: begin
                shift_register <= {DATA_WIDTH{1'b0}};
                bit_counter <= {($clog2(DATA_WIDTH)){1'b0}};
            end
            STATE_LOAD: begin
                shift_register <= parallel_data;
                bit_counter <= {($clog2(DATA_WIDTH)){1'b1}}; // Set to DATA_WIDTH-1
            end
            STATE_SHIFT: begin
                shift_register <= {shift_register[DATA_WIDTH-2:0], 1'b0};
                bit_counter <= bit_counter_next[$clog2(DATA_WIDTH)-1:0];
            end
            STATE_DONE: begin
                shift_register <= shift_register;
                bit_counter <= bit_counter;
            end
            default: begin
                shift_register <= {DATA_WIDTH{1'b0}};
                bit_counter <= {($clog2(DATA_WIDTH)){1'b0}};
            end
        endcase
    end

    assign serial_out = shift_register[DATA_WIDTH-1];
    assign tx_done = (current_state == STATE_DONE);

endmodule