//SystemVerilog
module mux_dff (
    input wire clk,           // Clock input
    input wire rst_n,         // Active low reset
    input wire valid_in,      // Input valid signal
    input wire sel,           // Select signal
    input wire d0,            // Data input 0
    input wire d1,            // Data input 1
    output reg q,             // Output register
    output reg valid_out      // Output valid signal
);

    // Internal pipeline registers and signals
    reg sel_stage1;           // Stage 1 registered select signal
    reg d0_stage1;            // Stage 1 registered d0 input
    reg d1_stage1;            // Stage 1 registered d1 input
    reg data_selected_stage2; // Stage 2 selected data
    reg valid_stage1;         // Valid signal for stage 1
    reg valid_stage2;         // Valid signal for stage 2

    // Stage 1: Register inputs and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_stage1 <= 1'b0;
            d0_stage1 <= 1'b0;
            d1_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            sel_stage1 <= sel;
            d0_stage1 <= d0;
            d1_stage1 <= d1;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: Selection logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_selected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_selected_stage2 <= sel_stage1 ? d1_stage1 : d0_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            q <= data_selected_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule