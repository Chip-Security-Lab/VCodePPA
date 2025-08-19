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
    reg [7:0] pending;
    reg dma_active;
    reg [1:0] state;
    
    // Pipeline registers for critical path optimization
    reg [7:0] pending_next;
    reg [3:0] int_id_next;
    reg int_active_next;
    reg dma_gnt_next;
    reg ctx_save_req_next;
    reg [1:0] state_next;
    
    localparam IDLE = 2'b00;
    localparam DMA_WAIT = 2'b01;
    localparam INT_PROCESS = 2'b10;
    localparam CTX_SAVE = 2'b11;
    
    // First stage: Combinational logic for next state calculation
    always @(*) begin
        // Default values
        pending_next = pending | periph_int;
        int_id_next = int_id;
        int_active_next = int_active;
        dma_gnt_next = dma_gnt;
        ctx_save_req_next = ctx_save_req;
        state_next = state;
        
        case (state)
            IDLE: begin
                if (dma_req && !dma_active) begin
                    dma_gnt_next = 1'b1;
                    state_next = DMA_WAIT;
                end else if (|pending) begin
                    int_id_next = find_highest(pending);
                    int_active_next = 1'b1;
                    state_next = INT_PROCESS;
                end
            end
            
            DMA_WAIT: begin
                dma_gnt_next = 1'b0;
                if (dma_done) begin
                    state_next = IDLE;
                end else if (|pending) begin
                    ctx_save_req_next = 1'b1;
                    state_next = CTX_SAVE;
                end
            end
            
            INT_PROCESS: begin
                if (int_complete) begin
                    int_active_next = 1'b0;
                    state_next = IDLE;
                end
            end
            
            CTX_SAVE: begin
                ctx_save_req_next = 1'b0;
                int_id_next = find_highest(pending);
                int_active_next = 1'b1;
                state_next = INT_PROCESS;
            end
        endcase
    end
    
    // Second stage: Sequential logic with pipeline registers
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
            // Update state and control signals from pipeline registers
            pending <= pending_next;
            state <= state_next;
            dma_gnt <= dma_gnt_next;
            ctx_save_req <= ctx_save_req_next;
            int_id <= int_id_next;
            int_active <= int_active_next;
            
            // Update pending interrupts with pipeline register
            if (state == IDLE && |pending && !dma_req) begin
                pending[find_highest(pending)] <= 1'b0;
            end else if (state == CTX_SAVE) begin
                pending[find_highest(pending)] <= 1'b0;
            end
            
            // Update dma_active based on state transitions
            if (state == IDLE && dma_req && !dma_active) begin
                dma_active <= 1'b1;
            end else if (state == DMA_WAIT && dma_done) begin
                dma_active <= 1'b0;
            end
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