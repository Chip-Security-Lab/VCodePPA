//SystemVerilog
module rng_toggle_9_pipeline_valid_ready (
    input              clk,
    input              rst,
    input              rand_val_ready,      // Downstream ready
    output reg [7:0]   rand_val_out,
    output reg         rand_val_valid
);

    // Stage 1: Input register and valid control
    reg [7:0] rand_val_stage1;
    reg       valid_stage1;

    // Stage 2: XOR computation and output register
    reg [7:0] rand_val_stage2;
    reg       valid_stage2;

    // Internal ready signals for pipeline stages
    wire      stage1_ready;
    wire      stage2_ready;

    // Stage ready logic (backpressure propagation)
    assign stage2_ready = rand_val_ready;
    assign stage1_ready = valid_stage2 ? stage2_ready : 1'b1;

    // Stage 1: Capture or reset
    always @(posedge clk) begin
        if (rst) begin
            rand_val_stage1 <= 8'h55;
            valid_stage1    <= 1'b0;
        end else if (stage1_ready) begin
            // On each valid transfer, propagate last output as input for next cycle
            rand_val_stage1 <= rand_val_stage2;
            valid_stage1    <= valid_stage2;
        end
    end

    // Stage 2: XOR operation and valid propagation
    always @(posedge clk) begin
        if (rst) begin
            rand_val_stage2 <= 8'h55;
            valid_stage2    <= 1'b1; // Output valid after reset
        end else if (stage2_ready) begin
            rand_val_stage2 <= rand_val_stage1 ^ 8'b00000001;
            valid_stage2    <= valid_stage1;
        end
    end

    // Output assignment with valid-ready handshake
    always @(posedge clk) begin
        if (rst) begin
            rand_val_out   <= 8'h55;
            rand_val_valid <= 1'b0;
        end else if (rand_val_ready) begin
            rand_val_out   <= rand_val_stage2;
            rand_val_valid <= valid_stage2;
        end else begin
            rand_val_valid <= valid_stage2;
        end
    end

endmodule