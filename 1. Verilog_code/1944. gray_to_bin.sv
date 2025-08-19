module gray_to_bin #(
    parameter DATA_W = 8
)(
    input [DATA_W-1:0] gray_code,
    output [DATA_W-1:0] binary
);
    integer i, j;
    reg [DATA_W-1:0] bin_temp;
    
    always @(*) begin
        bin_temp[DATA_W-1] = gray_code[DATA_W-1];
        for (i = DATA_W-2; i >= 0; i = i - 1)
            bin_temp[i] = bin_temp[i+1] ^ gray_code[i];
    end
    
    assign binary = bin_temp;
endmodule