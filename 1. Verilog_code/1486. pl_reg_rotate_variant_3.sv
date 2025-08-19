//SystemVerilog
module pl_reg_rotate #(
    parameter W = 8  // Register width
)(
    input  wire        clk,     // Clock signal
    input  wire        rst,     // Reset signal
    input  wire        load,    // Load enable signal
    input  wire        rotate,  // Rotate enable signal
    input  wire [W-1:0] d_in,   // Data input
    output wire [W-1:0] q,      // Register output
    input  wire        ready,   // Downstream ready signal
    output wire        valid    // Output valid signal
);

    // Pipeline stage registers for data path
    reg [W-1:0] stage1_data;
    reg [W-1:0] stage2_data;
    reg [W-1:0] stage3_data;
    
    // Pipeline stage control signals
    reg        stage1_valid;
    reg        stage2_valid;
    reg        stage3_valid;
    
    // Operation type tracking through pipeline
    reg        stage1_is_load;
    reg        stage1_is_rotate;
    reg        stage2_is_load;
    reg        stage2_is_rotate;
    
    // Intermediate computation results
    reg [W-1:0] rotate_result;
    
    // Pipeline flow control
    wire stage1_ready;
    wire stage2_ready;
    wire stage3_ready;
    
    // Final output assignment
    assign q = stage3_data;
    assign valid = stage3_valid;
    
    // Backward pressure propagation
    assign stage3_ready = ready;
    assign stage2_ready = ~stage3_valid || stage3_ready;
    assign stage1_ready = ~stage2_valid || stage2_ready;
    
    // Stage 1: Input capture and operation selection
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            stage1_is_load <= 1'b0;
            stage1_is_rotate <= 1'b0;
            stage1_data <= {W{1'b0}};
        end
        else if (stage1_ready) begin
            stage1_valid <= load | rotate;
            stage1_is_load <= load;
            stage1_is_rotate <= rotate & ~load; // Load has priority
            stage1_data <= d_in;
        end
    end
    
    // Stage 2: Computation stage
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            stage2_is_load <= 1'b0;
            stage2_is_rotate <= 1'b0;
            stage2_data <= {W{1'b0}};
            rotate_result <= {W{1'b0}};
        end
        else if (stage2_ready) begin
            stage2_valid <= stage1_valid;
            stage2_is_load <= stage1_is_load;
            stage2_is_rotate <= stage1_is_rotate;
            stage2_data <= stage1_data;
            
            // Pre-compute rotate result
            rotate_result <= {stage3_data[W-2:0], stage3_data[W-1]};
        end
    end
    
    // Stage 3: Output selection stage
    always @(posedge clk) begin
        if (rst) begin
            stage3_valid <= 1'b0;
            stage3_data <= {W{1'b0}};
        end
        else if (stage3_ready) begin
            stage3_valid <= stage2_valid;
            
            if (stage2_valid) begin
                if (stage2_is_load)
                    stage3_data <= stage2_data; // Load operation
                else if (stage2_is_rotate)
                    stage3_data <= rotate_result; // Rotate operation
                else
                    stage3_data <= stage3_data; // Maintain current value
            end
        end
    end

endmodule