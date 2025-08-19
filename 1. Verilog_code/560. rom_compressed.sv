module rom_compressed #(parameter AW=8)(
    input [AW-1:0] addr,
    output reg [31:0] data
);
    // 解压缩逻辑已经是可综合的
    always @(*) begin
        data = {addr, ~addr, addr ^ 8'hFF, addr | 8'h0F};
    end
endmodule