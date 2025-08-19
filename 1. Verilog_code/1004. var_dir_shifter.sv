module var_dir_shifter(
    input [15:0] in_data,
    input [3:0] shift_amount,
    input direction,      // 0:right, 1:left
    input fill_value,     // Value to fill vacant bits
    output reg [15:0] out_data
);
    integer i;
    always @(*) begin
        out_data = in_data;
        if (direction) begin  // Left shift
            for (i = 0; i < shift_amount; i = i + 1)
                out_data = {out_data[14:0], fill_value};
        end else begin        // Right shift
            for (i = 0; i < shift_amount; i = i + 1)
                out_data = {fill_value, out_data[15:1]};
        end
    end
endmodule