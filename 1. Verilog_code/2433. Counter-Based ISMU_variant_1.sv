//SystemVerilog
module counter_ismu #(
    parameter N = 8
)(
    input  wire          CLK,
    input  wire          nRST,
    input  wire [N-1:0]  IRQ,
    input  wire          CLR_CNT,
    output wire [N-1:0]  IRQ_STATUS,
    output wire [N-1:0][7:0] IRQ_COUNT
);
    // Edge detection signals
    wire [N-1:0] irq_edge;
    
    // Instantiate edge detector module
    edge_detector #(
        .WIDTH(N)
    ) u_edge_detector (
        .CLK        (CLK),
        .nRST       (nRST),
        .signal_in  (IRQ),
        .rising_edge(irq_edge)
    );
    
    // Instantiate interrupt counter module
    irq_counter #(
        .N(N)
    ) u_irq_counter (
        .CLK        (CLK),
        .nRST       (nRST),
        .irq_edge   (irq_edge),
        .CLR_CNT    (CLR_CNT),
        .IRQ_STATUS (IRQ_STATUS),
        .IRQ_COUNT  (IRQ_COUNT)
    );
    
endmodule

// Edge detector module - detects rising edges on input signals
module edge_detector #(
    parameter WIDTH = 8
)(
    input  wire             CLK,
    input  wire             nRST,
    input  wire [WIDTH-1:0] signal_in,
    output wire [WIDTH-1:0] rising_edge
);
    reg [WIDTH-1:0] signal_prev;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            signal_prev <= {WIDTH{1'b0}};
        end else begin
            signal_prev <= signal_in;
        end
    end
    
    // Rising edge occurs when current signal is high and previous was low
    assign rising_edge = signal_in & ~signal_prev;
    
endmodule

// Interrupt counter module - tracks IRQ occurrences
module irq_counter #(
    parameter N = 8
)(
    input  wire          CLK,
    input  wire          nRST,
    input  wire [N-1:0]  irq_edge,
    input  wire          CLR_CNT,
    output reg  [N-1:0]  IRQ_STATUS,
    output reg  [N-1:0][7:0] IRQ_COUNT
);
    integer i;
    
    always @(posedge CLK or negedge nRST) begin
        if (!nRST) begin
            IRQ_STATUS <= {N{1'b0}};
            for (i = 0; i < N; i = i + 1)
                IRQ_COUNT[i] <= 8'h0;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                if (CLR_CNT) begin
                    // Clear counter and status on clear signal
                    IRQ_STATUS[i] <= 1'b0;
                    IRQ_COUNT[i] <= 8'h0;
                end else if (irq_edge[i]) begin
                    // Always set status on edge
                    IRQ_STATUS[i] <= 1'b1;
                    
                    // Increment counter if not at max value
                    if (IRQ_COUNT[i] < 8'hFF) begin
                        IRQ_COUNT[i] <= IRQ_COUNT[i] + 8'h1;
                    end
                end
            end
        end
    end
    
endmodule