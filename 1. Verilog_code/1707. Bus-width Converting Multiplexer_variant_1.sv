//SystemVerilog
module width_converting_mux(
    input [31:0] wide_input,
    input [7:0] narrow_input,
    input select, mode,
    input req,
    output reg [31:0] result,
    output reg ack
);

    reg [31:0] result_reg;
    reg ack_reg;
    
    always @(*) begin
        if (req) begin
            if (select && mode)
                result_reg = {24'b0, narrow_input};
            else if (select && !mode)
                result_reg = {narrow_input, 24'b0};
            else
                result_reg = wide_input;
            ack_reg = 1'b1;
        end else begin
            result_reg = result;
            ack_reg = 1'b0;
        end
    end

    always @(posedge req) begin
        result <= result_reg;
        ack <= ack_reg;
    end

endmodule