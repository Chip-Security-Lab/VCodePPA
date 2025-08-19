//SystemVerilog
// Top-level module
module counter_ismu #(parameter N = 8)(
    input wire CLK, nRST,
    input wire [N-1:0] IRQ,
    input wire CLR_CNT,
    output wire [N-1:0] IRQ_STATUS,
    output wire [N-1:0][7:0] IRQ_COUNT
);
    // Detect rising edges on IRQ signals
    wire [N-1:0] irq_rise;
    irq_edge_detector #(.WIDTH(N)) edge_detect_inst (
        .CLK(CLK),
        .nRST(nRST),
        .IRQ(IRQ),
        .IRQ_RISE(irq_rise)
    );

    // Handle IRQ status and counting
    irq_counter #(.N(N)) counter_inst (
        .CLK(CLK),
        .nRST(nRST),
        .IRQ_RISE(irq_rise),
        .CLR_CNT(CLR_CNT),
        .IRQ_STATUS(IRQ_STATUS),
        .IRQ_COUNT(IRQ_COUNT)
    );
endmodule

// Edge detection submodule
module irq_edge_detector #(parameter WIDTH = 8)(
    input wire CLK, nRST,
    input wire [WIDTH-1:0] IRQ,
    output wire [WIDTH-1:0] IRQ_RISE
);
    reg [WIDTH-1:0] IRQ_prev;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_prev <= {WIDTH{1'b0}};
        end else begin
            IRQ_prev <= IRQ;
        end
    end
    
    // Rising edge detection
    assign IRQ_RISE = IRQ & ~IRQ_prev;
endmodule

// Counter and status handling submodule
module irq_counter #(parameter N = 8)(
    input wire CLK, nRST,
    input wire [N-1:0] IRQ_RISE,
    input wire CLR_CNT,
    output reg [N-1:0] IRQ_STATUS,
    output reg [N-1:0][7:0] IRQ_COUNT
);
    integer i;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_STATUS <= {N{1'b0}};
            for (i = 0; i < N; i = i + 1)
                IRQ_COUNT[i] <= 8'h0;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                if (IRQ_RISE[i]) begin
                    IRQ_STATUS[i] <= 1'b1;
                    if (IRQ_COUNT[i] < 8'hFF)
                        IRQ_COUNT[i] <= IRQ_COUNT[i] + 8'h1;
                end
            end
            
            if (CLR_CNT) begin
                IRQ_STATUS <= {N{1'b0}};
                for (i = 0; i < N; i = i + 1)
                    IRQ_COUNT[i] <= 8'h0;
            end
        end
    end
endmodule