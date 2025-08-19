module eth_fcs_gen (
    input clk, sof,
    input [7:0] data,
    output reg [31:0] fcs
);
    always @(posedge clk) begin
        if(sof) fcs <= 32'hFFFFFFFF;
        else begin
            fcs[31:24] <= fcs[24] ^ data[7] ^ fcs[30] ^ fcs[24];
            // ... 完整32位CRC计算
        end
    end
endmodule