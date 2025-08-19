module LZW_Encoder #(DICT_DEPTH=256) (
    input clk, en,
    input [7:0] data,
    output reg [15:0] code
);
reg [7:0] dict [DICT_DEPTH-1:0];
reg [15:0] current_code = 0;
always @(posedge clk) if(en) begin
    if(dict[current_code] == data) 
        current_code <= current_code + 1;
    else begin
        code <= current_code;
        dict[current_code] <= data;
        current_code <= 0;
    end
end
endmodule
