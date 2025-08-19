//SystemVerilog
module wave20_combo(
    input  wire [1:0] sel,
    input  wire [7:0] in_sin,
    input  wire [7:0] in_tri,
    input  wire [7:0] in_saw,
    output wire [7:0] wave_out
);
    assign wave_out = (sel == 2'b00) ? in_sin :
                      (sel == 2'b01) ? in_tri :
                      (sel == 2'b10) ? in_saw :
                      8'd0;
endmodule