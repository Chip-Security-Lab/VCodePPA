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
    reg [7:0] pending;
    reg dma_active;
    reg [1:0] state;
    
    localparam IDLE = 2'b00;
    localparam DMA_WAIT = 2'b01;
    localparam INT_PROCESS = 2'b10;
    localparam CTX_SAVE = 2'b11;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pending <= 8'h00;
            dma_active <= 1'b0;
            dma_gnt <= 1'b0;
            ctx_save_req <= 1'b0;
            int_id <= 4'h0;
            int_active <= 1'b0;
            state <= IDLE;
        end else begin
            // Always capture pending interrupts
            pending <= pending | periph_int;
            
            case (state)
                IDLE: begin
                    if (dma_req && !dma_active) begin
                        dma_gnt <= 1'b1;
                        dma_active <= 1'b1;
                        state <= DMA_WAIT;
                    end else if (|pending) begin
                        int_id <= find_highest(pending);
                        pending[int_id] <= 1'b0;
                        int_active <= 1'b1;
                        state <= INT_PROCESS;
                    end
                end
                
                DMA_WAIT: begin
                    dma_gnt <= 1'b0;
                    if (dma_done) begin
                        dma_active <= 1'b0;
                        state <= IDLE;
                    end else if (|pending) begin
                        // Need to pause DMA for interrupt
                        ctx_save_req <= 1'b1;
                        state <= CTX_SAVE;
                    end
                end
                
                INT_PROCESS: begin
                    if (int_complete) begin
                        int_active <= 1'b0;
                        state <= IDLE;
                    end
                end
                
                CTX_SAVE: begin
                    ctx_save_req <= 1'b0;
                    int_id <= find_highest(pending);
                    pending[int_id] <= 1'b0;
                    int_active <= 1'b1;
                    state <= INT_PROCESS;
                end
            endcase
        end
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