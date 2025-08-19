//SystemVerilog
// Top-level module: Structured signed to unsigned converter with pipelined dataflow

module signed_to_unsigned #(parameter WIDTH=16) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       signed_in,
    output wire [WIDTH-1:0]       unsigned_out,
    output wire                   overflow
);

    // Stage 1: Input Registering
    reg [WIDTH-1:0] signed_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            signed_in_stage1 <= {WIDTH{1'b0}};
        else
            signed_in_stage1 <= signed_in;
    end

    // Stage 2: Overflow Detection and Intermediate Registering
    wire overflow_stage2;
    reg overflow_stage2_reg;
    wire [WIDTH-1:0] signed_data_stage2;
    reg [WIDTH-1:0] signed_data_stage2_reg;

    overflow_detector #(.WIDTH(WIDTH)) u_overflow_detector (
        .signed_value(signed_in_stage1),
        .overflow_flag(overflow_stage2)
    );

    assign signed_data_stage2 = signed_in_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow_stage2_reg <= 1'b0;
            signed_data_stage2_reg <= {WIDTH{1'b0}};
        end else begin
            overflow_stage2_reg <= overflow_stage2;
            signed_data_stage2_reg <= signed_data_stage2;
        end
    end

    // Stage 3: Unsigned Conversion and Output Registering
    wire [WIDTH-1:0] unsigned_converted_stage3;
    reg  [WIDTH-1:0] unsigned_out_reg;
    reg              overflow_out_reg;

    unsigned_converter #(.WIDTH(WIDTH)) u_unsigned_converter (
        .signed_value(signed_data_stage2_reg),
        .overflow_flag(overflow_stage2_reg),
        .unsigned_value(unsigned_converted_stage3)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_out_reg <= {WIDTH{1'b0}};
            overflow_out_reg <= 1'b0;
        end else begin
            unsigned_out_reg <= unsigned_converted_stage3;
            overflow_out_reg <= overflow_stage2_reg;
        end
    end

    assign unsigned_out = unsigned_out_reg;
    assign overflow     = overflow_out_reg;

endmodule

// -------------------------------------------------------------------
// Submodule: Overflow Detector
// Detects if the input signed value is negative (sign bit is 1)
module overflow_detector #(parameter WIDTH=16) (
    input  wire [WIDTH-1:0] signed_value,
    output wire             overflow_flag
);
    // The MSB is the sign bit in two's complement
    assign overflow_flag = signed_value[WIDTH-1];
endmodule

// -------------------------------------------------------------------
// Submodule: Unsigned Converter
// Converts a signed value to unsigned, zeroing output if overflow
module unsigned_converter #(parameter WIDTH=16) (
    input  wire [WIDTH-1:0] signed_value,
    input  wire             overflow_flag,
    output wire [WIDTH-1:0] unsigned_value
);
    // If overflow (negative), output zero; else, output original value
    assign unsigned_value = overflow_flag ? {WIDTH{1'b0}} : signed_value;
endmodule