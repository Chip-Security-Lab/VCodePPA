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
    
    localparam IDLE = 2'b00;
    localparam DMA_WAIT = 2'b01;
    localparam INT_PROCESS = 2'b10;
    localparam CTX_SAVE = 2'b11;
    
    // Borrow subtractor implementation
    wire [7:0] pending_next;
    wire [7:0] pending_borrow;
    wire [7:0] pending_diff;
    
    // Generate borrow chain
    assign pending_borrow[0] = 1'b0;
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : borrow_chain
            assign pending_borrow[i] = pending[i-1] & ~pending_next[i-1];
        end
    endgenerate
    
    // Calculate difference with borrow
    assign pending_diff = pending - pending_next;
    assign pending_next = pending | periph_int;
    
    // Reset logic
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
            pending <= pending_next;
        end
    end
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (dma_req && !dma_active) begin
                        state <= DMA_WAIT;
                    end else if (|pending) begin
                        state <= INT_PROCESS;
                    end
                end
                
                DMA_WAIT: begin
                    if (dma_done) begin
                        state <= IDLE;
                    end else if (|pending) begin
                        state <= CTX_SAVE;
                    end
                end
                
                INT_PROCESS: begin
                    if (int_complete) begin
                        state <= IDLE;
                    end
                end
                
                CTX_SAVE: begin
                    state <= INT_PROCESS;
                end
            endcase
        end
    end
    
    // DMA control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dma_gnt <= 1'b0;
            dma_active <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (dma_req && !dma_active) begin
                        dma_gnt <= 1'b1;
                        dma_active <= 1'b1;
                    end
                end
                
                DMA_WAIT: begin
                    dma_gnt <= 1'b0;
                    if (dma_done) begin
                        dma_active <= 1'b0;
                    end
                end
                
                default: begin
                    dma_gnt <= 1'b0;
                end
            endcase
        end
    end
    
    // Interrupt control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_id <= 4'h0;
            int_active <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (|pending) begin
                        int_id <= find_highest(pending);
                        pending[int_id] <= 1'b0;
                        int_active <= 1'b1;
                    end
                end
                
                INT_PROCESS: begin
                    if (int_complete) begin
                        int_active <= 1'b0;
                    end
                end
                
                CTX_SAVE: begin
                    int_id <= find_highest(pending);
                    pending[int_id] <= 1'b0;
                    int_active <= 1'b1;
                end
                
                default: begin
                    // No changes to int signals in other states
                end
            endcase
        end
    end
    
    // Context save request control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctx_save_req <= 1'b0;
        end else begin
            case (state)
                DMA_WAIT: begin
                    if (|pending) begin
                        ctx_save_req <= 1'b1;
                    end
                end
                
                CTX_SAVE: begin
                    ctx_save_req <= 1'b0;
                end
                
                default: begin
                    ctx_save_req <= 1'b0;
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