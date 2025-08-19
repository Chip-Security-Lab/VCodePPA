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

    reg [DW-1:0] queue [0:(PRIO_LEVELS*2)-1];
    reg [PRIO_LEVELS-1:0] wr_ptr;
    reg [PRIO_LEVELS-1:0] rd_ptr;
    wire [PRIO_LEVELS-1:0] queue_empty;
    wire [PRIO_LEVELS-1:0] queue_full;
    wire [PRIO_LEVELS-1:0] queue_rd_en;
    wire [PRIO_LEVELS-1:0] queue_wr_en;

    // Optimized control signal generation
    assign queue_empty = rd_ptr ^ wr_ptr;
    assign queue_full = ~(rd_ptr ^ wr_ptr);
    assign queue_rd_en = queue_empty & ctx_valid;
    assign queue_wr_en = save_req & (rd_ptr ^ wr_ptr);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            // Write operation with optimized pointer update
            for (int i = 0; i < PRIO_LEVELS; i++) begin
                if (queue_wr_en[i]) begin
                    queue[{i, wr_ptr[i]}] <= ctx_in;
                    wr_ptr[i] <= wr_ptr[i] ^ 1'b1;
                end
            end

            // Read operation with optimized priority encoding
            for (int i = PRIO_LEVELS-1; i >= 0; i--) begin
                if (queue_rd_en[i]) begin
                    ctx_out <= queue[{i, rd_ptr[i]}];
                    rd_ptr[i] <= rd_ptr[i] ^ 1'b1;
                    ctx_valid[i] <= 1'b1;
                end else begin
                    ctx_valid[i] <= 1'b0;
                end
            end
        end
    end
endmodule