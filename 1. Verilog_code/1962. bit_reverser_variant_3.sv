//SystemVerilog
module bit_reverser #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out,
    output reg done
);

    typedef enum reg [1:0] {
        IDLE = 2'b00,
        REVERSE = 2'b01,
        DONE = 2'b10
    } state_t;

    reg [1:0] state, next_state;
    reg [$clog2(WIDTH):0] idx, next_idx;
    reg [WIDTH-1:0] next_data_out;

    // State Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            idx <= 0;
            data_out <= {WIDTH{1'b0}};
        end else begin
            state <= next_state;
            idx <= next_idx;
            data_out <= next_data_out;
        end
    end

    // Next State Logic and Output Logic
    always @(*) begin
        next_state = state;
        next_idx = idx;
        next_data_out = data_out;
        done = 1'b0;
        case (state)
            IDLE: begin
                done = 1'b0;
                next_data_out = {WIDTH{1'b0}};
                next_idx = 0;
                if (start) begin
                    next_state = REVERSE;
                end
            end
            REVERSE: begin
                next_data_out = data_out;
                next_data_out[idx] = data_in[WIDTH-1-idx];
                if (idx == WIDTH-1) begin
                    next_idx = 0;
                    next_state = DONE;
                end else begin
                    next_idx = idx + 1;
                    next_state = REVERSE;
                end
            end
            DONE: begin
                done = 1'b1;
                next_state = IDLE;
                next_idx = 0;
                next_data_out = data_out;
            end
            default: begin
                next_state = IDLE;
                next_idx = 0;
                next_data_out = {WIDTH{1'b0}};
                done = 1'b0;
            end
        endcase
    end

endmodule