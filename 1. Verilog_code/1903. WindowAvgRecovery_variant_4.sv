//SystemVerilog
module WindowAvgRecovery #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);
    // Registers for input sample storage
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    // Pre-compute partial sums at each stage
    reg [WIDTH+1:0] sum_stage1; // Buffer[0] + Buffer[1]
    reg [WIDTH+1:0] sum_stage2; // Buffer[2] + Buffer[3]
    reg [WIDTH+2:0] final_sum;  // sum_stage1 + sum_stage2
    
    integer i;

    // Buffer update logic
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset buffer registers
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= 0;
            end
        end else begin
            // Update buffer - shifted register chain
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= din;
        end
    end

    // First stage computation
    always @(posedge clk) begin
        if (!rst_n) begin
            sum_stage1 <= 0;
            sum_stage2 <= 0;
        end else begin
            // First stage - partial sums
            sum_stage1 <= buffer[0] + buffer[1];
            sum_stage2 <= buffer[2] + buffer[3];
        end
    end

    // Second stage computation
    always @(posedge clk) begin
        if (!rst_n) begin
            final_sum <= 0;
        end else begin
            // Second stage - final sum
            final_sum <= sum_stage1 + sum_stage2;
        end
    end

    // Output stage
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= 0;
        end else begin
            // Final stage - shift for division by 4
            dout <= final_sum >> 2;
        end
    end
endmodule