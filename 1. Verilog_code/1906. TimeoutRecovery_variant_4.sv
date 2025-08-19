//SystemVerilog
module TimeoutRecovery #(parameter WIDTH=8, TIMEOUT=32'hFFFF) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] unstable_in,
    output reg [WIDTH-1:0] stable_out,
    output reg timeout
);
    // Stage 1: Input registration and counter update
    reg [31:0] counter_stage1;
    reg [WIDTH-1:0] unstable_in_stage1;
    reg [WIDTH-1:0] stable_out_stage1;
    
    // Stage 2: Counter buffering
    reg [31:0] counter_stage2;
    reg [31:0] counter_buf1_stage2;
    reg [31:0] counter_buf2_stage2;
    reg [WIDTH-1:0] unstable_in_stage2;
    reg [WIDTH-1:0] stable_out_stage2;
    
    // Stage 3: Comparison operation
    reg counter_ge_timeout_stage3;
    reg counter_ge_timeout_buf1_stage3;
    reg counter_ge_timeout_buf2_stage3;
    reg [WIDTH-1:0] unstable_in_stage3;
    reg [WIDTH-1:0] stable_out_stage3;
    
    // Stage 4: Final output logic
    reg counter_ge_timeout_buf1_stage4;
    reg counter_ge_timeout_buf2_stage4;
    reg [WIDTH-1:0] unstable_in_stage4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            counter_stage1 <= 0;
            unstable_in_stage1 <= 0;
            stable_out_stage1 <= 0;
            
            counter_stage2 <= 0;
            counter_buf1_stage2 <= 0;
            counter_buf2_stage2 <= 0;
            unstable_in_stage2 <= 0;
            stable_out_stage2 <= 0;
            
            counter_ge_timeout_stage3 <= 0;
            counter_ge_timeout_buf1_stage3 <= 0;
            counter_ge_timeout_buf2_stage3 <= 0;
            unstable_in_stage3 <= 0;
            stable_out_stage3 <= 0;
            
            counter_ge_timeout_buf1_stage4 <= 0;
            counter_ge_timeout_buf2_stage4 <= 0;
            unstable_in_stage4 <= 0;
            
            stable_out <= 0;
            timeout <= 0;
        end else begin
            // Stage 1: Input registration and counter update
            unstable_in_stage1 <= unstable_in;
            stable_out_stage1 <= stable_out;
            
            if (unstable_in != stable_out) begin
                counter_stage1 <= 0;
            end else begin
                counter_stage1 <= counter_stage1 + 1;
            end
            
            // Stage 2: Counter buffering
            counter_stage2 <= counter_stage1;
            counter_buf1_stage2 <= counter_stage1;
            counter_buf2_stage2 <= counter_stage1;
            unstable_in_stage2 <= unstable_in_stage1;
            stable_out_stage2 <= stable_out_stage1;
            
            // Stage 3: Comparison operations split into separate stage
            counter_ge_timeout_stage3 <= (counter_stage2 >= TIMEOUT);
            counter_ge_timeout_buf1_stage3 <= (counter_buf1_stage2 >= TIMEOUT);
            counter_ge_timeout_buf2_stage3 <= (counter_buf2_stage2 >= TIMEOUT);
            unstable_in_stage3 <= unstable_in_stage2;
            stable_out_stage3 <= stable_out_stage2;
            
            // Stage 4: Final output logic
            counter_ge_timeout_buf1_stage4 <= counter_ge_timeout_buf1_stage3;
            counter_ge_timeout_buf2_stage4 <= counter_ge_timeout_buf2_stage3;
            unstable_in_stage4 <= unstable_in_stage3;
            
            // Output stage
            timeout <= counter_ge_timeout_buf1_stage4;
            
            if (counter_ge_timeout_buf2_stage4) begin
                stable_out <= stable_out;
            end else begin
                stable_out <= unstable_in_stage4;
            end
        end
    end
endmodule