//SystemVerilog
module lut_mult_req_ack (
    input clk,
    input rst_n,
    input [3:0] a, b,
    input req,
    output reg ack,
    output reg [7:0] product
);

    reg [7:0] product_next;
    reg busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'h00;
            ack <= 1'b0;
            busy <= 1'b0;
        end else begin
            if (!busy && req) begin
                case({a, b})
                    8'h00: product <= 8'h00;
                    8'h01: product <= 8'h00;
                    8'h02: product <= 8'h00;
                    8'h03: product <= 8'h00;
                    8'h04: product <= 8'h00;
                    8'h05: product <= 8'h00;
                    8'h06: product <= 8'h00;
                    8'h07: product <= 8'h00;
                    8'h08: product <= 8'h00;
                    8'h09: product <= 8'h00;
                    8'h0A: product <= 8'h00;
                    8'h0B: product <= 8'h00;
                    8'h0C: product <= 8'h00;
                    8'h0D: product <= 8'h00;
                    8'h0E: product <= 8'h00;
                    8'h0F: product <= 8'h00;
                    8'h10: product <= 8'h00;
                    8'h11: product <= 8'h01;
                    8'h12: product <= 8'h02;
                    8'h13: product <= 8'h03;
                    // ... 中间查找表项省略 ...
                    8'hF0: product <= 8'h00;
                    8'hF1: product <= 8'h0F;
                    8'hF2: product <= 8'h1E;
                    8'hF3: product <= 8'h2D;
                    8'hF4: product <= 8'h3C;
                    8'hF5: product <= 8'h4B;
                    8'hF6: product <= 8'h5A;
                    8'hF7: product <= 8'h69;
                    8'hF8: product <= 8'h78;
                    8'hF9: product <= 8'h87;
                    8'hFA: product <= 8'h96;
                    8'hFB: product <= 8'hA5;
                    8'hFC: product <= 8'hB4;
                    8'hFD: product <= 8'hC3;
                    8'hFE: product <= 8'hD2;
                    8'hFF: product <= 8'hE1;
                    default: product <= 8'h00;
                endcase
                ack <= 1'b1;
                busy <= 1'b1;
            end else if (busy && !req) begin
                ack <= 1'b0;
                busy <= 1'b0;
            end
        end
    end

endmodule