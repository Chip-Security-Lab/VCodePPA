module counter_ismu #(parameter N = 8)(
    input wire CLK, nRST,
    input wire [N-1:0] IRQ,
    input wire CLR_CNT,
    output reg [N-1:0] IRQ_STATUS,
    output reg [N-1:0][7:0] IRQ_COUNT
);
    integer i;
    reg [N-1:0] IRQ_prev;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_prev <= {N{1'b0}};
            IRQ_STATUS <= {N{1'b0}};
            for (i = 0; i < N; i = i + 1)
                IRQ_COUNT[i] <= 8'h0;
        end else begin
            IRQ_prev <= IRQ;
            for (i = 0; i < N; i = i + 1) begin
                if (IRQ[i] & ~IRQ_prev[i]) begin
                    IRQ_STATUS[i] <= 1'b1;
                    if (IRQ_COUNT[i] < 8'hFF)
                        IRQ_COUNT[i] <= IRQ_COUNT[i] + 8'h1;
                end
                if (CLR_CNT) begin
                    IRQ_STATUS <= {N{1'b0}};
                    IRQ_COUNT[i] <= 8'h0;
                end
            end
        end
    end
endmodule