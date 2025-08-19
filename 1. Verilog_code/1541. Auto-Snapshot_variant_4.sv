//SystemVerilog
// IEEE 1364-2005
module auto_snapshot_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire error_detected,
    output reg [WIDTH-1:0] shadow_data,
    output reg snapshot_taken
);
    // Optimized pipeline stage registers using a single multi-dimensional array
    reg [WIDTH-1:0] main_reg_pipeline [2:0];
    
    // Optimized control and status signals using packed arrays for better routing
    reg [2:0] error_detected_pipeline;
    reg [2:0] snapshot_pending_pipeline;
    
    // Combined pipeline logic using a single always block for better synthesis optimization
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 3; i = i + 1) begin
                main_reg_pipeline[i] <= {WIDTH{1'b0}};
            end
            error_detected_pipeline <= 3'b0;
            snapshot_pending_pipeline <= 3'b0;
        end else begin
            // Stage 1
            main_reg_pipeline[0] <= data_in;
            error_detected_pipeline[0] <= error_detected;
            snapshot_pending_pipeline[0] <= error_detected && !snapshot_taken;
            
            // Forward propagation to later stages
            for (i = 1; i < 3; i = i + 1) begin
                main_reg_pipeline[i] <= main_reg_pipeline[i-1];
                error_detected_pipeline[i] <= error_detected_pipeline[i-1];
                snapshot_pending_pipeline[i] <= snapshot_pending_pipeline[i-1];
            end
        end
    end
    
    // Optimized shadow data capture logic with prioritized conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            snapshot_taken <= 1'b0;
        end else begin
            // Priority-based decision making with optimized condition checking
            if (snapshot_pending_pipeline[2] && !snapshot_taken) begin
                shadow_data <= main_reg_pipeline[2];
                snapshot_taken <= 1'b1;
            end else if (!error_detected_pipeline[2]) begin
                snapshot_taken <= 1'b0;
            end
        end
    end
endmodule