//SystemVerilog
module width_converting_mux(
    input [31:0] wide_input,
    input [7:0] narrow_input,
    input select,
    input mode,
    input valid,
    output reg [31:0] result,
    output reg ready
);
    wire [31:0] mux_result = select ? (mode ? {24'b0, narrow_input} : {narrow_input, 24'b0}) : wide_input;
    
    always @(*) begin
        {result, ready} = valid ? {mux_result, 1'b1} : {32'b0, 1'b0};
    end
endmodule