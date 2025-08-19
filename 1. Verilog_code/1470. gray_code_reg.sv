module gray_code_reg(
    input clk, reset,
    input [7:0] bin_in,
    input load, convert,
    output reg [7:0] gray_out
);
    reg [7:0] binary;

    always @(posedge clk) begin
        if (reset) begin
            binary <= 8'h00;
            gray_out <= 8'h00;
        end else if (load)
            binary <= bin_in;
        else if (convert)
            gray_out <= binary ^ {1'b0, binary[7:1]};
    end
endmodule