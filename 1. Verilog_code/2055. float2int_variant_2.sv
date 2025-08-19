//SystemVerilog
module float2int #(parameter INT_BITS = 32) (
    input wire clk,
    input wire rst_n,
    input wire [31:0] float_in,  // IEEE-754 Single precision
    output reg signed [INT_BITS-1:0] int_out,
    output reg overflow
);

    // Pipeline valid signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg flush_stage1, flush_stage2, flush_stage3, flush_stage4;

    // Stage 1: Input register and field extraction
    reg [31:0] float_in_stage1;
    reg sign_stage1;
    reg [7:0] exponent_stage1;
    reg [22:0] mantissa_stage1;

    // Stage 2: Shift and overflow calculation
    reg sign_stage2;
    reg [7:0] exponent_stage2;
    reg [22:0] mantissa_stage2;
    reg [INT_BITS:0] shifted_value_stage2; // Extra bit for sign extension
    reg overflow_next_stage2;

    // Stage 3: Sign handling and overflow mux
    reg [INT_BITS-1:0] int_out_mux1_stage3;
    reg [INT_BITS-1:0] int_out_mux2_stage3;
    reg sign_stage3;
    reg overflow_next_stage3;

    // Stage 4: Output register
    reg [INT_BITS-1:0] int_out_stage4;
    reg overflow_stage4;

    // Pipeline flush logic (for demonstration: flush on reset)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flush_stage1 <= 1'b1;
            flush_stage2 <= 1'b1;
            flush_stage3 <= 1'b1;
            flush_stage4 <= 1'b1;
        end else begin
            flush_stage1 <= 1'b0;
            flush_stage2 <= flush_stage1;
            flush_stage3 <= flush_stage2;
            flush_stage4 <= flush_stage3;
        end
    end

    // Stage 1: Register inputs and extract fields
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            float_in_stage1 <= 32'b0;
            sign_stage1 <= 1'b0;
            exponent_stage1 <= 8'b0;
            mantissa_stage1 <= 23'b0;
            valid_stage1 <= 1'b0;
        end else begin
            float_in_stage1 <= float_in;
            sign_stage1 <= float_in[31];
            exponent_stage1 <= float_in[30:23];
            mantissa_stage1 <= float_in[22:0];
            valid_stage1 <= 1'b1 & ~flush_stage1;
        end
    end

    // Stage 2: Shift mantissa and calculate overflow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage2 <= 1'b0;
            exponent_stage2 <= 8'b0;
            mantissa_stage2 <= 23'b0;
            shifted_value_stage2 <= {(INT_BITS+1){1'b0}};
            overflow_next_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            sign_stage2 <= sign_stage1;
            exponent_stage2 <= exponent_stage1;
            mantissa_stage2 <= mantissa_stage1;
            if (exponent_stage1 >= 8'd127) begin
                shifted_value_stage2 <= {1'b1, mantissa_stage1} << (exponent_stage1 - 8'd127);
            end else begin
                shifted_value_stage2 <= {1'b1, mantissa_stage1} >> (8'd127 - exponent_stage1);
            end
            overflow_next_stage2 <= (exponent_stage1 > (8'd127 + INT_BITS - 1));
            valid_stage2 <= valid_stage1 & ~flush_stage2;
        end
    end

    // Stage 3: Sign conversion and saturation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out_mux1_stage3 <= {INT_BITS{1'b0}};
            int_out_mux2_stage3 <= {INT_BITS{1'b0}};
            sign_stage3 <= 1'b0;
            overflow_next_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            sign_stage3 <= sign_stage2;
            overflow_next_stage3 <= overflow_next_stage2;
            // Signed conversion
            if (sign_stage2) begin
                int_out_mux1_stage3 <= (~shifted_value_stage2[INT_BITS-1:0]) + 1'b1;
                int_out_mux2_stage3 <= {1'b1, {(INT_BITS-1){1'b0}}}; // Most negative number
            end else begin
                int_out_mux1_stage3 <= shifted_value_stage2[INT_BITS-1:0];
                int_out_mux2_stage3 <= {1'b0, {(INT_BITS-1){1'b1}}}; // Most positive number
            end
            valid_stage3 <= valid_stage2 & ~flush_stage3;
        end
    end

    // Stage 4: Output register and final mux
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out_stage4 <= {INT_BITS{1'b0}};
            overflow_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            overflow_stage4 <= overflow_next_stage3;
            if (overflow_next_stage3) begin
                int_out_stage4 <= int_out_mux2_stage3;
            end else begin
                int_out_stage4 <= int_out_mux1_stage3;
            end
            valid_stage4 <= valid_stage3 & ~flush_stage4;
        end
    end

    // Output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {INT_BITS{1'b0}};
            overflow <= 1'b0;
        end else if (valid_stage4) begin
            int_out <= int_out_stage4;
            overflow <= overflow_stage4;
        end
    end

endmodule