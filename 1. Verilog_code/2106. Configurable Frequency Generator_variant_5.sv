//SystemVerilog
module config_freq_gen(
    input wire master_clk,
    input wire rstn,
    input wire [7:0] freq_sel,
    output reg out_clk
);

// Stage 1: Register freq_sel and previous counter
reg [7:0] counter_stage1_r;
reg [7:0] freq_sel_stage1_r;
reg valid_stage1_r;

// Stage 2: Compare and calculate next counter, toggle, and reset
reg [7:0] counter_stage2_r;
reg toggle_stage2_r;
reg reset_counter_stage2_r;
reg valid_stage2_r;

// Stage 3: Register toggle, reset, and counter for output calculation
reg [7:0] counter_stage3_r;
reg toggle_stage3_r;
reg reset_counter_stage3_r;
reg valid_stage3_r;

// Stage 4: Update output clock
reg [7:0] counter_stage4_r;
reg out_clk_next_stage4_r;
reg valid_stage4_r;

// Intermediate wires between stages
wire [7:0] counter_stage2_w;
wire toggle_stage2_w;
wire reset_counter_stage2_w;

wire [7:0] counter_stage3_w;
wire toggle_stage3_w;
wire reset_counter_stage3_w;

wire [7:0] counter_stage4_w;
wire out_clk_next_stage4_w;

// Stage 2 combination logic (split from previous stage)
assign {counter_stage2_w, toggle_stage2_w, reset_counter_stage2_w} =
    (counter_stage1_r >= freq_sel_stage1_r) ?
        {8'd0, 1'b1, 1'b1} :
        {counter_stage1_r + 8'd1, 1'b0, 1'b0};

// Stage 3 pass-through logic
assign counter_stage3_w = counter_stage2_r;
assign toggle_stage3_w  = toggle_stage2_r;
assign reset_counter_stage3_w = reset_counter_stage2_r;

// Stage 4 combination logic for output clock
assign counter_stage4_w = counter_stage3_r;
assign out_clk_next_stage4_w = (toggle_stage3_r) ? ~out_clk : out_clk;

// Pipeline register chain and valid signals
always @(posedge master_clk or negedge rstn) begin
    if (!rstn) begin
        // Stage 1
        counter_stage1_r         <= 8'd0;
        freq_sel_stage1_r        <= 8'd0;
        valid_stage1_r           <= 1'b0;
        // Stage 2
        counter_stage2_r         <= 8'd0;
        toggle_stage2_r          <= 1'b0;
        reset_counter_stage2_r   <= 1'b0;
        valid_stage2_r           <= 1'b0;
        // Stage 3
        counter_stage3_r         <= 8'd0;
        toggle_stage3_r          <= 1'b0;
        reset_counter_stage3_r   <= 1'b0;
        valid_stage3_r           <= 1'b0;
        // Stage 4
        counter_stage4_r         <= 8'd0;
        out_clk_next_stage4_r    <= 1'b0;
        valid_stage4_r           <= 1'b0;
        // Output
        out_clk                  <= 1'b0;
    end else begin
        // Stage 1: Register current counter and freq_sel
        counter_stage1_r         <= counter_stage4_r; // feedback from last stage
        freq_sel_stage1_r        <= freq_sel;
        valid_stage1_r           <= 1'b1;

        // Stage 2: Register outputs of combination logic after input
        counter_stage2_r         <= counter_stage2_w;
        toggle_stage2_r          <= toggle_stage2_w;
        reset_counter_stage2_r   <= reset_counter_stage2_w;
        valid_stage2_r           <= valid_stage1_r;

        // Stage 3: Register outputs of previous stage
        counter_stage3_r         <= counter_stage3_w;
        toggle_stage3_r          <= toggle_stage3_w;
        reset_counter_stage3_r   <= reset_counter_stage3_w;
        valid_stage3_r           <= valid_stage2_r;

        // Stage 4: Register outputs and prepare for output
        counter_stage4_r         <= counter_stage4_w;
        out_clk_next_stage4_r    <= out_clk_next_stage4_w;
        valid_stage4_r           <= valid_stage3_r;

        // Output stage: Register out_clk
        if (valid_stage4_r) begin
            out_clk <= out_clk_next_stage4_r;
        end
    end
end

endmodule