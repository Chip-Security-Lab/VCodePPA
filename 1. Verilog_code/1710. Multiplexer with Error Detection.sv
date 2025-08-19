module error_detect_mux(
    input [7:0] in_a, in_b, in_c, in_d,
    input [1:0] select,
    input valid_a, valid_b, valid_c, valid_d,
    output reg [7:0] out_data,
    output reg error_flag
);
    always @(*) begin
        error_flag = 1'b0;
        case (select)
            2'b00: begin
                out_data = in_a;
                error_flag = !valid_a;
            end
            2'b01: begin
                out_data = in_b;
                error_flag = !valid_b;
            end
            2'b10: begin
                out_data = in_c;
                error_flag = !valid_c;
            end
            2'b11: begin
                out_data = in_d;
                error_flag = !valid_d;
            end
        endcase
    end
endmodule