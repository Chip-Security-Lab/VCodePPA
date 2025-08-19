//SystemVerilog
module dma_icmu (
    input clk, rst_n,
    input [7:0] periph_int,
    input dma_req, dma_done,
    input [31:0] dma_addr,
    input [15:0] dma_length,
    output reg dma_gnt,
    output reg ctx_save_req,
    output reg [3:0] int_id,
    output reg int_active,
    input int_complete
);

    // Pipeline registers
    reg [7:0] pending_stage1, pending_stage2;
    reg dma_active_stage1, dma_active_stage2;
    reg [1:0] state_stage1, state_stage2;
    reg dma_gnt_stage1, dma_gnt_stage2;
    reg ctx_save_req_stage1, ctx_save_req_stage2;
    reg [3:0] int_id_stage1, int_id_stage2;
    reg int_active_stage1, int_active_stage2;
    reg valid_stage1, valid_stage2;

    // Pipeline control
    reg pipeline_stall;
    
    localparam IDLE = 2'b00;
    localparam DMA_WAIT = 2'b01;
    localparam INT_PROCESS = 2'b10;
    localparam CTX_SAVE = 2'b11;

    // Stage 1: Interrupt detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else if (!pipeline_stall) begin
            pending_stage1 <= pending_stage2 | periph_int;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 1: DMA state tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_active_stage1 <= 1'b0;
            state_stage1 <= IDLE;
        end else if (!pipeline_stall) begin
            dma_active_stage1 <= dma_active_stage2;
            state_stage1 <= state_stage2;
        end
    end

    // Stage 2: DMA control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_gnt_stage2 <= 1'b0;
            dma_active_stage2 <= 1'b0;
        end else if (!pipeline_stall) begin
            dma_gnt_stage2 <= (state_stage1 == IDLE && dma_req && !dma_active_stage1) ? 1'b1 : 
                            (state_stage1 == DMA_WAIT) ? 1'b0 : dma_gnt_stage2;
            dma_active_stage2 <= (state_stage1 == IDLE && dma_req && !dma_active_stage1) ? 1'b1 :
                               (state_stage1 == DMA_WAIT && dma_done) ? 1'b0 : dma_active_stage1;
        end
    end

    // Stage 2: Interrupt processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id_stage2 <= 4'h0;
            int_active_stage2 <= 1'b0;
            pending_stage2 <= 8'h00;
        end else if (!pipeline_stall) begin
            if (state_stage1 == IDLE && |pending_stage1) begin
                int_id_stage2 <= find_highest(pending_stage1);
                pending_stage2 <= pending_stage1 & ~(8'b1 << int_id_stage2);
                int_active_stage2 <= 1'b1;
            end else if (state_stage1 == CTX_SAVE) begin
                int_id_stage2 <= find_highest(pending_stage1);
                pending_stage2 <= pending_stage1 & ~(8'b1 << int_id_stage2);
                int_active_stage2 <= 1'b1;
            end else if (state_stage1 == INT_PROCESS && int_complete) begin
                int_active_stage2 <= 1'b0;
            end else begin
                pending_stage2 <= pending_stage1;
            end
        end
    end

    // Stage 2: Context save control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctx_save_req_stage2 <= 1'b0;
        end else if (!pipeline_stall) begin
            ctx_save_req_stage2 <= (state_stage1 == DMA_WAIT && |pending_stage1) ? 1'b1 :
                                 (state_stage1 == CTX_SAVE) ? 1'b0 : ctx_save_req_stage2;
        end
    end

    // Stage 2: State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
        end else if (!pipeline_stall) begin
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_gnt <= 1'b0;
            ctx_save_req <= 1'b0;
            int_id <= 4'h0;
            int_active <= 1'b0;
        end else if (!pipeline_stall) begin
            dma_gnt <= dma_gnt_stage2;
            ctx_save_req <= ctx_save_req_stage2;
            int_id <= int_id_stage2;
            int_active <= int_active_stage2;
        end
    end

    // Pipeline control logic
    always @(*) begin
        pipeline_stall = (state_stage1 == DMA_WAIT && dma_done) ||
                        (state_stage1 == INT_PROCESS && int_complete) ||
                        (state_stage1 == CTX_SAVE);
    end

    function [3:0] find_highest;
        input [7:0] ints;
        reg [3:0] result;
        integer i;
        begin
            result = 4'h0;
            for (i = 7; i >= 0; i=i-1)
                if (ints[i]) result = i[3:0];
            find_highest = result;
        end
    endfunction

endmodule