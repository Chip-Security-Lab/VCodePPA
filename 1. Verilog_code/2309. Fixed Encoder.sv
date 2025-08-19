module fixed_encoder (
    input      [7:0] symbol,
    input            valid_in,
    output reg [3:0] code,
    output reg       valid_out
);
    // Asynchronous operation
    always @(*) begin
        if (valid_in) begin
            case (symbol[3:0])
                4'h0: code = 4'h8;
                4'h1: code = 4'h9;
                4'h2: code = 4'hA;
                4'h3: code = 4'hB;
                4'h4: code = 4'hC;
                4'h5: code = 4'hD;
                4'h6: code = 4'hE;
                4'h7: code = 4'hF;
                4'h8: code = 4'h0;
                4'h9: code = 4'h1;
                4'hA: code = 4'h2;
                4'hB: code = 4'h3;
                4'hC: code = 4'h4;
                4'hD: code = 4'h5;
                4'hE: code = 4'h6;
                4'hF: code = 4'h7;
            endcase
            valid_out = 1'b1;
        end else begin
            code = 4'h0;
            valid_out = 1'b0;
        end
    end
endmodule