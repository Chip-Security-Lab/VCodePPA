//SystemVerilog
module circ_shift_reg #(
    parameter WIDTH = 12
)(
    input clk,
    input rstn,
    input en,
    input dir,
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] shifter_out
);
    // Johnson Encoding for 5 states (3 bits required)
    localparam [2:0]
        S_RESET    = 3'b000, // 0
        S_LOAD     = 3'b100, // 1
        S_SHIFT_EN = 3'b110, // 2
        S_HOLD     = 3'b111, // 3
        S_UNUSED   = 3'b011; // 4 (unused, acts as error recovery)

    reg [2:0] current_state, next_state;

    // State Transition Logic using Johnson pattern
    always @(*) begin
        case (current_state)
            S_RESET: begin
                if (!rstn)
                    next_state = S_RESET;
                else if (load_en)
                    next_state = S_LOAD;
                else if (en)
                    next_state = S_SHIFT_EN;
                else
                    next_state = S_HOLD;
            end
            S_LOAD: begin
                if (!rstn)
                    next_state = S_RESET;
                else if (en)
                    next_state = S_SHIFT_EN;
                else if (load_en)
                    next_state = S_LOAD;
                else
                    next_state = S_HOLD;
            end
            S_SHIFT_EN: begin
                if (!rstn)
                    next_state = S_RESET;
                else if (load_en)
                    next_state = S_LOAD;
                else if (en)
                    next_state = S_SHIFT_EN;
                else
                    next_state = S_HOLD;
            end
            S_HOLD: begin
                if (!rstn)
                    next_state = S_RESET;
                else if (load_en)
                    next_state = S_LOAD;
                else if (en)
                    next_state = S_SHIFT_EN;
                else
                    next_state = S_HOLD;
            end
            default: begin
                next_state = S_RESET;
            end
        endcase
    end

    // State Register
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            current_state <= S_RESET;
        else
            current_state <= next_state;
    end

    // 2-bit Conditional Invert Subtractor
    function [1:0] cond_invert_subtract_2bit;
        input [1:0] minuend;
        input [1:0] subtrahend;
        reg [1:0] subtrahend_inv;
        reg [2:0] sum;
        begin
            subtrahend_inv = ~subtrahend;
            sum = {1'b0, minuend} + {1'b0, subtrahend_inv} + 1'b1; // Add 1 for two's complement
            cond_invert_subtract_2bit = sum[1:0];
        end
    endfunction

    // 2-bit Add with wrap-around
    function [1:0] add_wrap_2bit;
        input [1:0] a;
        input [1:0] b;
        reg [2:0] sum;
        begin
            sum = a + b;
            add_wrap_2bit = sum[1:0];
        end
    endfunction

    // Shift Amount Calculation Using 2-bit Conditional Invert Subtractor
    wire [1:0] shift_amt;
    assign shift_amt = (dir) ? 2'b01 : cond_invert_subtract_2bit(2'b00, 2'b01);

    // Shifted Output Calculation
    reg [WIDTH-1:0] shift_result;
    integer i;

    always @(*) begin
        shift_result = shifter_out;
        if (current_state == S_SHIFT_EN) begin
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (dir) begin
                    // Left circular shift by 1
                    shift_result[i] = shifter_out[add_wrap_2bit(i, shift_amt)];
                end else begin
                    // Right circular shift by 1 (using conditional invert subtractor for wrap-around)
                    shift_result[i] = shifter_out[cond_invert_subtract_2bit(i[1:0], shift_amt)];
                end
            end
        end
    end

    // Output Register Logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shifter_out <= {WIDTH{1'b0}};
        end else begin
            case (current_state)
                S_RESET: begin
                    shifter_out <= {WIDTH{1'b0}};
                end
                S_LOAD: begin
                    shifter_out <= load_val;
                end
                S_SHIFT_EN: begin
                    shifter_out <= shift_result;
                end
                S_HOLD: begin
                    shifter_out <= shifter_out;
                end
                default: begin
                    shifter_out <= {WIDTH{1'b0}};
                end
            endcase
        end
    end
endmodule