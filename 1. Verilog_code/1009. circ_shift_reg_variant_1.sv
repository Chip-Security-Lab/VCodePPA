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
    typedef enum logic [1:0] {
        STATE_RESET = 2'b00,
        STATE_LOAD  = 2'b01,
        STATE_SHIFT = 2'b10,
        STATE_HOLD  = 2'b11
    } state_t;

    state_t next_state;

    always @(*) begin
        if (!rstn)
            next_state = STATE_RESET;
        else if (load_en)
            next_state = STATE_LOAD;
        else if (en)
            next_state = STATE_SHIFT;
        else
            next_state = STATE_HOLD;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            shifter_out <= {WIDTH{1'b0}};
        end else begin
            case (next_state)
                STATE_LOAD: begin
                    shifter_out <= load_val;
                end
                STATE_SHIFT: begin
                    case (dir)
                        1'b1: shifter_out <= {shifter_out[WIDTH-2:0], shifter_out[WIDTH-1]};
                        1'b0: shifter_out <= {shifter_out[0], shifter_out[WIDTH-1:1]};
                        default: shifter_out <= shifter_out;
                    endcase
                end
                default: begin
                    shifter_out <= shifter_out;
                end
            endcase
        end
    end
endmodule