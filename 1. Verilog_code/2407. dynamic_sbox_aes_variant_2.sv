//SystemVerilog
module dynamic_sbox_aes (
    input clk, gen_sbox,
    input [7:0] sbox_in,
    output reg [7:0] sbox_out
);
    reg [7:0] sbox [0:255];
    integer i;
    
    // 优化的GF(2^8)乘法计算函数
    function [7:0] gf_mul;
        input [7:0] a;
        begin
            if (a[7:4] == 4'h0) begin
                case(a[3:0])
                    4'h0: gf_mul = 8'h00;
                    4'h1: gf_mul = 8'h1B;
                    4'h2: gf_mul = 8'h36;
                    4'h3: gf_mul = 8'h2D;
                    4'h4: gf_mul = 8'h6C;
                    4'h5: gf_mul = 8'h77;
                    4'h6: gf_mul = 8'h5A;
                    4'h7: gf_mul = 8'h41;
                    4'h8: gf_mul = 8'hD8;
                    4'h9: gf_mul = 8'hC3;
                    4'hA: gf_mul = 8'hEE;
                    4'hB: gf_mul = 8'hF5;
                    4'hC: gf_mul = 8'hB4;
                    4'hD: gf_mul = 8'hAF;
                    4'hE: gf_mul = 8'h82;
                    4'hF: gf_mul = 8'h99;
                endcase
            end
            else begin
                // 优化的乘法计算，减少关键路径
                gf_mul = a[7] ? ({a[6:0], 1'b0} ^ 8'h1B) : {a[6:0], 1'b0};
            end
        end
    endfunction
    
    // 分离S-box生成和查找逻辑，提高效率
    always @(posedge clk) begin
        if (gen_sbox) begin
            // 并行生成S-box
            for(i=0; i<256; i=i+1) begin
                // 直接计算结果，省去中间变量
                sbox[i] <= gf_mul(i[7:0]) ^ 8'h63;
            end
        end
    end
    
    // 独立读取逻辑，降低时序路径复杂度
    always @(posedge clk) begin
        if (!gen_sbox) begin
            sbox_out <= sbox[sbox_in];
        end
    end
endmodule