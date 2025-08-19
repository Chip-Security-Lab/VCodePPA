//SystemVerilog
module counter_clock_gate (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output wire clk_out
);
    // Internal signals
    wire compare_result_stage1;
    wire compare_result_stage2;
    wire [3:0] cnt_stage1;

    // Counter submodule instantiation
    counter_module counter_inst (
        .clk_in          (clk_in),
        .rst_n           (rst_n),
        .div_ratio       (div_ratio),
        .cnt_out         (cnt_stage1),
        .compare_result  (compare_result_stage1)
    );

    // Pipeline register submodule instantiation
    pipeline_register pipeline_inst (
        .clk_in          (clk_in),
        .rst_n           (rst_n),
        .compare_in      (compare_result_stage1),
        .compare_out     (compare_result_stage2)
    );

    // Clock gating submodule instantiation
    clock_gate_module clock_gate_inst (
        .clk_in          (clk_in),
        .enable          (compare_result_stage2),
        .clk_out         (clk_out)
    );
endmodule

// Counter module for handling the counting and comparison logic
module counter_module (
    input  wire clk_in,
    input  wire rst_n,
    input  wire [3:0] div_ratio,
    output reg  [3:0] cnt_out,
    output reg  compare_result
);
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            cnt_out <= 4'b0;
            compare_result <= 1'b1; // Initialize as true to generate first clock
        end else begin
            cnt_out <= (cnt_out == div_ratio) ? 4'b0 : cnt_out + 1'b1;
            compare_result <= (cnt_out == div_ratio) || (cnt_out == 4'b0);
        end
    end
endmodule

// Pipeline register module for ensuring proper timing
module pipeline_register (
    input  wire clk_in,
    input  wire rst_n,
    input  wire compare_in,
    output reg  compare_out
);
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            compare_out <= 1'b1;
        else
            compare_out <= compare_in;
    end
endmodule

// Clock gating module for generating the output clock
module clock_gate_module (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    // Clock gating implementation
    assign clk_out = clk_in & enable;
endmodule