//SystemVerilog

module float_rot #(
    parameter EXP = 5,
    parameter MANT = 10
)(
    input  wire [EXP+MANT:0] in_data,
    input  wire [4:0] shift_amt,
    output wire [EXP+MANT:0] out_data
);

    // Stage 1: Extract fields from input
    wire sign_stage1;
    wire [EXP-1:0] exponent_stage1;
    wire [MANT:0] mantissa_stage1;

    assign sign_stage1     = in_data[EXP+MANT];
    assign exponent_stage1 = in_data[EXP+MANT-1:MANT];
    assign mantissa_stage1 = in_data[MANT:0];

    // Pipeline Register: Stage 1 -> Stage 2
    reg sign_stage2;
    reg [EXP-1:0] exponent_stage2;
    reg [MANT:0] mantissa_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage2     <= 1'b0;
            exponent_stage2 <= {EXP{1'b0}};
            mantissa_stage2 <= {(MANT+1){1'b0}};
        end else begin
            sign_stage2     <= sign_stage1;
            exponent_stage2 <= exponent_stage1;
            mantissa_stage2 <= mantissa_stage1;
        end
    end

    // Stage 2: Cordic Rotation Pipeline
    wire [MANT:0] cordic_rotated_mantissa;
    cordic_rotate_pipelined #(.WIDTH(MANT+1), .STAGES(5)) cordic_rot_pipe_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_vector(mantissa_stage2),
        .sh_amt(shift_amt),
        .rotated_vector(cordic_rotated_mantissa)
    );

    // Pipeline Register: Stage 2 -> Stage 3 (output stage)
    reg sign_stage3;
    reg [EXP-1:0] exponent_stage3;
    reg [MANT:0] cordic_mantissa_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage3         <= 1'b0;
            exponent_stage3     <= {EXP{1'b0}};
            cordic_mantissa_stage3 <= {(MANT+1){1'b0}};
        end else begin
            sign_stage3         <= sign_stage2;
            exponent_stage3     <= exponent_stage2;
            cordic_mantissa_stage3 <= cordic_rotated_mantissa;
        end
    end

    // Output assembler
    assign out_data = {sign_stage3, exponent_stage3, cordic_mantissa_stage3[MANT:1]};

endmodule

// ========================= CORDIC Pipeline Module =========================
module cordic_rotate_pipelined #(
    parameter WIDTH = 11,
    parameter STAGES = 5
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       in_vector,
    input  wire [4:0]             sh_amt,
    output wire [WIDTH-1:0]       rotated_vector
);

    // Pipeline registers for each stage
    reg [WIDTH-1:0] x   [0:STAGES];
    reg [WIDTH-1:0] y   [0:STAGES];
    reg [4:0]       z   [0:STAGES];

    integer i;

    // Stage 0: Initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x[0] <= {WIDTH{1'b0}};
            y[0] <= {WIDTH{1'b0}};
            z[0] <= 5'b0;
        end else begin
            x[0] <= in_vector;
            y[0] <= {WIDTH{1'b0}};
            z[0] <= sh_amt;
        end
    end

    // CORDIC Pipeline Stages
    genvar stage;
    generate
        for (stage = 0; stage < STAGES; stage = stage + 1) begin : CORDIC_PIPE_STAGES
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    x[stage+1] <= {WIDTH{1'b0}};
                    y[stage+1] <= {WIDTH{1'b0}};
                    z[stage+1] <= 5'b0;
                end else begin
                    if (z[stage][4]) begin
                        x[stage+1] <= x[stage] + (y[stage] >>> stage);
                        y[stage+1] <= y[stage] - (x[stage] >>> stage);
                        z[stage+1] <= z[stage] + (1'b1 << stage);
                    end else begin
                        x[stage+1] <= x[stage] - (y[stage] >>> stage);
                        y[stage+1] <= y[stage] + (x[stage] >>> stage);
                        z[stage+1] <= z[stage] - (1'b1 << stage);
                    end
                end
            end
        end
    endgenerate

    // Output assignment from the last stage
    assign rotated_vector = x[STAGES];

endmodule