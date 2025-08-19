//SystemVerilog
// Top-level module: Pipelined Unsigned to Signed Conversion with Overflow Detection (Pipelined Version)
module unsigned_to_signed #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [WIDTH-1:0]      unsigned_in,
    output wire [WIDTH-1:0]      signed_out,
    output wire                  overflow,
    output wire                  valid_out
);

    // -------------------------------
    // Pipeline Stage 1: Input Register
    // -------------------------------
    reg  [WIDTH-1:0]             unsigned_in_stage1;
    reg                          valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_in_stage1 <= {WIDTH{1'b0}};
            valid_stage1       <= 1'b0;
        end else begin
            if (start) begin
                unsigned_in_stage1 <= unsigned_in;
                valid_stage1       <= 1'b1;
            end else begin
                valid_stage1       <= 1'b0;
            end
        end
    end

    // ------------------------------------------
    // Pipeline Stage 2: Extract Sign/Unsigned Part
    // ------------------------------------------
    reg                          sign_bit_stage2;
    reg  [WIDTH-2:0]             unsigned_part_stage2;
    reg  [WIDTH-1:0]             unsigned_in_stage2;
    reg                          valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_bit_stage2       <= 1'b0;
            unsigned_part_stage2  <= {WIDTH-1{1'b0}};
            unsigned_in_stage2    <= {WIDTH{1'b0}};
            valid_stage2          <= 1'b0;
        end else begin
            sign_bit_stage2       <= unsigned_in_stage1[WIDTH-1];
            unsigned_part_stage2  <= unsigned_in_stage1[WIDTH-2:0];
            unsigned_in_stage2    <= unsigned_in_stage1;
            valid_stage2          <= valid_stage1;
        end
    end

    // ------------------------------------------
    // Pipeline Stage 3: Overflow Detection & Result Selection
    // ------------------------------------------
    reg                          overflow_stage3;
    reg  [WIDTH-1:0]             signed_out_stage3;
    reg                          valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow_stage3   <= 1'b0;
            signed_out_stage3 <= {WIDTH{1'b0}};
            valid_stage3      <= 1'b0;
        end else begin
            overflow_stage3   <= sign_bit_stage2;
            signed_out_stage3 <= sign_bit_stage2 ? {1'b0, unsigned_part_stage2} : unsigned_in_stage2;
            valid_stage3      <= valid_stage2;
        end
    end

    // -------------------------------
    // Pipeline Stage 4: Output Register
    // -------------------------------
    reg                          overflow_stage4;
    reg  [WIDTH-1:0]             signed_out_stage4;
    reg                          valid_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            overflow_stage4   <= 1'b0;
            signed_out_stage4 <= {WIDTH{1'b0}};
            valid_stage4      <= 1'b0;
        end else begin
            overflow_stage4   <= overflow_stage3;
            signed_out_stage4 <= signed_out_stage3;
            valid_stage4      <= valid_stage3;
        end
    end

    // -------------------------------
    // Output Assignments
    // -------------------------------
    assign overflow   = overflow_stage4;
    assign signed_out = signed_out_stage4;
    assign valid_out  = valid_stage4;

endmodule