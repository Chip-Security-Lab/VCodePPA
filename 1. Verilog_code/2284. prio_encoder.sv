module prio_encoder (
    input [7:0] req,
    output reg [2:0] code
);
    always @(*) begin
        casex (req)
            8'b1xxx_xxxx: code = 3'h7;
            8'b01xx_xxxx: code = 3'h6;
            // ... 其他优先级逻辑 ...
            default: code = 3'h0;
        endcase
    end
endmodule