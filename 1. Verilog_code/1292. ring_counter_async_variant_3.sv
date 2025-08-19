//SystemVerilog
//IEEE 1364-2005 Verilog
module ring_counter_async (
    input wire clk,             // Clock input
    input wire rst_n,           // Active-low asynchronous reset
    input wire en,              // Enable signal
    input wire valid_in,        // Input valid signal
    output wire valid_out,      // Output valid signal
    output wire [3:0] ring_pattern // One-hot encoded output pattern
);

    // Pipeline stage 1 registers
    reg [3:0] ring_pattern_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [3:0] ring_pattern_stage2;
    reg valid_stage2;
    
    // Stage 1: Initial pattern generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_pattern_stage1 <= 4'b0001;
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            if (en && valid_in) begin
                ring_pattern_stage1 <= 4'b0001;
            end
            else if (!en && valid_in) begin
                ring_pattern_stage1 <= 4'b0000;
            end
        end
    end
    
    // Stage 2: Pattern rotation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_pattern_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                if (|ring_pattern_stage1) begin
                    ring_pattern_stage2 <= {ring_pattern_stage1[2:0], ring_pattern_stage1[3]};
                end
                else begin
                    ring_pattern_stage2 <= ring_pattern_stage1;
                end
            end
        end
    end
    
    // Output assignments
    assign ring_pattern = ring_pattern_stage2;
    assign valid_out = valid_stage2;

endmodule