//SystemVerilog
// SystemVerilog
// Submodule for the core logic - no change needed for this simple logic
module not_logic (
    input wire in_A,
    output wire out_Y
);
    assign out_Y = ~in_A;
endmodule

// Top module with clocking and pipelined instantiation
module not_gate_clk_pipelined (
    input wire clk,
    input wire reset_n, // Active low reset
    input wire A,
    input wire valid_in, // Input valid signal
    output reg Y,
    output reg valid_out // Output valid signal
);

    // Stage 1: Input register
    reg A_stage1;
    reg valid_stage1;

    // Stage 2: Logic operation and output register
    wire logic_out_stage2;
    reg Y_stage2;
    reg valid_stage2;

    // Stage 1: Register input and valid signal
    always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            A_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            A_stage1 <= A;
            valid_stage1 <= valid_in;
        end
    end

    // Instantiate the logic submodule - operates on stage 1 data
    not_logic u_not_logic_stage2 (
        .in_A(A_stage1),
        .out_Y(logic_out_stage2)
    );

    // Stage 2: Register the logic output and valid signal
    always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            Y_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            Y_stage2 <= logic_out_stage2;
            valid_stage2 <= valid_stage1; // Propagate valid signal
        end
    end

    // Final Output Stage: Register the final output and valid signal
    // This stage registers the output from stage 2.
    // In this simple case, it's just the final output register.
    always @ (posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            Y <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            Y <= Y_stage2;
            valid_out <= valid_stage2; // Propagate valid signal
        end
    end

endmodule