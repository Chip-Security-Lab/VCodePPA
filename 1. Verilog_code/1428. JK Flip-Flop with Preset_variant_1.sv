//SystemVerilog
module jk_ff_preset (
    input wire clk,
    input wire preset_n,
    input wire j,
    input wire k,
    input wire valid_in,    // Input validity signal
    output reg q,
    output reg valid_out    // Output validity signal
);
    // Stage 1 registers
    reg [1:0] jk_stage1;
    reg q_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg q_next;
    reg valid_stage2;
    
    // Stage 1: Input capture and state determination
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            jk_stage1 <= 2'b00;
            q_stage1 <= 1'b1;       // Preset state
            valid_stage1 <= 1'b0;
        end else begin
            jk_stage1 <= {j, k};
            q_stage1 <= q;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: State transition calculation
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            q_next <= 1'b1;         // Preset state
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            case (jk_stage1)
                2'b00: q_next <= q_stage1;    // No change
                2'b01: q_next <= 1'b0;        // Reset
                2'b10: q_next <= 1'b1;        // Set
                2'b11: q_next <= ~q_stage1;   // Toggle
            endcase
        end
    end
    
    // Stage 3: Output update
    always @(posedge clk or negedge preset_n) begin
        if (!preset_n) begin
            q <= 1'b1;              // Preset state
            valid_out <= 1'b0;
        end else begin
            q <= q_next;
            valid_out <= valid_stage2;
        end
    end
endmodule