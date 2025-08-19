//SystemVerilog
module cdc_fifo_ctrl #(
    parameter DEPTH = 8
) (
    input  wire                         wr_clk,
    input  wire                         rd_clk,
    input  wire                         reset,
    input  wire                         write,
    input  wire                         read,
    output wire                         full,
    output wire                         empty,
    output reg  [$clog2(DEPTH)-1:0]     wptr,
    output reg  [$clog2(DEPTH)-1:0]     rptr
);

    // Internal pointer and Gray code registers
    reg [$clog2(DEPTH)-1:0] wptr_gray;
    reg [$clog2(DEPTH)-1:0] rptr_gray;
    reg [$clog2(DEPTH)-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [$clog2(DEPTH)-1:0] rptr_gray_sync1, rptr_gray_sync2;

    // Write pointer update with case restructuring
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr <= {($clog2(DEPTH)){1'b0}};
        end else begin
            case ({write, full})
                2'b10: wptr <= wptr + 1'b1;
                default: wptr <= wptr;
            endcase
        end
    end

    // Write pointer Gray code update with case restructuring
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            wptr_gray <= {($clog2(DEPTH)){1'b0}};
        end else begin
            case ({write, full})
                2'b10: wptr_gray <= (wptr + 1'b1) ^ ((wptr + 1'b1) >> 1);
                default: wptr_gray <= wptr_gray;
            endcase
        end
    end

    // Read pointer update with case restructuring
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr <= {($clog2(DEPTH)){1'b0}};
        end else begin
            case ({read, empty})
                2'b10: rptr <= rptr + 1'b1;
                default: rptr <= rptr;
            endcase
        end
    end

    // Read pointer Gray code update with case restructuring
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            rptr_gray <= {($clog2(DEPTH)){1'b0}};
        end else begin
            case ({read, empty})
                2'b10: rptr_gray <= (rptr + 1'b1) ^ ((rptr + 1'b1) >> 1);
                default: rptr_gray <= rptr_gray;
            endcase
        end
    end

    // Synchronize wptr_gray into rd_clk domain
    always @(posedge rd_clk or posedge reset) begin
        if (reset) begin
            wptr_gray_sync1 <= {($clog2(DEPTH)){1'b0}};
            wptr_gray_sync2 <= {($clog2(DEPTH)){1'b0}};
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Synchronize rptr_gray into wr_clk domain
    always @(posedge wr_clk or posedge reset) begin
        if (reset) begin
            rptr_gray_sync1 <= {($clog2(DEPTH)){1'b0}};
            rptr_gray_sync2 <= {($clog2(DEPTH)){1'b0}};
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Full condition generation (combinational)
    assign full = (wptr_gray == {~rptr_gray_sync2[$clog2(DEPTH)-1:$clog2(DEPTH)-2],
                                 rptr_gray_sync2[$clog2(DEPTH)-3:0]});

    // Empty condition generation (combinational)
    assign empty = (rptr_gray == wptr_gray_sync2);

endmodule