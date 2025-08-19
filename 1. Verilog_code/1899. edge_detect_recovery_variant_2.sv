//SystemVerilog IEEE 1364-2005
module edge_detect_recovery (
    input wire clk,
    input wire rst_n,
    input wire signal_in,
    output reg rising_edge,
    output reg falling_edge,
    output reg [7:0] edge_count
);
    // Pipeline registers
    reg signal_ff1, signal_ff2;
    reg edge_valid;
    reg rise_detect, fall_detect;
    
    // Stage 1: Input sampling with optimized edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_ff1 <= 1'b0;
            signal_ff2 <= 1'b0;
            rise_detect <= 1'b0;
            fall_detect <= 1'b0;
        end else begin
            // Double flop synchronization
            signal_ff1 <= signal_in;
            signal_ff2 <= signal_ff1;
            
            // Optimized edge detection using direct comparison
            rise_detect <= signal_ff1 & ~signal_ff2;
            fall_detect <= ~signal_ff1 & signal_ff2;
        end
    end
    
    // Stage 2: Edge validation and output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rising_edge <= 1'b0;
            falling_edge <= 1'b0;
            edge_valid <= 1'b0;
        end else begin
            // Direct assignment to outputs reduces logic depth
            rising_edge <= rise_detect;
            falling_edge <= fall_detect;
            
            // Combined edge detection using a single OR operation
            edge_valid <= rise_detect | fall_detect;
        end
    end
    
    // Stage 3: Counter logic with enable control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            edge_count <= 8'h00;
        end else if (edge_valid) begin
            // Counter increment with enable condition
            edge_count <= edge_count + 8'h01;
        end
    end
endmodule