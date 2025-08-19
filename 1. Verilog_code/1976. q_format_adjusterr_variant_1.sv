//SystemVerilog
module q_format_adjuster #(
    parameter IN_INT = 8, 
    IN_FRAC = 8, 
    OUT_INT = 4, 
    OUT_FRAC = 12
)(
    input wire [IN_INT+IN_FRAC-1:0] in_data,
    output wire [OUT_INT+OUT_FRAC-1:0] out_data,
    output wire overflow
);

    wire [OUT_INT+IN_INT+IN_FRAC-1:0] sign_extended_data;
    assign sign_extended_data = {{OUT_INT{in_data[IN_INT+IN_FRAC-1]}}, in_data};

    wire [OUT_INT+OUT_FRAC-1:0] shifted_data_case1;
    wire temp_overflow_case1;
    wire [OUT_INT+OUT_FRAC-1:0] shifted_data_case2;

    generate
        if (IN_FRAC <= OUT_FRAC) begin : GEN_CASE1
            q_format_shift_extend #(
                .IN_INT(IN_INT),
                .IN_FRAC(IN_FRAC),
                .OUT_INT(OUT_INT),
                .OUT_FRAC(OUT_FRAC)
            ) shift_extend_inst (
                .in_data(sign_extended_data),
                .shifted_data(shifted_data_case1)
            );

            q_overflow_detect #(
                .IN_INT(IN_INT),
                .IN_FRAC(IN_FRAC),
                .OUT_INT(OUT_INT)
            ) overflow_detect_inst (
                .in_data(in_data),
                .overflow(temp_overflow_case1)
            );
        end else begin : GEN_CASE2
            q_format_shift_trunc #(
                .IN_INT(IN_INT),
                .IN_FRAC(IN_FRAC),
                .OUT_INT(OUT_INT),
                .OUT_FRAC(OUT_FRAC)
            ) shift_trunc_inst (
                .in_data(in_data),
                .shifted_data(shifted_data_case2)
            );
        end
    endgenerate

    assign out_data = (IN_FRAC <= OUT_FRAC) ? shifted_data_case1 : shifted_data_case2;
    assign overflow = (IN_FRAC <= OUT_FRAC) ? temp_overflow_case1 : 1'b0;

endmodule

// 通用移位和符号扩展子模块
module q_format_shift_extend #(
    parameter IN_INT = 8, 
    IN_FRAC = 8, 
    OUT_INT = 4, 
    OUT_FRAC = 12
)(
    input  wire [OUT_INT+IN_INT+IN_FRAC-1:0] in_data,
    output reg  [OUT_INT+OUT_FRAC-1:0] shifted_data
);
    integer idx;
    always @* begin
        shifted_data = {OUT_INT+OUT_FRAC{1'b0}};
        for (idx = 0; idx < OUT_INT+OUT_FRAC; idx = idx + 1) begin
            if (idx < OUT_INT+IN_INT+IN_FRAC) begin
                if (idx >= (OUT_FRAC - IN_FRAC)) begin
                    shifted_data[idx] = in_data[idx - (OUT_FRAC - IN_FRAC)];
                end else begin
                    shifted_data[idx] = 1'b0;
                end
            end else begin
                shifted_data[idx] = 1'b0;
            end
        end
    end
endmodule

// 通用溢出检测子模块
module q_overflow_detect #(
    parameter IN_INT = 8, 
    IN_FRAC = 8, 
    OUT_INT = 4
)(
    input  wire [IN_INT+IN_FRAC-1:0] in_data,
    output reg  overflow
);
    integer idx;
    always @* begin
        overflow = 1'b0;
        for (idx = IN_FRAC + OUT_INT; idx <= IN_INT+IN_FRAC-1; idx = idx + 1) begin
            if (in_data[idx]) overflow = 1'b1;
        end
    end
endmodule

// 通用移位和截断子模块
module q_format_shift_trunc #(
    parameter IN_INT = 8, 
    IN_FRAC = 8, 
    OUT_INT = 4, 
    OUT_FRAC = 12
)(
    input  wire [IN_INT+IN_FRAC-1:0] in_data,
    output reg  [OUT_INT+OUT_FRAC-1:0] shifted_data
);
    integer idx;
    always @* begin
        shifted_data = {OUT_INT+OUT_FRAC{1'b0}};
        for (idx = 0; idx < OUT_INT+OUT_FRAC; idx = idx + 1) begin
            if (idx < OUT_INT+IN_INT+OUT_FRAC) begin
                if ((IN_INT+IN_FRAC-1-idx) >= (IN_FRAC-OUT_FRAC) && (IN_INT+IN_FRAC-1-idx) <= (IN_INT+IN_FRAC-1)) begin
                    shifted_data[idx] = in_data[IN_INT+IN_FRAC-1-idx - (IN_FRAC-OUT_FRAC)];
                end else if (idx >= OUT_INT+IN_FRAC) begin
                    shifted_data[idx] = in_data[IN_INT+IN_FRAC-1];
                end else begin
                    shifted_data[idx] = 1'b0;
                end
            end else begin
                shifted_data[idx] = 1'b0;
            end
        end
    end
endmodule