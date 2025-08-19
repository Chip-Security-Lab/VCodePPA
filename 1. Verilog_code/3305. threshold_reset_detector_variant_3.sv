//SystemVerilog
module threshold_reset_detector #(
    parameter WIDTH = 8
)(
    input  wire                clk,
    input  wire                enable,
    input  wire [WIDTH-1:0]    voltage_level,
    input  wire [WIDTH-1:0]    threshold,
    output reg                 reset_out
);

    // Pipeline Stage 1: Threshold Comparison using conditional negation subtractor (3 bits)
    wire [2:0]                 comp_a;
    wire [2:0]                 comp_b;
    wire [2:0]                 comp_b_inv;
    wire                       comp_cin;
    wire [2:0]                 comp_sum;
    wire                       comp_cout;
    wire                       comp_result;

    assign comp_a     = voltage_level[2:0];
    assign comp_b     = threshold[2:0];
    assign comp_b_inv = ~comp_b;
    assign comp_cin   = 1'b1;

    assign {comp_cout, comp_sum} = {1'b0, comp_a} + {1'b0, comp_b_inv} + comp_cin;
    assign comp_result = comp_cout == 1'b0; // comp_a < comp_b

    reg stage1_is_under;
    always @(posedge clk) begin
        if (!enable)
            stage1_is_under <= 1'b0;
        else
            stage1_is_under <= comp_result;
    end

    // Pipeline Stage 2: Consecutive Under Counter (3 bits)
    reg [2:0] stage2_under_counter;
    wire [2:0] counter_limit;
    wire [2:0] counter_next;
    assign counter_limit = 3'd5;

    assign counter_next = (stage2_under_counter < counter_limit) ?
                         (stage2_under_counter + 3'd1) : counter_limit;

    always @(posedge clk) begin
        if (!enable) begin
            stage2_under_counter <= 3'd0;
        end else begin
            if (stage1_is_under) begin
                stage2_under_counter <= counter_next;
            end else begin
                stage2_under_counter <= 3'd0;
            end
        end
    end

    // Pipeline Stage 3: Reset Output Generation using conditional negation subtractor (3 bits)
    wire [2:0] threshold3;
    wire [2:0] stage2_cnt;
    wire [2:0] threshold3_inv;
    wire       cmp3_cin;
    wire [2:0] cmp3_sum;
    wire       cmp3_cout;
    wire       cmp3_result;

    assign threshold3     = 3'd3;
    assign stage2_cnt     = stage2_under_counter;
    assign threshold3_inv = ~threshold3;
    assign cmp3_cin       = 1'b1;

    assign {cmp3_cout, cmp3_sum} = {1'b0, stage2_cnt} + {1'b0, threshold3_inv} + cmp3_cin;
    assign cmp3_result = cmp3_cout;

    reg stage3_reset_condition;
    always @(posedge clk) begin
        if (!enable)
            stage3_reset_condition <= 1'b0;
        else
            stage3_reset_condition <= cmp3_result;
    end

    // Output Register
    always @(posedge clk) begin
        reset_out <= stage3_reset_condition;
    end

endmodule