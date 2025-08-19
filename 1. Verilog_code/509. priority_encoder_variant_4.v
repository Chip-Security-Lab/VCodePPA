module priority_encoder_top(
    input [7:0] req,
    output [2:0] code
);

    wire [2:0] high_priority_code;
    wire [2:0] low_priority_code;
    wire high_priority_valid;

    high_priority_encoder high_enc(
        .req(req[7:4]),
        .code(high_priority_code),
        .valid(high_priority_valid)
    );

    low_priority_encoder low_enc(
        .req(req[3:0]),
        .code(low_priority_code)
    );

    output_selector out_sel(
        .high_priority_code(high_priority_code),
        .low_priority_code(low_priority_code),
        .high_priority_valid(high_priority_valid),
        .final_code(code)
    );

endmodule

module high_priority_encoder(
    input [3:0] req,
    output reg [2:0] code,
    output reg valid
);
    always @(*) begin
        case(1'b1)
            req[3]: begin code = 3'b111; valid = 1'b1; end
            req[2]: begin code = 3'b110; valid = 1'b1; end
            req[1]: begin code = 3'b101; valid = 1'b1; end
            req[0]: begin code = 3'b100; valid = 1'b1; end
            default: begin code = 3'b000; valid = 1'b0; end
        endcase
    end
endmodule

module low_priority_encoder(
    input [3:0] req,
    output reg [2:0] code
);
    always @(*) begin
        case(1'b1)
            req[3]: code = 3'b011;
            req[2]: code = 3'b010;
            req[1]: code = 3'b001;
            req[0]: code = 3'b000;
            default: code = 3'b000;
        endcase
    end
endmodule

module output_selector(
    input [2:0] high_priority_code,
    input [2:0] low_priority_code,
    input high_priority_valid,
    output reg [2:0] final_code
);
    always @(*) begin
        if (high_priority_valid) begin
            final_code = high_priority_code;
        end else begin
            final_code = low_priority_code;
        end
    end
endmodule