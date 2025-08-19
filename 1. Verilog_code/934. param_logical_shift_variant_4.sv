//SystemVerilog
module param_logical_shift #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input signed [WIDTH-1:0] din,
    input [SHIFT_W-1:0] shift,
    output signed [WIDTH-1:0] dout
);
    reg signed [WIDTH-1:0] shift_result;
    
    always @(*) begin
        case(shift)
            // Implement shift operation using individual cases
            // for better control and potentially improved timing
            0: shift_result = din;
            1: shift_result = {din[WIDTH-2:0], 1'b0};
            2: shift_result = {din[WIDTH-3:0], 2'b0};
            3: shift_result = {din[WIDTH-4:0], 3'b0};
            4: shift_result = {din[WIDTH-5:0], 4'b0};
            5: shift_result = {din[WIDTH-6:0], 5'b0};
            6: shift_result = {din[WIDTH-7:0], 6'b0};
            7: shift_result = {din[WIDTH-8:0], 7'b0};
            default: shift_result = {WIDTH{1'b0}}; // For shifts >= WIDTH, result is 0
        endcase
    end
    
    assign dout = shift_result;
endmodule