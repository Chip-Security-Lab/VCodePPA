//SystemVerilog
module wave20_combo(
    input  wire [1:0] sel,
    input  wire [7:0] in_sin,
    input  wire [7:0] in_tri,
    input  wire [7:0] in_saw,
    output wire [7:0] wave_out
);
    reg [7:0] wave_out_reg;
    assign wave_out = wave_out_reg;

    always @(*) begin
        if (sel == 2'b00) begin
            wave_out_reg = in_sin;
        end else if (sel == 2'b01) begin
            wave_out_reg = in_tri;
        end else if (sel == 2'b10) begin
            wave_out_reg = in_saw;
        end else begin
            wave_out_reg = 8'd0;
        end
    end
endmodule