//SystemVerilog
module CrossMux #(parameter DW=8) (
    input clk,
    input rst_n,
    input [3:0][DW-1:0] in,
    input [1:0] x_sel, y_sel,
    input  valid_in,
    output reg [DW+1:0] out,
    output reg          valid_out
);

    // Stage 1: Input selection and first pipeline register
    reg [DW-1:0] selected_data_stage1;
    reg [1:0]    y_sel_stage1;
    reg          valid_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_data_stage1 <= {DW{1'b0}};
            y_sel_stage1         <= 2'b00;
            valid_stage1         <= 1'b0;
        end else begin
            selected_data_stage1 <= in[x_sel];
            y_sel_stage1         <= y_sel;
            valid_stage1         <= valid_in;
        end
    end

    // Stage 2: Adder input preparation and pipeline register
    reg [3:0] adder_a_stage2, adder_b_stage2;
    reg [DW-1:0] selected_data_stage2;
    reg          valid_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adder_a_stage2        <= 4'b0;
            adder_b_stage2        <= 4'b0;
            selected_data_stage2  <= {DW{1'b0}};
            valid_stage2          <= 1'b0;
        end else begin
            adder_a_stage2        <= selected_data_stage1[3:0];
            adder_b_stage2        <= {2'b00, y_sel_stage1};
            selected_data_stage2  <= selected_data_stage1;
            valid_stage2          <= valid_stage1;
        end
    end

    // Stage 3: Adder calculation and pipeline register
    wire [3:0] sum_result_stage3;
    wire       carry_out_stage3;
    CarryLookaheadAdder4 u_cla4 (
        .a   (adder_a_stage2),
        .b   (adder_b_stage2),
        .cin (1'b0),
        .sum (sum_result_stage3),
        .cout(carry_out_stage3)
    );

    reg [3:0] sum_result_stage3_reg;
    reg       carry_out_stage3_reg;
    reg [DW-1:0] selected_data_stage3;
    reg          valid_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_result_stage3_reg   <= 4'b0;
            carry_out_stage3_reg    <= 1'b0;
            selected_data_stage3    <= {DW{1'b0}};
            valid_stage3            <= 1'b0;
        end else begin
            sum_result_stage3_reg   <= sum_result_stage3;
            carry_out_stage3_reg    <= carry_out_stage3;
            selected_data_stage3    <= selected_data_stage2;
            valid_stage3            <= valid_stage2;
        end
    end

    // Stage 4: Parity calculation and output register
    wire parity_bit_stage4;
    assign parity_bit_stage4 = ^selected_data_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out       <= {(DW+2){1'b0}};
            valid_out <= 1'b0;
        end else begin
            out       <= {parity_bit_stage4, sum_result_stage3_reg, carry_out_stage3_reg};
            valid_out <= valid_stage3;
        end
    end

endmodule

module CarryLookaheadAdder4 (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] p, g;
    wire [4:0] c;

    assign p = a ^ b; // Propagate
    assign g = a & b; // Generate

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] 
                | (p[3] & g[2]) 
                | (p[3] & p[2] & g[1]) 
                | (p[3] & p[2] & p[1] & g[0]) 
                | (p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum  = p ^ c[3:0];
    assign cout = c[4];
endmodule