//SystemVerilog
module float_rot #(parameter EXP=5, parameter MANT=10)
(
    input  [EXP+MANT:0] in,
    input  [4:0]        sh,
    output [EXP+MANT:0] out
);

    wire [MANT:0] mantissa_in;
    assign mantissa_in = in[MANT:0];

    // Rotation results
    reg [MANT:0] rot_mant_0;
    reg [MANT:0] rot_mant_1;
    reg [MANT:0] rot_mant_2;
    reg [MANT:0] rot_mant_3;
    reg [MANT:0] rot_mant_4;
    reg [MANT:0] rot_mant_5;
    reg [MANT:0] rot_mant_6;
    reg [MANT:0] rot_mant_7;
    reg [MANT:0] rot_mant_8;
    reg [MANT:0] rot_mant_9;
    reg [MANT:0] rot_mant_10;

    // Rotation results calculated independently
    always @(*) rot_mant_0 = mantissa_in;
    always @(*) rot_mant_1 = {mantissa_in[MANT-1:0], mantissa_in[MANT]} ^ ((mantissa_in >> 1) & {MANT+1{1'b1}});
    always @(*) rot_mant_2 = {mantissa_in[MANT-2:0], mantissa_in[MANT:MANT-1]} ^ ((mantissa_in >> 2) & {MANT+1{1'b1}});
    always @(*) rot_mant_3 = {mantissa_in[MANT-3:0], mantissa_in[MANT:MANT-2]} ^ ((mantissa_in >> 3) & {MANT+1{1'b1}});
    always @(*) rot_mant_4 = {mantissa_in[MANT-4:0], mantissa_in[MANT:MANT-3]} ^ ((mantissa_in >> 4) & {MANT+1{1'b1}});
    always @(*) rot_mant_5 = {mantissa_in[MANT-5:0], mantissa_in[MANT:MANT-4]} ^ ((mantissa_in >> 5) & {MANT+1{1'b1}});
    always @(*) rot_mant_6 = {mantissa_in[MANT-6:0], mantissa_in[MANT:MANT-5]} ^ ((mantissa_in >> 6) & {MANT+1{1'b1}});
    always @(*) rot_mant_7 = {mantissa_in[MANT-7:0], mantissa_in[MANT:MANT-6]} ^ ((mantissa_in >> 7) & {MANT+1{1'b1}});
    always @(*) rot_mant_8 = {mantissa_in[MANT-8:0], mantissa_in[MANT:MANT-7]} ^ ((mantissa_in >> 8) & {MANT+1{1'b1}});
    always @(*) rot_mant_9 = {mantissa_in[MANT-9:0], mantissa_in[MANT:MANT-8]} ^ ((mantissa_in >> 9) & {MANT+1{1'b1}});
    always @(*) rot_mant_10 = {mantissa_in[0], mantissa_in[MANT:1]} ^ ((mantissa_in >> 10) & {MANT+1{1'b1}});

    // Mux: select rotation result according to sh
    reg [MANT:0] selected_rot_mant;
    always @(*) begin
        case (sh)
            5'd0:  selected_rot_mant = rot_mant_0;
            5'd1:  selected_rot_mant = rot_mant_1;
            5'd2:  selected_rot_mant = rot_mant_2;
            5'd3:  selected_rot_mant = rot_mant_3;
            5'd4:  selected_rot_mant = rot_mant_4;
            5'd5:  selected_rot_mant = rot_mant_5;
            5'd6:  selected_rot_mant = rot_mant_6;
            5'd7:  selected_rot_mant = rot_mant_7;
            5'd8:  selected_rot_mant = rot_mant_8;
            5'd9:  selected_rot_mant = rot_mant_9;
            5'd10: selected_rot_mant = rot_mant_10;
            default: selected_rot_mant = {(MANT+1){1'b0}};
        endcase
    end

    assign out = {in[EXP+MANT], in[EXP+MANT-1:MANT], selected_rot_mant[MANT:1]};

endmodule