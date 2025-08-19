//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Standard
// Top-level module
module freq_synthesizer (
    input wire ref_clk,
    input wire reset,
    input wire [1:0] mult_sel, // 00:x1, 01:x2, 10:x4, 11:x8
    output wire clk_out
);
    wire phase_0, phase_90, phase_180, phase_270;
    
    // Instantiate phase generator module
    phase_generator phase_gen (
        .ref_clk(ref_clk),
        .reset(reset),
        .phase_0(phase_0),
        .phase_90(phase_90),
        .phase_180(phase_180),
        .phase_270(phase_270)
    );
    
    // Instantiate frequency multiplier module
    frequency_multiplier freq_mult (
        .ref_clk(ref_clk),
        .reset(reset),
        .mult_sel(mult_sel),
        .phase_0(phase_0),
        .phase_90(phase_90),
        .phase_180(phase_180),
        .phase_270(phase_270),
        .clk_out(clk_out)
    );
    
endmodule

// Module to generate four-phase clock signals
module phase_generator (
    input wire ref_clk,
    input wire reset,
    output reg phase_0,
    output reg phase_90,
    output reg phase_180,
    output reg phase_270
);
    reg [1:0] counter;
    reg [3:0] phase_decode;
    
    // First pipeline stage - counter logic
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            counter <= 2'b00;
        end else begin
            counter <= counter + 2'b01;
        end
    end
    
    // Second pipeline stage - phase decode logic
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            phase_decode <= 4'b0000;
        end else begin
            phase_decode <= 4'b0000;
            case (counter)
                2'b00: phase_decode[0] <= 1'b1;
                2'b01: phase_decode[1] <= 1'b1;
                2'b10: phase_decode[2] <= 1'b1;
                2'b11: phase_decode[3] <= 1'b1;
            endcase
        end
    end
    
    // Final output assignment
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            phase_0 <= 1'b0;
            phase_90 <= 1'b0;
            phase_180 <= 1'b0;
            phase_270 <= 1'b0;
        end else begin
            phase_0 <= phase_decode[0];
            phase_90 <= phase_decode[1];
            phase_180 <= phase_decode[2];
            phase_270 <= phase_decode[3];
        end
    end
endmodule

// Module to multiply the frequency based on selection
module frequency_multiplier (
    input wire ref_clk,
    input wire reset,
    input wire [1:0] mult_sel,
    input wire phase_0,
    input wire phase_90,
    input wire phase_180,
    input wire phase_270,
    output reg clk_out
);
    // Pipeline registers for critical path segmentation
    reg [1:0] mult_sel_reg;
    reg phase_0_reg, phase_90_reg, phase_180_reg, phase_270_reg;
    reg phase_0_180_combined, phase_all_combined;
    reg toggle_clk;
    
    // First pipeline stage - register inputs
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            mult_sel_reg <= 2'b00;
            phase_0_reg <= 1'b0;
            phase_90_reg <= 1'b0;
            phase_180_reg <= 1'b0;
            phase_270_reg <= 1'b0;
        end else begin
            mult_sel_reg <= mult_sel;
            phase_0_reg <= phase_0;
            phase_90_reg <= phase_90;
            phase_180_reg <= phase_180;
            phase_270_reg <= phase_270;
        end
    end
    
    // Second pipeline stage - partial combinations
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            phase_0_180_combined <= 1'b0;
            phase_all_combined <= 1'b0;
            toggle_clk <= 1'b0;
        end else begin
            // Compute partial results
            phase_0_180_combined <= phase_0_reg | phase_180_reg;
            phase_all_combined <= phase_0_reg | phase_90_reg | phase_180_reg | phase_270_reg;
            toggle_clk <= ~toggle_clk;
        end
    end
    
    // Final output stage
    always @(posedge ref_clk or posedge reset) begin
        if (reset) begin
            clk_out <= 1'b0;
        end else begin
            case (mult_sel_reg)
                2'b00: clk_out <= phase_0_reg & ~phase_180_reg; // x1 multiplication
                2'b01: clk_out <= phase_0_180_combined;         // x2 multiplication
                2'b10: clk_out <= phase_all_combined;           // x4 multiplication
                2'b11: clk_out <= toggle_clk;                   // x8 multiplication using toggle
            endcase
        end
    end
endmodule