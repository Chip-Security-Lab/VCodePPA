//SystemVerilog
module error_detect_mux(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input valid_a, valid_b, valid_c, valid_d,
    output reg [7:0] out_data,
    output reg error_flag
);

    // Dadda multiplier implementation
    wire [7:0] mux_out;
    wire valid_selected;
    
    // Partial product generation
    wire [7:0][7:0] pp;
    genvar i, j;
    generate
        for(i = 0; i < 8; i = i + 1) begin : pp_gen
            for(j = 0; j < 8; j = j + 1) begin : pp_row
                assign pp[i][j] = (select == 2'b00) ? (in_a[i] & in_b[j]) :
                                (select == 2'b01) ? (in_b[i] & in_c[j]) :
                                (select == 2'b10) ? (in_c[i] & in_d[j]) : (in_d[i] & in_a[j]);
            end
        end
    endgenerate

    // Dadda tree reduction
    wire [7:0] sum, carry;
    wire [6:0] sum_int, carry_int;
    
    // First stage reduction
    assign {carry[0], sum[0]} = pp[0][0];
    assign {carry[1], sum[1]} = pp[0][1] + pp[1][0];
    assign {carry[2], sum[2]} = pp[0][2] + pp[1][1] + pp[2][0];
    assign {carry[3], sum[3]} = pp[0][3] + pp[1][2] + pp[2][1] + pp[3][0];
    assign {carry[4], sum[4]} = pp[0][4] + pp[1][3] + pp[2][2] + pp[3][1] + pp[4][0];
    assign {carry[5], sum[5]} = pp[0][5] + pp[1][4] + pp[2][3] + pp[3][2] + pp[4][1] + pp[5][0];
    assign {carry[6], sum[6]} = pp[0][6] + pp[1][5] + pp[2][4] + pp[3][3] + pp[4][2] + pp[5][1] + pp[6][0];
    assign {carry[7], sum[7]} = pp[0][7] + pp[1][6] + pp[2][5] + pp[3][4] + pp[4][3] + pp[5][2] + pp[6][1] + pp[7][0];

    // Final addition
    assign mux_out = sum + {carry[6:0], 1'b0};

    // Valid signal selection
    assign valid_selected = (select == 2'b00) ? valid_a :
                           (select == 2'b01) ? valid_b :
                           (select == 2'b10) ? valid_c : valid_d;

    always @(*) begin
        out_data = mux_out;
        error_flag = ~valid_selected;
    end
endmodule