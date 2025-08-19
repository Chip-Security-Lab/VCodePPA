//SystemVerilog
module fsm_converter #(parameter S_WIDTH=4) (
    input  wire [S_WIDTH-1:0] state_in,
    output reg  [2**S_WIDTH-1:0] state_out
);

    integer idx;

    // Combined combinational logic for one-hot generation and output assignment
    always @(*) begin : one_hot_generation_and_assign
        state_out = {2**S_WIDTH{1'b0}};
        state_out[state_in] = 1'b1;
    end

endmodule