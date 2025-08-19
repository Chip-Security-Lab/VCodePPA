//SystemVerilog
module direction_ring_counter (
    input  wire       clk,       // Clock input
    input  wire       rst,       // Reset input
    input  wire       dir_sel,   // Direction select (0:left, 1:right)
    input  wire       valid_in,  // Input valid signal
    output wire       valid_out, // Output valid signal
    output wire [3:0] q_out      // Counter output
);
    // Pipeline registers - Stage 1: Input and direction handling
    reg        stage1_valid;     // Stage 1 valid flag
    reg        stage1_dir;       // Registered direction in stage 1
    reg [3:0]  stage1_data;      // Stage 1 data register
    
    // Pipeline registers - Stage 2: Shift operation
    reg        stage2_valid;     // Stage 2 valid flag
    reg [3:0]  stage2_data;      // Stage 2 data register (output)
    
    // Intermediate signals for improved readability
    reg [3:0]  next_data;        // Next data value to be registered

    // Stage 1: Input capture and feedback handling
    always @(posedge clk) begin
        if (rst) begin
            stage1_valid <= 1'b0;
            stage1_dir   <= 1'b0;
            stage1_data  <= 4'b0001;
        end
        else if (valid_in) begin
            stage1_valid <= 1'b1;
            stage1_dir   <= dir_sel;
            stage1_data  <= (stage2_valid) ? stage2_data : 4'b0001;
        end
        else begin
            stage1_valid <= 1'b0;
        end
    end

    // Calculate next data value based on current data and direction
    always @(*) begin
        if (stage1_dir)
            next_data = {stage1_data[0], stage1_data[3:1]}; // Shift right
        else
            next_data = {stage1_data[2:0], stage1_data[3]}; // Shift left
    end
    
    // Stage 2: Shift operation
    always @(posedge clk) begin
        if (rst) begin
            stage2_valid <= 1'b0;
            stage2_data  <= 4'b0001;
        end
        else if (stage1_valid) begin
            stage2_valid <= 1'b1;
            stage2_data  <= next_data;
        end
        else begin
            stage2_valid <= 1'b0;
        end
    end
    
    // Output assignments
    assign q_out     = stage2_data;
    assign valid_out = stage2_valid;
    
endmodule