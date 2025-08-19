//SystemVerilog
module width_converting_mux(
    input [31:0] wide_input,
    input [7:0] narrow_input,
    input select, mode,
    input req,
    output reg [31:0] result,
    output reg ack
);
    wire [31:0] narrow_extended = mode ? {24'b0, narrow_input} : {narrow_input, 24'b0};
    
    always @(*) begin
        if (req) begin
            result = select ? narrow_extended : wide_input;
            ack = 1'b1;
        end else begin
            result = 32'b0;
            ack = 1'b0;
        end
    end
endmodule