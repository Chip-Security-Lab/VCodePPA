//SystemVerilog
module sync_arithmetic_right_shifter #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input                  clk_i,
    input                  en_i,
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output reg [DW-1:0]    data_o
);
    wire [DW-1:0] shifted_result;
    
    // Instantiate the parallel borrow subtractor based shifter
    arithmetic_right_shift_pbs #(
        .DW(DW),
        .SW(SW)
    ) shifter_inst (
        .data_i(data_i),
        .shift_i(shift_i),
        .result_o(shifted_result)
    );
    
    // Register the result
    always @(posedge clk_i) begin
        if (en_i) begin
            data_o <= shifted_result;
        end
    end
endmodule

module arithmetic_right_shift_pbs #(
    parameter DW = 32,  // Data width
    parameter SW = 5    // Shift width
)(
    input      [DW-1:0]    data_i,
    input      [SW-1:0]    shift_i,
    output     [DW-1:0]    result_o
);
    // Internal signals
    reg [DW-1:0] shift_result;
    wire sign_bit = data_i[DW-1];
    
    // Generate different shift amounts using parallel structure
    always @(*) begin
        // Default value (no shift)
        shift_result = data_i;
        
        // Implement arithmetic right shift using parallel structure
        if (shift_i[0]) shift_result = {sign_bit, shift_result[DW-1:1]};
        if (shift_i[1]) shift_result = {{2{sign_bit}}, shift_result[DW-1:2]};
        if (shift_i[2]) shift_result = {{4{sign_bit}}, shift_result[DW-1:4]};
        if (shift_i[3]) shift_result = {{8{sign_bit}}, shift_result[DW-1:8]};
        if (shift_i[4]) shift_result = {{16{sign_bit}}, shift_result[DW-1:16]};
        
        // For larger shift widths, add more stages here
    end
    
    assign result_o = shift_result;
endmodule