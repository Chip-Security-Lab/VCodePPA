//SystemVerilog
module xor_difference_detector #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] pattern_a,
    input [WIDTH-1:0] pattern_b,
    output [WIDTH-1:0] difference_map,
    output exact_match,
    output reg [$clog2(WIDTH+1)-1:0] hamming_distance
);

    // State definitions
    typedef enum logic [1:0] {
        IDLE,
        CALCULATE,
        DONE
    } state_t;

    reg [1:0] state, next_state;
    reg [$clog2(WIDTH)-1:0] counter;
    reg [$clog2(WIDTH+1)-1:0] hamming_temp;

    // Combinational logic
    assign difference_map = pattern_a ^ pattern_b;
    assign exact_match = (difference_map == {WIDTH{1'b0}});

    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            counter <= 0;
            hamming_temp <= 0;
            hamming_distance <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    counter <= 0;
                    hamming_temp <= 0;
                end
                CALCULATE: begin
                    if (difference_map[counter]) begin
                        hamming_temp <= hamming_temp + 1;
                    end
                    counter <= counter + 1;
                end
                DONE: begin
                    hamming_distance <= hamming_temp;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = CALCULATE;
            CALCULATE: next_state = (counter == WIDTH-1) ? DONE : CALCULATE;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule