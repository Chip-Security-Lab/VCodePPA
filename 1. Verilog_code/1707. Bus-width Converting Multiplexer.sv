module width_converting_mux(
    input [31:0] wide_input,
    input [7:0] narrow_input,
    input select, mode,
    output reg [31:0] result
);
    always @(*) begin
        if (select) begin
            if (mode)
                result = {24'b0, narrow_input};
            else
                result = {narrow_input, 24'b0};
        end else
            result = wide_input;
    end
endmodule