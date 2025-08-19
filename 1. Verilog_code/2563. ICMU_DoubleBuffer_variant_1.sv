//SystemVerilog
module ICMU_DoubleBuffer #(
    parameter DW = 32,
    parameter DEPTH = 8
)(
    input clk,
    input rst_sync,
    input buffer_swap,
    input context_valid,
    input [DW-1:0] ctx_in,
    output [DW-1:0] ctx_out,
    output reg ready_out
);
    reg [DW-1:0] buffer_A [0:DEPTH-1];
    reg [DW-1:0] buffer_B [0:DEPTH-1];
    reg buf_select;
    reg [1:0] state;
    reg [1:0] next_state;
    reg [DW-1:0] ctx_in_reg;
    reg context_valid_reg;
    reg buffer_swap_reg;
    reg buf_select_next;
    reg [DW-1:0] ctx_out_reg;

    // State encoding
    localparam IDLE = 2'b00;
    localparam WRITE_A = 2'b01;
    localparam WRITE_B = 2'b10;
    localparam SWAP = 2'b11;

    // Stage 1: Input Register Stage
    always @(posedge clk) begin
        if (rst_sync) begin
            ctx_in_reg <= 0;
            context_valid_reg <= 0;
            buffer_swap_reg <= 0;
        end else begin
            ctx_in_reg <= ctx_in;
            context_valid_reg <= context_valid;
            buffer_swap_reg <= buffer_swap;
        end
    end

    // Stage 2: State and Control Logic
    always @(posedge clk) begin
        if (rst_sync) begin
            state <= IDLE;
            buf_select <= 0;
            buf_select_next <= 0;
        end else begin
            state <= next_state;
            buf_select <= buf_select_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = state;
        buf_select_next = buf_select;
        
        case (state)
            IDLE: begin
                if (buffer_swap_reg) begin
                    next_state = SWAP;
                end else if (context_valid_reg) begin
                    next_state = buf_select ? WRITE_B : WRITE_A;
                end
            end
            WRITE_A: begin
                next_state = IDLE;
            end
            WRITE_B: begin
                next_state = IDLE;
            end
            SWAP: begin
                buf_select_next = ~buf_select;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Stage 3: Data Path
    always @(posedge clk) begin
        if (rst_sync) begin
            buffer_A[0] <= 0;
            buffer_B[0] <= 0;
            ctx_out_reg <= 0;
        end else begin
            if (state == WRITE_A) begin
                buffer_A[0] <= ctx_in_reg;
            end
            if (state == WRITE_B) begin
                buffer_B[0] <= ctx_in_reg;
            end
            ctx_out_reg <= buf_select ? buffer_B[0] : buffer_A[0];
        end
    end

    // Stage 4: Output Stage
    always @(posedge clk) begin
        if (rst_sync) begin
            ready_out <= 0;
        end else begin
            ready_out <= (state == IDLE) || (state == SWAP);
        end
    end

    assign ctx_out = ctx_out_reg;
endmodule