//SystemVerilog
module magnitude_comp_stage1 #(parameter WIDTH = 8)(
    input [WIDTH-1:0] a, b,
    output [WIDTH-1:0] difference_stage1,
    output a_larger_stage1
);
    assign a_larger_stage1 = a > b;
    assign difference_stage1 = a_larger_stage1 ? a - b : b - a;
endmodule

module magnitude_comp_stage2 #(parameter WIDTH = 8)(
    input [WIDTH-1:0] diff_stage1,
    output [$clog2(WIDTH)-1:0] priority_bit_stage2
);
    // Priority encoder for most significant 1
    function [$clog2(WIDTH)-1:0] find_msb;
        input [WIDTH-1:0] value;
        integer i;
        begin
            find_msb = 0;
            for (i = WIDTH-1; i >= 0; i = i - 1)
                if (value[i]) find_msb = i[$clog2(WIDTH)-1:0];
        end
    endfunction

    assign priority_bit_stage2 = find_msb(diff_stage1);
endmodule

module magnitude_comp_pipeline #(parameter WIDTH = 8)(
    input clk,
    input rst,
    input [WIDTH-1:0] a_in, b_in,
    output [WIDTH-1:0] diff_magnitude_out,
    output [$clog2(WIDTH)-1:0] priority_bit_out,
    output a_larger_out
);

    // Registered inputs for Stage 1 (Forward Retiming)
    reg [WIDTH-1:0] a_in_reg;
    reg [WIDTH-1:0] b_in_reg;

    // Stage 1 outputs
    wire [WIDTH-1:0] difference_s1;
    wire a_larger_s1;

    // Registered output for a_larger_s1 (available after Stage 1)
    reg a_larger_s1_reg;

    // Stage 2 outputs
    wire [$clog2(WIDTH)-1:0] priority_bit_s2;

    // Registered outputs of Stage 2
    reg [$clog2(WIDTH)-1:0] priority_bit_s2_reg;
    reg [WIDTH-1:0] diff_magnitude_s2_reg; // Registering diff_magnitude here

    // Register inputs a_in and b_in (Forward Retiming)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_in_reg <= 0;
            b_in_reg <= 0;
        end else begin
            a_in_reg <= a_in;
            b_in_reg <= b_in;
        end
    end

    // Stage 1: Magnitude difference and comparison
    // Uses registered inputs
    magnitude_comp_stage1 #(WIDTH) stage1_inst (
        .a(a_in_reg),
        .b(b_in_reg),
        .difference_stage1(difference_s1),
        .a_larger_stage1(a_larger_s1)
    );

    // Register a_larger_s1 (available after stage 1)
     always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_larger_s1_reg <= 0;
        end else begin
            a_larger_s1_reg <= a_larger_s1;
        end
    end


    // Stage 2: Priority encoding
    // Uses the direct output of stage 1 (difference_s1)
    magnitude_comp_stage2 #(WIDTH) stage2_inst (
        .diff_stage1(difference_s1),
        .priority_bit_stage2(priority_bit_s2)
    );

    // Register Stage 2 outputs and the difference_s1
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            priority_bit_s2_reg <= 0;
            diff_magnitude_s2_reg <= 0; // Reset registered magnitude
        end else begin
            priority_bit_s2_reg <= priority_bit_s2;
            diff_magnitude_s2_reg <= difference_s1; // Register the magnitude output
        end
    end

    // Final Outputs (registered from Stage 2 and a_larger_s1)
    assign diff_magnitude_out = diff_magnitude_s2_reg;
    assign priority_bit_out = priority_bit_s2_reg;
    assign a_larger_out = a_larger_s1_reg; // a_larger is available after stage 1, registered

endmodule