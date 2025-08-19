module error_detect_decoder(
    input [1:0] addr,
    input valid,
    output reg [3:0] select,
    output reg error
);
    always @(*) begin
        select = 4'b0000;
        error = 1'b0;
        
        if (valid)
            select[addr] = 1'b1;
        else
            error = 1'b1;
    end
endmodule