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
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            ctx_valid <= 0;
            ctx_out <= 0;
        end else begin
            for (i = 0; i < PRIO_LEVELS; i=i+1) begin
                // Write operation
                if (save_req[i] && !rst_n) begin
                    queue[i][wr_ptr[i]] <= ctx_in;
                    wr_ptr[i] <= ~wr_ptr[i];
                end
                
                // Read operation
                if (rd_ptr[i] != wr_ptr[i] && !rst_n) begin
                    ctx_out <= queue[i][rd_ptr[i]];
                    rd_ptr[i] <= ~rd_ptr[i];
                    ctx_valid[i] <= 1;
                end else if (!rst_n) begin
                    ctx_valid[i] <= 0;
                end
            end
        end
    end
endmodule