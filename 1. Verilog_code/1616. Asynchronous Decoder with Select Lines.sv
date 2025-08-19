module async_sel_decoder (
    input [1:0] sel,
    input enable,
    output reg [3:0] out_bus
);
    always @(*) begin
        out_bus = 4'b0000;
        if (enable)
            case (sel)
                2'b00: out_bus = 4'b0001;
                2'b01: out_bus = 4'b0010;
                2'b10: out_bus = 4'b0100;
                2'b11: out_bus = 4'b1000;
            endcase
    end
endmodule