module rom_lut #(parameter OUT=24)(
    input [3:0] sel,
    output reg [OUT-1:0] value
);
    // 使用case语句代替移位操作
    always @(*) begin
        case(sel)
            4'h0: value = 24'h000001;
            4'h1: value = 24'h000002;
            4'h2: value = 24'h000004;
            4'h3: value = 24'h000008;
            4'h4: value = 24'h000010;
            4'h5: value = 24'h000020;
            4'h6: value = 24'h000040;
            4'h7: value = 24'h000080;
            4'h8: value = 24'h000100;
            4'h9: value = 24'h000200;
            4'hA: value = 24'h000400;
            4'hB: value = 24'h000800;
            4'hC: value = 24'h001000;
            4'hD: value = 24'h002000;
            4'hE: value = 24'h004000;
            4'hF: value = 24'h008000;
            default: value = 24'h000000;
        endcase
    end
endmodule