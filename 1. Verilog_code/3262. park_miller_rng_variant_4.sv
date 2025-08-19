//SystemVerilog
module park_miller_rng_pipeline (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output wire        valid,
    output wire [31:0] rand_val
);
    // Park-Miller constants
    parameter A = 16807;
    parameter M = 32'h7FFFFFFF; // 2^31 - 1
    parameter Q = 127773;       // M / A
    parameter R = 2836;         // M % A
    parameter MQ = 16807 * 127773; // For range checks

    // Stage 1: Register input and rand_val
    reg  [31:0] rand_val_stage1;
    reg         valid_stage1;
    wire [31:0] rand_val_input;

    // Stage 2: Calculate rand_val % Q and rand_val / Q
    reg  [16:0] mod_stage2;
    reg  [14:0] div_stage2;
    reg         valid_stage2;
    reg  [31:0] rand_val_stage2;

    // Stage 3: temp1 = A * (rand_val % Q)
    reg  [47:0] mult_stage3;
    reg  [31:0] rand_val_stage3;
    reg  [14:0] div_stage3;
    reg         valid_stage3;

    // Stage 4: temp2 = (M / Q) * (rand_val / Q)
    reg  [47:0] mult_stage4;
    reg  [47:0] temp_stage4;
    reg         valid_stage4;

    // Stage 5: temp = temp1 - temp2, output logic
    reg  [47:0] temp_stage5;
    reg  [31:0] rand_val_stage5;
    reg         valid_stage5;

    // Stage 6: Output register
    reg  [31:0] rand_val_out;
    reg         valid_stage6;

    // Intermediate signals for always blocks
    reg [31:0] rand_val_stage1_next;
    reg        valid_stage1_next;

    reg [16:0] mod_stage2_next;
    reg [14:0] div_stage2_next;
    reg [31:0] rand_val_stage2_next;
    reg        valid_stage2_next;

    reg [47:0] mult_stage3_next;
    reg [31:0] rand_val_stage3_next;
    reg [14:0] div_stage3_next;
    reg        valid_stage3_next;

    reg [47:0] mult_stage4_next;
    reg [47:0] temp_stage4_next;
    reg        valid_stage4_next;

    reg [47:0] temp_stage5_next;
    reg [31:0] rand_val_stage5_next;
    reg        valid_stage5_next;

    reg [31:0] rand_val_out_next;
    reg        valid_stage6_next;

    // Feedback for pipeline
    assign rand_val_input = (rst) ? 32'd1 : rand_val_out;

    // Stage 1: Next value logic
    always @(*) begin
        if (rst) begin
            rand_val_stage1_next = 32'd1;
            valid_stage1_next    = 1'b0;
        end else if (start) begin
            rand_val_stage1_next = rand_val_input;
            valid_stage1_next    = 1'b1;
        end else begin
            rand_val_stage1_next = rand_val_stage1;
            valid_stage1_next    = 1'b0;
        end
    end

    // Stage 1: Registers
    always @(posedge clk) begin
        rand_val_stage1 <= rand_val_stage1_next;
        valid_stage1    <= valid_stage1_next;
    end

    // Stage 2: Next value logic
    always @(*) begin
        if (rst) begin
            mod_stage2_next      = 17'd0;
            div_stage2_next      = 15'd0;
            rand_val_stage2_next = 32'd0;
            valid_stage2_next    = 1'b0;
        end else begin
            if (rand_val_stage1 < Q) begin
                mod_stage2_next      = rand_val_stage1[16:0];
                div_stage2_next      = 15'd0;
            end else if (rand_val_stage1 < (Q << 1)) begin
                mod_stage2_next      = rand_val_stage1[16:0] - Q;
                div_stage2_next      = 15'd1;
            end else begin
                mod_stage2_next      = rand_val_stage1 % Q;
                div_stage2_next      = rand_val_stage1 / Q;
            end
            rand_val_stage2_next = rand_val_stage1;
            valid_stage2_next    = valid_stage1;
        end
    end

    // Stage 2: Registers
    always @(posedge clk) begin
        mod_stage2      <= mod_stage2_next;
        div_stage2      <= div_stage2_next;
        rand_val_stage2 <= rand_val_stage2_next;
        valid_stage2    <= valid_stage2_next;
    end

    // Stage 3: Next value logic
    always @(*) begin
        if (rst) begin
            mult_stage3_next     = 48'd0;
            div_stage3_next      = 15'd0;
            rand_val_stage3_next = 32'd0;
            valid_stage3_next    = 1'b0;
        end else begin
            mult_stage3_next     = A * mod_stage2;
            div_stage3_next      = div_stage2;
            rand_val_stage3_next = rand_val_stage2;
            valid_stage3_next    = valid_stage2;
        end
    end

    // Stage 3: Registers
    always @(posedge clk) begin
        mult_stage3     <= mult_stage3_next;
        div_stage3      <= div_stage3_next;
        rand_val_stage3 <= rand_val_stage3_next;
        valid_stage3    <= valid_stage3_next;
    end

    // Stage 4: Next value logic
    always @(*) begin
        if (rst) begin
            mult_stage4_next     = 48'd0;
            temp_stage4_next     = 48'd0;
            valid_stage4_next    = 1'b0;
        end else begin
            mult_stage4_next     = (M / Q) * div_stage3;
            temp_stage4_next     = mult_stage3;
            valid_stage4_next    = valid_stage3;
        end
    end

    // Stage 4: Registers
    always @(posedge clk) begin
        mult_stage4     <= mult_stage4_next;
        temp_stage4     <= temp_stage4_next;
        valid_stage4    <= valid_stage4_next;
    end

    // Stage 5: Next value logic
    always @(*) begin
        if (rst) begin
            temp_stage5_next     = 48'd0;
            rand_val_stage5_next = 32'd1;
            valid_stage5_next    = 1'b0;
        end else begin
            temp_stage5_next = temp_stage4 - mult_stage4;
            if (temp_stage4 <= mult_stage4)
                rand_val_stage5_next = temp_stage4 - mult_stage4 + M;
            else
                rand_val_stage5_next = temp_stage4 - mult_stage4;
            valid_stage5_next = valid_stage4;
        end
    end

    // Stage 5: Registers
    always @(posedge clk) begin
        temp_stage5     <= temp_stage5_next;
        rand_val_stage5 <= rand_val_stage5_next;
        valid_stage5    <= valid_stage5_next;
    end

    // Stage 6: Next value logic
    always @(*) begin
        if (rst) begin
            rand_val_out_next  = 32'd1;
            valid_stage6_next  = 1'b0;
        end else if (valid_stage5) begin
            rand_val_out_next  = rand_val_stage5;
            valid_stage6_next  = 1'b1;
        end else begin
            rand_val_out_next  = rand_val_out;
            valid_stage6_next  = 1'b0;
        end
    end

    // Stage 6: Registers
    always @(posedge clk) begin
        rand_val_out  <= rand_val_out_next;
        valid_stage6  <= valid_stage6_next;
    end

    assign rand_val = rand_val_out;
    assign valid    = valid_stage6;

endmodule