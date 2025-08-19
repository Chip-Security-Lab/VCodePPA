//SystemVerilog
module shadow_reg_double_buf #(
    parameter WIDTH = 16
) (
    input wire clk,
    input wire reset_n,  // Added reset signal for better initialization
    input wire swap,
    input wire update_valid,  // Added validity signal for data updates
    input wire [WIDTH-1:0] update_data,
    output reg [WIDTH-1:0] active_data,
    output reg update_ready  // Added handshaking signal
);
    // Pipeline stages for data flow
    reg [WIDTH-1:0] buffer_stage1;
    reg [WIDTH-1:0] buffer_stage2;
    
    // Control signals
    reg swap_pending;
    
    // Data path: Input → Stage1 → Stage2 → Output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Clear pipeline stages on reset
            buffer_stage1 <= {WIDTH{1'b0}};
            buffer_stage2 <= {WIDTH{1'b0}};
            active_data <= {WIDTH{1'b0}};
            swap_pending <= 1'b0;
            update_ready <= 1'b1;
        end else begin
            // First pipeline stage - capture input data
            if (update_valid && update_ready) begin
                buffer_stage1 <= update_data;
                update_ready <= 1'b0;  // Block new updates until processed
            end
            
            // Second pipeline stage - prepare data for potential swap
            buffer_stage2 <= buffer_stage1;
            
            // Output stage - perform swap if requested
            if (swap) begin
                active_data <= buffer_stage2;
                swap_pending <= 1'b0;
                update_ready <= 1'b1;  // Ready for new data after swap
            end else if (swap_pending) begin
                swap_pending <= 1'b0;
                update_ready <= 1'b1;
            end else if (!update_ready) begin
                // Mark update as processed
                swap_pending <= 1'b1;
            end
        end
    end
endmodule