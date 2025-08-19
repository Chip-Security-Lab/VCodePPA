//SystemVerilog
module int_ctrl_edge #(
    parameter WIDTH = 8
)(
    input                  clk,        // System clock
    input                  rst,        // Asynchronous reset
    input  [WIDTH-1:0]     async_intr, // Asynchronous interrupt inputs
    output [WIDTH-1:0]     synced_intr // Edge-detected synchronized interrupts
);
    // Synchronization registers
    reg [WIDTH-1:0] sync_stage1_r;
    reg [WIDTH-1:0] sync_stage2_r;
    
    // Edge detection register
    reg [WIDTH-1:0] synced_intr_r;
    
    // Two-stage synchronization pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all pipeline registers
            sync_stage1_r <= {WIDTH{1'b0}};
            sync_stage2_r <= {WIDTH{1'b0}};
        end
        else begin
            // First synchronization stage
            sync_stage1_r <= async_intr;
            // Second synchronization stage
            sync_stage2_r <= sync_stage1_r;
        end
    end
    
    // Edge detection pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            synced_intr_r <= {WIDTH{1'b0}};
        end
        else begin
            // Rising edge detection logic
            synced_intr_r <= sync_stage1_r & ~sync_stage2_r;
        end
    end
    
    // Output assignment
    assign synced_intr = synced_intr_r;
    
endmodule