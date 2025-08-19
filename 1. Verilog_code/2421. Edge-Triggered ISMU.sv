module edge_triggered_ismu #(parameter SRC_COUNT = 8)(
    input wire clk, rst_n,
    input wire [SRC_COUNT-1:0] intr_sources,
    input wire [SRC_COUNT-1:0] intr_mask,
    output reg [SRC_COUNT-1:0] pending_intr,
    output wire intr_valid
);
    reg [SRC_COUNT-1:0] intr_sources_r;
    wire [SRC_COUNT-1:0] edge_detected;
    
    assign edge_detected = intr_sources & ~intr_sources_r & ~intr_mask;
    assign intr_valid = |pending_intr;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            intr_sources_r <= 0;
            pending_intr <= 0;
        end else begin
            intr_sources_r <= intr_sources;
            pending_intr <= pending_intr | edge_detected;
        end
    end
endmodule