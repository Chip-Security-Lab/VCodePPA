//SystemVerilog
module async_glitch_filter #(
    parameter GLITCH_THRESHOLD = 3
)(
    input clk,
    input rst_n,
    input [GLITCH_THRESHOLD-1:0] samples,
    output reg filtered_out
);

    typedef enum logic [1:0] {
        IDLE,
        COUNTING,
        DONE
    } state_t;

    reg [1:0] state, next_state;
    reg [$clog2(GLITCH_THRESHOLD):0] count;
    reg [$clog2(GLITCH_THRESHOLD):0] ones_count;
    reg [GLITCH_THRESHOLD-1:0] samples_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            count <= 0;
            ones_count <= 0;
            samples_reg <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    samples_reg <= samples;
                    count <= 0;
                    ones_count <= 0;
                end
                COUNTING: begin
                    if (samples_reg[count]) begin
                        ones_count <= ones_count + 1;
                    end
                    count <= count + 1;
                end
                DONE: begin
                    filtered_out <= (ones_count > GLITCH_THRESHOLD/2);
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: next_state = COUNTING;
            COUNTING: next_state = (count == GLITCH_THRESHOLD-1) ? DONE : COUNTING;
            DONE: next_state = IDLE;
        endcase
    end

endmodule