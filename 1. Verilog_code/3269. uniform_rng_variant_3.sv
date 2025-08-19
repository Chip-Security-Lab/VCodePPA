//SystemVerilog
module uniform_rng (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        en_i,
    output reg [15:0]  random_o
);

    // Stage 1: State Registers
    reg [31:0] state_x_stage1, state_y_stage1, state_z_stage1, state_w_stage1;

    // Stage 2: Intermediate Calculation Registers
    reg [31:0] x_next_stage2, y_next_stage2, z_next_stage2, w_next_stage2;

    // Stage 3: Output Register
    reg [31:0] w_out_stage3;

    // Internal wire for xorshift computation
    reg [31:0] x_xorshift_result;

    //========================================================
    // Stage 1: State Initialization (reset)
    //========================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            state_x_stage1 <= 32'h12345678;
            state_y_stage1 <= 32'h9ABCDEF0;
            state_z_stage1 <= 32'h13579BDF;
            state_w_stage1 <= 32'h2468ACE0;
        end
    end

    //========================================================
    // Stage 1: State Update (enable)
    //========================================================
    always @(posedge clk_i) begin
        if (!rst_i && en_i) begin
            state_x_stage1 <= x_next_stage2;
            state_y_stage1 <= y_next_stage2;
            state_z_stage1 <= z_next_stage2;
            state_w_stage1 <= w_next_stage2;
        end
    end

    //========================================================
    // Stage 2: XORShift Calculation (x_xorshift_result)
    //========================================================
    always @(*) begin
        x_xorshift_result = (state_x_stage1 ^ (state_x_stage1 << 11)) 
                          ^ ((state_x_stage1 ^ (state_x_stage1 << 11)) >> 8)
                          ^ (state_y_stage1 ^ (state_y_stage1 >> 19));
    end

    //========================================================
    // Stage 2: Intermediate Register Reset
    //========================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            x_next_stage2 <= 32'h12345678;
            y_next_stage2 <= 32'h9ABCDEF0;
            z_next_stage2 <= 32'h13579BDF;
            w_next_stage2 <= 32'h2468ACE0;
        end
    end

    //========================================================
    // Stage 2: Intermediate Register Update (enable)
    //========================================================
    always @(posedge clk_i) begin
        if (!rst_i && en_i) begin
            x_next_stage2 <= x_xorshift_result;
            y_next_stage2 <= state_z_stage1;
            z_next_stage2 <= state_w_stage1;
            w_next_stage2 <= x_next_stage2;
        end
    end

    //========================================================
    // Stage 3: Output Pipeline Register Reset
    //========================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            w_out_stage3 <= 32'h2468ACE0;
        end
    end

    //========================================================
    // Stage 3: Output Pipeline Register Update (enable)
    //========================================================
    always @(posedge clk_i) begin
        if (!rst_i && en_i) begin
            w_out_stage3 <= w_next_stage2;
        end
    end

    //========================================================
    // Stage 3: Output Register Reset
    //========================================================
    always @(posedge clk_i) begin
        if (rst_i) begin
            random_o <= 16'h0;
        end
    end

    //========================================================
    // Stage 3: Output Register Update (enable)
    //========================================================
    always @(posedge clk_i) begin
        if (!rst_i && en_i) begin
            random_o <= w_out_stage3[15:0];
        end
    end

endmodule