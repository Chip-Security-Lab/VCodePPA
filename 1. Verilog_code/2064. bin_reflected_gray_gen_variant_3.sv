//SystemVerilog
// Top-level module: Pipelined Bin to Reflected Gray Code Generator
module bin_reflected_gray_gen #(parameter WIDTH = 4) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   enable,
    output wire [WIDTH-1:0]       gray_code_out
);

    //--------------------------------------------------------------------------
    // Stage 1: Binary Counter Register
    //--------------------------------------------------------------------------

    wire [WIDTH-1:0] counter_stage1;
    reg  [WIDTH-1:0] counter_reg_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_reg_stage1 <= {WIDTH{1'b0}};
        else if (enable)
            counter_reg_stage1 <= counter_reg_stage1 + 1'b1;
    end

    assign counter_stage1 = counter_reg_stage1;

    //--------------------------------------------------------------------------
    // Stage 2: Pipeline Register for Counter Output
    //--------------------------------------------------------------------------

    reg [WIDTH-1:0] counter_reg_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_reg_stage2 <= {WIDTH{1'b0}};
        else if (enable)
            counter_reg_stage2 <= counter_stage1;
    end

    //--------------------------------------------------------------------------
    // Stage 3: Binary to Gray Code Conversion (Combinational)
    //--------------------------------------------------------------------------

    wire [WIDTH-1:0] gray_code_stage3;
    assign gray_code_stage3 = counter_reg_stage2 ^ (counter_reg_stage2 >> 1);

    //--------------------------------------------------------------------------
    // Stage 4: Pipeline Register for Gray Code Output
    //--------------------------------------------------------------------------

    reg [WIDTH-1:0] gray_code_reg_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_code_reg_stage4 <= {WIDTH{1'b0}};
        else if (enable)
            gray_code_reg_stage4 <= gray_code_stage3;
    end

    //--------------------------------------------------------------------------
    // Output Assignment
    //--------------------------------------------------------------------------

    assign gray_code_out = gray_code_reg_stage4;

endmodule