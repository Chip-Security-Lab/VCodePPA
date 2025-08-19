module crc_adaptive #(parameter MAX_WIDTH=64)(
    input clk,
    input [MAX_WIDTH-1:0] data,
    input [5:0] width_sel,  // 输入有效位宽
    output reg [31:0] crc
);
    reg [31:0] crc_next;
    reg [5:0] i;
    
    always @(*) begin
        crc_next = crc;
        for (i = 0; i < width_sel; i = i + 1) begin
            crc_next = {crc_next[30:0], 1'b0} ^ 
                  ((crc_next[31] ^ data[i]) ? 32'h04C11DB7 : 32'h0);
        end
    end
    
    always @(posedge clk) begin
        crc <= crc_next;
    end
endmodule