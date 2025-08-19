//SystemVerilog
module linear_to_log #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       linear_in,
    output reg  [WIDTH-1:0]       log_out
);

    // LUT Initialization
    reg [WIDTH-1:0] lut_table [0:LUT_SIZE-1];
    integer idx;

    initial begin : LUT_INIT_BLOCK
        for (idx = 0; idx < LUT_SIZE; idx = idx + 1) begin
            lut_table[idx] = (1 << (idx/2));
        end
    end

    // Pipeline Stage 1: Input Register
    reg [WIDTH-1:0] stage1_linear_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_linear_in <= {WIDTH{1'b0}};
        else
            stage1_linear_in <= linear_in;
    end

    // Pipeline Stage 2: LUT Search (Combinatorial)
    reg [WIDTH-1:0] stage2_candidate_idx;
    reg             stage2_found;
    integer         search_idx;

    always @* begin : LUT_SEARCH_BLOCK
        stage2_candidate_idx = {WIDTH{1'b0}};
        stage2_found = 1'b0;
        for (search_idx = LUT_SIZE-1; search_idx >= 0; search_idx = search_idx - 1) begin
            if (!stage2_found && stage1_linear_in >= lut_table[search_idx]) begin
                stage2_candidate_idx = search_idx[WIDTH-1:0];
                stage2_found = 1'b1;
            end
        end
    end

    // Pipeline Stage 3: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            log_out <= {WIDTH{1'b0}};
        else
            log_out <= stage2_candidate_idx;
    end

endmodule