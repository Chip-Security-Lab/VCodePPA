//SystemVerilog
module ICMU_PrioQueue #(
    parameter DW = 64,
    parameter PRIO_LEVELS = 4
)(
    input clk,
    input rst_n,
    input [PRIO_LEVELS-1:0] save_req,
    input [DW-1:0] ctx_in,
    output reg [DW-1:0] ctx_out,
    output reg [PRIO_LEVELS-1:0] ctx_valid
);

    reg [DW-1:0] queue [0:PRIO_LEVELS-1][0:1];
    reg [PRIO_LEVELS-1:0] wr_ptr;
    reg [PRIO_LEVELS-1:0] rd_ptr;
    wire [PRIO_LEVELS-1:0] queue_not_empty;
    wire [PRIO_LEVELS-1:0] next_wr_ptr;
    wire [PRIO_LEVELS-1:0] next_rd_ptr;
    reg [DW-1:0] next_ctx_out;
    reg [PRIO_LEVELS-1:0] next_ctx_valid;

    // Combinational logic for next state
    assign next_wr_ptr = wr_ptr ^ save_req;
    assign next_rd_ptr = rd_ptr ^ queue_not_empty;
    assign queue_not_empty = rd_ptr ^ wr_ptr;

    // Reset and state update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;
            ctx_valid <= next_ctx_valid;
            ctx_out <= next_ctx_out;
        end
    end

    // Queue write and read logic
    always @(*) begin
        next_ctx_out = ctx_out;
        next_ctx_valid = 0;
        
        for (integer i = 0; i < PRIO_LEVELS; i=i+1) begin
            if (save_req[i]) begin
                queue[i][wr_ptr[i]] = ctx_in;
            end
            
            if (queue_not_empty[i]) begin
                next_ctx_out = queue[i][rd_ptr[i]];
                next_ctx_valid[i] = 1;
            end
        end
    end

endmodule