//SystemVerilog
module right_logical_shifter #(
    parameter WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [WIDTH-1:0] in_data,
    input wire [$clog2(WIDTH)-1:0] shift_amount,
    output wire [WIDTH-1:0] out_data
);

    typedef enum logic [1:0] {
        S_RESET  = 2'b01,
        S_ENABLE = 2'b10,
        S_IDLE   = 2'b00
    } ctrl_state_t;

    reg [WIDTH-1:0] in_data_reg;
    reg [$clog2(WIDTH)-1:0] shift_amount_reg;
    reg ctrl_enable_reg;
    reg ctrl_reset_reg;

    // Registering inputs and control signals
    always @(posedge clock) begin
        if (reset) begin
            in_data_reg      <= {WIDTH{1'b0}};
            shift_amount_reg <= {($clog2(WIDTH)){1'b0}};
            ctrl_enable_reg  <= 1'b0;
            ctrl_reset_reg   <= 1'b1;
        end else begin
            in_data_reg      <= in_data;
            shift_amount_reg <= shift_amount;
            ctrl_enable_reg  <= enable;
            ctrl_reset_reg   <= 1'b0;
        end
    end

    // Combinational state logic
    ctrl_state_t ctrl_state_comb;
    always @(*) begin
        if (ctrl_reset_reg)
            ctrl_state_comb = S_RESET;
        else if (ctrl_enable_reg)
            ctrl_state_comb = S_ENABLE;
        else
            ctrl_state_comb = S_IDLE;
    end

    reg [WIDTH-1:0] out_data_reg;

    // Output logic is now purely combinational, registers moved to input side
    always @(*) begin
        case (ctrl_state_comb)
            S_RESET:  out_data_reg = {WIDTH{1'b0}};
            S_ENABLE: out_data_reg = in_data_reg >> shift_amount_reg;
            S_IDLE:   out_data_reg = out_data_reg;
            default:  out_data_reg = out_data_reg;
        endcase
    end

    assign out_data = out_data_reg;

endmodule