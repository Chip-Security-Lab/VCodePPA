//SystemVerilog
module mux_async_reset_pipeline (
    input wire clock,                   // Clock signal
    input wire areset_n,                // Active-low async reset
    input wire [3:0] data_a, data_b,    // Data inputs
    input wire select,                  // Selection control
    input wire in_valid,                // Input valid signal
    output reg [3:0] out_data,          // Output register
    output reg out_valid                // Output valid signal
);

    // Pipeline stage 1 registers
    reg [3:0] data_a_stage1, data_b_stage1;
    reg select_stage1;
    reg valid_stage1;

    // Pipeline stage 2 registers (mux result and valid)
    reg [3:0] mux_result_stage2;
    reg valid_stage2;

    // Stage 1: Register inputs
    always @(posedge clock or negedge areset_n) begin
        if (!areset_n) begin
            data_a_stage1    <= 4'b0;
            data_b_stage1    <= 4'b0;
            select_stage1    <= 1'b0;
            valid_stage1     <= 1'b0;
        end else begin
            data_a_stage1    <= data_a;
            data_b_stage1    <= data_b;
            select_stage1    <= select;
            valid_stage1     <= in_valid;
        end
    end

    // Stage 2: Mux operation and register result
    always @(posedge clock or negedge areset_n) begin
        if (!areset_n) begin
            mux_result_stage2 <= 4'b0;
            valid_stage2      <= 1'b0;
        end else begin
            mux_result_stage2 <= ({4{select_stage1}} & data_b_stage1) |
                                 ({4{~select_stage1}} & data_a_stage1);
            valid_stage2      <= valid_stage1;
        end
    end

    // Output stage: Register output and valid
    always @(posedge clock or negedge areset_n) begin
        if (!areset_n) begin
            out_data  <= 4'b0;
            out_valid <= 1'b0;
        end else begin
            out_data  <= mux_result_stage2;
            out_valid <= valid_stage2;
        end
    end

endmodule