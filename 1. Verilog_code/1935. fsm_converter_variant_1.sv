//SystemVerilog
module fsm_converter #(parameter S_WIDTH=4) (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [S_WIDTH-1:0]        state_in,
    output reg  [2**S_WIDTH-1:0]     state_out
);

    // Stage 0: Input register
    reg [S_WIDTH-1:0] state_in_stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_in_stage0 <= {S_WIDTH{1'b0}};
        else
            state_in_stage0 <= state_in;
    end

    // Stage 1: Adder pipeline
    wire [S_WIDTH-1:0] incremented_state_stage1;
    wire               carry_out_stage1;

    brent_kung_adder_4bit u_bk_adder (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (state_in_stage0),
        .b     (4'd1),
        .sum   (incremented_state_stage1),
        .cout  (carry_out_stage1)
    );

    // Stage 2: Output decode register
    reg [S_WIDTH-1:0] incremented_state_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            incremented_state_stage2 <= {S_WIDTH{1'b0}};
        else
            incremented_state_stage2 <= incremented_state_stage1;
    end

    // Stage 3: Output decode (one-hot)
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_out <= {2**S_WIDTH{1'b0}};
        else begin
            for (i=0; i<2**S_WIDTH; i=i+1) begin
                state_out[i] <= (i == incremented_state_stage2) ? 1'b1 : 1'b0;
            end
        end
    end

endmodule

module brent_kung_adder_4bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [3:0]  a,
    input  wire [3:0]  b,
    output reg  [3:0]  sum,
    output reg         cout
);
    // Pipeline Stage 1: Generate and Propagate
    reg [3:0] a_stage1, b_stage1;
    reg [3:0] g_stage1, p_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 4'b0;
            b_stage1 <= 4'b0;
            g_stage1 <= 4'b0;
            p_stage1 <= 4'b0;
        end else begin
            a_stage1 <= a;
            b_stage1 <= b;
            g_stage1 <= a & b;
            p_stage1 <= a ^ b;
        end
    end

    // Pipeline Stage 2: Brent-Kung carry logic
    reg [3:0] g_stage2, p_stage2;
    reg       g1_0_stage2, p1_0_stage2, g2_1_stage2, p2_1_stage2, g3_2_stage2, p3_2_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage2        <= 4'b0;
            p_stage2        <= 4'b0;
            g1_0_stage2     <= 1'b0;
            p1_0_stage2     <= 1'b0;
            g2_1_stage2     <= 1'b0;
            p2_1_stage2     <= 1'b0;
            g3_2_stage2     <= 1'b0;
            p3_2_stage2     <= 1'b0;
        end else begin
            g_stage2        <= g_stage1;
            p_stage2        <= p_stage1;
            g1_0_stage2     <= g_stage1[1] | (p_stage1[1] & g_stage1[0]);
            p1_0_stage2     <= p_stage1[1] & p_stage1[0];
            g2_1_stage2     <= g_stage1[2] | (p_stage1[2] & g_stage1[1]);
            p2_1_stage2     <= p_stage1[2] & p_stage1[1];
            g3_2_stage2     <= g_stage1[3] | (p_stage1[3] & g_stage1[2]);
            p3_2_stage2     <= p_stage1[3] & p_stage1[2];
        end
    end

    // Pipeline Stage 3: Final carry logic
    reg [3:0] g_stage3, p_stage3;
    reg       g2_0_stage3, p2_0_stage3, g3_1_stage3, p3_1_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g_stage3    <= 4'b0;
            p_stage3    <= 4'b0;
            g2_0_stage3 <= 1'b0;
            p2_0_stage3 <= 1'b0;
            g3_1_stage3 <= 1'b0;
            p3_1_stage3 <= 1'b0;
        end else begin
            g_stage3    <= g_stage2;
            p_stage3    <= p_stage2;
            g2_0_stage3 <= g2_1_stage2 | (p2_1_stage2 & g_stage2[0]);
            p2_0_stage3 <= p2_1_stage2 & p_stage2[0];
            g3_1_stage3 <= g3_2_stage2 | (p3_2_stage2 & g_stage2[1]);
            p3_1_stage3 <= p3_2_stage2 & p_stage2[1];
        end
    end

    // Pipeline Stage 4: Final result
    reg [3:0] carry_stage4;
    reg       g3_0_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum         <= 4'b0;
            cout        <= 1'b0;
            carry_stage4<= 4'b0;
            g3_0_stage4 <= 1'b0;
        end else begin
            carry_stage4[0] <= 1'b0;
            carry_stage4[1] <= g_stage3[0];
            carry_stage4[2] <= g1_0_stage2;
            carry_stage4[3] <= g2_0_stage3;
            g3_0_stage4     <= g3_1_stage3 | (p3_1_stage3 & g_stage3[0]);

            sum[0] <= p_stage3[0] ^ carry_stage4[0];
            sum[1] <= p_stage3[1] ^ carry_stage4[1];
            sum[2] <= p_stage3[2] ^ carry_stage4[2];
            sum[3] <= p_stage3[3] ^ carry_stage4[3];
            cout   <= g3_0_stage4;
        end
    end

endmodule