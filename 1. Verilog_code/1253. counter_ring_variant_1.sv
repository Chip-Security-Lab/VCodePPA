//SystemVerilog
//IEEE 1364-2005
module counter_ring #(
    parameter DEPTH = 4
) (
    input wire clk,
    input wire rst_n,
    input wire en_in,        // Enable input signal
    output wire en_out,      // Enable output signal
    output reg [DEPTH-1:0] ring
);

    // Pipeline stage registers
    reg [DEPTH-1:0] ring_stage1;
    reg [DEPTH-1:0] ring_stage2;
    
    // Valid signals for pipeline control
    reg valid_stage1;
    reg valid_stage2;
    
    // Stage 1: Initial shifting
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_stage1 <= {1'b1, {DEPTH-1{1'b0}}};
            valid_stage1 <= 1'b0;
        end else begin
            if (en_in) begin
                ring_stage1 <= {ring[DEPTH-2:0], ring[DEPTH-1]};
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Additional processing stage (could add more complex logic here)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_stage2 <= {1'b1, {DEPTH-1{1'b0}}};
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                ring_stage2 <= ring_stage1;
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring <= {1'b1, {DEPTH-1{1'b0}}};
        end else begin
            if (valid_stage2) begin
                ring <= ring_stage2;
            end
        end
    end
    
    // Pipeline valid signal propagation
    assign en_out = valid_stage2;
    
endmodule