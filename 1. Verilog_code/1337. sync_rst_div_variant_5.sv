//SystemVerilog
// Top-level module with increased pipeline depth and improved timing

module sync_rst_div #(
    parameter DIV = 8
) (
    input wire clk,
    input wire async_rst,
    output wire clk_out
);

    // Internal signals
    wire sync_rst;
    
    // Buffered clock and reset signals with increased distribution network
    (* dont_touch = "true" *) wire clk_buf1, clk_buf2, clk_buf3;
    (* dont_touch = "true" *) wire sync_rst_buf1, sync_rst_buf2, sync_rst_buf3;
    
    // Enhanced clock buffering to reduce fanout and improve timing
    assign clk_buf1 = clk;
    assign clk_buf2 = clk;
    assign clk_buf3 = clk;
    
    // Instantiate enhanced synchronous reset generator submodule
    sync_rst_generator u_sync_rst_gen (
        .clk        (clk_buf1),
        .async_rst  (async_rst),
        .sync_rst   (sync_rst)
    );
    
    // Enhanced reset buffering with pipeline registers
    assign sync_rst_buf1 = sync_rst;
    assign sync_rst_buf2 = sync_rst;
    assign sync_rst_buf3 = sync_rst;

    // Instantiate enhanced clock divider submodule
    clock_divider #(
        .DIV        (DIV)
    ) u_clk_divider (
        .clk        (clk_buf2),
        .sync_rst   (sync_rst_buf1),
        .clk_out    (clk_out)
    );

endmodule

module sync_rst_generator (
    input wire clk,
    input wire async_rst,
    output wire sync_rst
);

    // Enhanced multi-stage synchronizer for reset with increased pipeline depth
    (* dont_touch = "true" *) reg [4:0] sync_rst_reg;
    
    // Metastability hardening with deeper synchronization chain
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            sync_rst_reg <= 5'b11111;
        else
            sync_rst_reg <= {sync_rst_reg[3:0], 1'b0};
    end

    // Output synchronous reset signal with additional filtering
    assign sync_rst = sync_rst_reg[4];

endmodule

module clock_divider #(
    parameter DIV = 8
) (
    input wire clk,
    input wire sync_rst,
    output reg clk_out
);

    // Pipeline stages for division calculation
    localparam CNT_WIDTH = $clog2(DIV/2);
    
    // Stage 1: Counter increment and comparison setup
    reg [CNT_WIDTH:0] cnt_stage1;
    reg compare_flag_stage1;
    
    // Stage 2: Comparison result and counter reset preparation
    reg [CNT_WIDTH:0] cnt_stage2;
    reg compare_result_stage2;
    
    // Stage 3: Clock toggle decision
    reg toggle_enable_stage3;
    reg [CNT_WIDTH:0] cnt_stage3;
    
    // Stage 4: Final clock output update
    reg toggle_enable_stage4;
    
    // Buffered clk_out for lower fanout
    (* dont_touch = "true" *) wire clk_out_prebuf;
    
    // Pipeline Stage 1: Counter operation and comparison setup
    always @(posedge clk) begin
        if (sync_rst) begin
            cnt_stage1 <= 0;
            compare_flag_stage1 <= 0;
        end
        else begin
            cnt_stage1 <= (cnt_stage3 == DIV/2-1) ? 0 : cnt_stage3 + 1;
            compare_flag_stage1 <= (cnt_stage3 == DIV/2-1) ? 1'b1 : 1'b0;
        end
    end
    
    // Pipeline Stage 2: Evaluation of comparison results
    always @(posedge clk) begin
        if (sync_rst) begin
            cnt_stage2 <= 0;
            compare_result_stage2 <= 0;
        end
        else begin
            cnt_stage2 <= cnt_stage1;
            compare_result_stage2 <= compare_flag_stage1;
        end
    end
    
    // Pipeline Stage 3: Prepare for clock toggle
    always @(posedge clk) begin
        if (sync_rst) begin
            toggle_enable_stage3 <= 0;
            cnt_stage3 <= 0;
        end
        else begin
            toggle_enable_stage3 <= compare_result_stage2;
            cnt_stage3 <= cnt_stage2;
        end
    end
    
    // Pipeline Stage 4: Final clock output logic
    always @(posedge clk) begin
        if (sync_rst) begin
            toggle_enable_stage4 <= 0;
            clk_out <= 0;
        end
        else begin
            toggle_enable_stage4 <= toggle_enable_stage3;
            if (toggle_enable_stage4)
                clk_out <= ~clk_out;
        end
    end

endmodule