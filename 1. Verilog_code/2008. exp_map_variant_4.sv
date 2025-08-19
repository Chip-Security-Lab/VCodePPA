//SystemVerilog
module exp_map #(parameter W=16) (
    input  wire [W-1:0] x,
    output wire [W-1:0] y
);

    // Barrel shifter for (1 << x[W-1:4])
    wire [W-1:0] one_shift;
    wire [W-5:0] shift_amt_high = x[W-1:4];

    genvar idx;
    generate
        for (idx = 0; idx < W; idx = idx + 1) begin : one_shift_gen
            assign one_shift[idx] = (idx == shift_amt_high) ? 1'b1 : 1'b0;
        end
    endgenerate

    // Barrel shifter for (x[3:0] << (x[W-1:4]-4))
    wire [3:0] x_low = x[3:0];
    wire [W-1:0] x_low_ext;
    assign x_low_ext = { {(W-4){1'b0}}, x_low };

    wire [W-1:0] x_low_shifted;
    wire [W-5:0] shift_amt_low;
    assign shift_amt_low = (shift_amt_high > 4) ? (shift_amt_high - 4) : { (W-5){1'b0} };

    // State machine implementation for barrel_left_shift
    reg [W-1:0] shifter_in;
    reg [W-1:0] shifter_out;
    reg [W-5:0] shamt_reg;
    reg [$clog2(W-5+1)-1:0] state;
    reg busy;
    integer k;

    localparam IDLE    = 0;
    localparam SHIFTER = 1;
    localparam DONE    = 2;

    // For combinational logic, implement a state machine in a combinational always block
    always @(*) begin
        // Initialization
        shifter_in = x_low_ext;
        shifter_out = x_low_ext;
        shamt_reg = shift_amt_low;
        state = IDLE;
        k = W-5-1;
        busy = 1'b0;

        // State Machine
        state = SHIFTER;
        while (state != DONE) begin
            case (state)
                SHIFTER: begin
                    if (k >= 0) begin
                        if (shamt_reg[k])
                            shifter_out = shifter_out << (1 << k);
                        k = k - 1;
                        if (k < 0)
                            state = DONE;
                    end else begin
                        state = DONE;
                    end
                end
                default: state = DONE;
            endcase
        end
    end

    assign x_low_shifted = shifter_out;
    assign y = one_shift | x_low_shifted;

endmodule