//SystemVerilog
module default_value_mux #(
    parameter WIDTH = 12,
    parameter DEFAULT_VAL = {WIDTH{1'b1}}
)(
    input logic clk,
    input logic rst_n,
    input logic [WIDTH-1:0] data_a, data_b, data_c,
    input logic [1:0] mux_select,
    input logic use_default,
    output logic [WIDTH-1:0] mux_result
);

    // Pipeline stage 1: Input selection
    logic [WIDTH-1:0] sel_a, sel_b, sel_c;
    logic [WIDTH-1:0] stage1_out;
    logic [1:0] mux_select_r;
    logic use_default_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_select_r <= '0;
            use_default_r <= '0;
        end else begin
            mux_select_r <= mux_select;
            use_default_r <= use_default;
        end
    end

    // Pipeline stage 2: Selection combination
    logic [WIDTH-1:0] stage2_out;
    logic [WIDTH-1:0] selected;

    always_comb begin
        // First stage: Generate individual selections
        sel_a = {WIDTH{mux_select_r == 2'b00}} & data_a;
        sel_b = {WIDTH{mux_select_r == 2'b01}} & data_b;
        sel_c = {WIDTH{mux_select_r == 2'b10}} & data_c;
        
        // Second stage: Combine selections
        stage1_out = sel_a | sel_b | sel_c;
        
        // Final selection
        selected = (mux_select_r == 2'b11) ? DEFAULT_VAL : stage1_out;
    end

    // Pipeline stage 3: Output selection
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_out <= '0;
        end else begin
            stage2_out <= selected;
        end
    end

    // Final output stage
    always_comb begin
        mux_result = use_default_r ? DEFAULT_VAL : stage2_out;
    end

endmodule