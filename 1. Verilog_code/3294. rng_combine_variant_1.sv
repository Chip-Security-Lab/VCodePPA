//SystemVerilog
module rng_combine_14_valid_ready (
    input              clk,
    input              rst,
    input              data_valid,
    output reg         data_ready,
    output reg [7:0]   rnd,
    output reg         rnd_valid,
    input              rnd_ready
);

    // Stage 1: Input Latch
    reg [7:0]           rnd_stage1;
    reg                 valid_stage1;
    wire                ready_stage1;

    // Stage 2: Shifting
    reg [7:0]           left_shift_stage2;
    reg [7:0]           right_shift_stage2;
    reg                 valid_stage2;
    wire                ready_stage2;

    // Stage 3: Mixing & Output
    reg [7:0]           mix_stage3;
    reg                 valid_stage3;
    wire                ready_stage3;

    // Pipeline control
    assign ready_stage1  = ~valid_stage1 | ready_stage2;
    assign ready_stage2  = ~valid_stage2 | ready_stage3;
    assign ready_stage3  = ~valid_stage3 | (rnd_valid & rnd_ready);

    // data_ready: accept new input if stage1 is ready
    always @(*) begin
        data_ready = ready_stage1;
    end

    // Stage 1: Input and latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd_stage1   <= 8'h99;
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            if (data_valid && ready_stage1) begin
                rnd_stage1   <= rnd_stage1; // Hold previous value, actual value will be used only when valid
                valid_stage1 <= 1'b1;
            end else if (!data_valid) begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Shifting
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            left_shift_stage2  <= 8'h00;
            right_shift_stage2 <= 8'h00;
            valid_stage2       <= 1'b0;
        end else if (ready_stage2) begin
            if (valid_stage1) begin
                left_shift_stage2  <= {rnd_stage1[4:0], 3'b000};
                right_shift_stage2 <= {2'b00, rnd_stage1[7:2]};
                valid_stage2       <= 1'b1;
            end else begin
                valid_stage2       <= 1'b0;
            end
        end
    end

    // Stage 3: Mixing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mix_stage3   <= 8'h00;
            valid_stage3 <= 1'b0;
        end else if (ready_stage3) begin
            if (valid_stage2) begin
                mix_stage3   <= (left_shift_stage2 ^ right_shift_stage2) ^ 8'h5A;
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rnd       <= 8'h99;
            rnd_valid <= 1'b0;
        end else begin
            if (valid_stage3 && ready_stage3) begin
                rnd       <= mix_stage3;
                rnd_valid <= 1'b1;
            end else if (rnd_valid && rnd_ready) begin
                rnd_valid <= 1'b0;
            end
        end
    end

endmodule