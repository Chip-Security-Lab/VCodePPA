module gray2bin_seq #(parameter DATA_W = 8) (
    input wire clk, rst_n, enable,
    input wire [DATA_W-1:0] gray_code,
    output reg [DATA_W-1:0] binary_out
);
    reg [DATA_W-1:0] next_binary;
    integer i;
    
    always @(*) begin
        next_binary[DATA_W-1] = gray_code[DATA_W-1];
        for (i = DATA_W-2; i >= 0; i = i - 1)
            next_binary[i] = next_binary[i+1] ^ gray_code[i];
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {DATA_W{1'b0}};
        else if (enable)
            binary_out <= next_binary;
    end
endmodule