//SystemVerilog
module multi_phase_clk_gen(
    input  wire clk_in,
    input  wire reset,
    output reg  clk_0,    // 0 degrees
    output reg  clk_90,   // 90 degrees
    output reg  clk_180,  // 180 degrees
    output reg  clk_270   // 270 degrees
);

    // Stage 1: Counter register
    reg [1:0] phase_counter_stage1;
    reg [1:0] phase_counter_stage2;

    // Stage 2: Phase decode pipeline registers
    reg phase_0_stage2, phase_0_stage3;
    reg phase_90_stage2, phase_90_stage3;
    reg phase_180_stage2, phase_180_stage3;
    reg phase_270_stage2, phase_270_stage3;

    // Pipeline Stage 1: Counter Update
    always @(posedge clk_in or posedge reset) begin
        if (reset)
            phase_counter_stage1 <= 2'b00;
        else
            phase_counter_stage1 <= phase_counter_stage1 + 2'b01;
    end

    // Pipeline Stage 2: Counter Register Forwarding
    always @(posedge clk_in or posedge reset) begin
        if (reset)
            phase_counter_stage2 <= 2'b00;
        else
            phase_counter_stage2 <= phase_counter_stage1;
    end

    // Pipeline Stage 3: Phase Decoding (flattened if-else structure)
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_0_stage2   <= 1'b0;
            phase_90_stage2  <= 1'b0;
            phase_180_stage2 <= 1'b0;
            phase_270_stage2 <= 1'b0;
        end else if (phase_counter_stage2 == 2'b00) begin
            phase_0_stage2   <= 1'b1;
            phase_90_stage2  <= 1'b0;
            phase_180_stage2 <= 1'b0;
            phase_270_stage2 <= 1'b0;
        end else if (phase_counter_stage2 == 2'b01) begin
            phase_0_stage2   <= 1'b0;
            phase_90_stage2  <= 1'b1;
            phase_180_stage2 <= 1'b0;
            phase_270_stage2 <= 1'b0;
        end else if (phase_counter_stage2 == 2'b10) begin
            phase_0_stage2   <= 1'b0;
            phase_90_stage2  <= 1'b0;
            phase_180_stage2 <= 1'b1;
            phase_270_stage2 <= 1'b0;
        end else if (phase_counter_stage2 == 2'b11) begin
            phase_0_stage2   <= 1'b0;
            phase_90_stage2  <= 1'b0;
            phase_180_stage2 <= 1'b0;
            phase_270_stage2 <= 1'b1;
        end
    end

    // Pipeline Stage 4: Output Registering (flattened if-else structure)
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_0_stage3   <= 1'b0;
            phase_90_stage3  <= 1'b0;
            phase_180_stage3 <= 1'b0;
            phase_270_stage3 <= 1'b0;
        end else if (phase_0_stage2) begin
            phase_0_stage3   <= 1'b1;
            phase_90_stage3  <= 1'b0;
            phase_180_stage3 <= 1'b0;
            phase_270_stage3 <= 1'b0;
        end else if (phase_90_stage2) begin
            phase_0_stage3   <= 1'b0;
            phase_90_stage3  <= 1'b1;
            phase_180_stage3 <= 1'b0;
            phase_270_stage3 <= 1'b0;
        end else if (phase_180_stage2) begin
            phase_0_stage3   <= 1'b0;
            phase_90_stage3  <= 1'b0;
            phase_180_stage3 <= 1'b1;
            phase_270_stage3 <= 1'b0;
        end else if (phase_270_stage2) begin
            phase_0_stage3   <= 1'b0;
            phase_90_stage3  <= 1'b0;
            phase_180_stage3 <= 1'b0;
            phase_270_stage3 <= 1'b1;
        end
    end

    // Output Assignment (flattened if-else structure)
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            clk_0   <= 1'b0;
            clk_90  <= 1'b0;
            clk_180 <= 1'b0;
            clk_270 <= 1'b0;
        end else if (phase_0_stage3) begin
            clk_0   <= 1'b1;
            clk_90  <= 1'b0;
            clk_180 <= 1'b0;
            clk_270 <= 1'b0;
        end else if (phase_90_stage3) begin
            clk_0   <= 1'b0;
            clk_90  <= 1'b1;
            clk_180 <= 1'b0;
            clk_270 <= 1'b0;
        end else if (phase_180_stage3) begin
            clk_0   <= 1'b0;
            clk_90  <= 1'b0;
            clk_180 <= 1'b1;
            clk_270 <= 1'b0;
        end else if (phase_270_stage3) begin
            clk_0   <= 1'b0;
            clk_90  <= 1'b0;
            clk_180 <= 1'b0;
            clk_270 <= 1'b1;
        end
    end

endmodule